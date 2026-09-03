import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Result of asking Firebase to send a verification SMS.
///
/// Firebase can finish the job by itself on some Android devices (it reads the SMS and signs the
/// user in without them typing anything), so "sent" is not the only success case - callers have to
/// handle being already signed in.
enum OtpSendStatus {
  /// SMS dispatched; the user must now type the code.
  codeSent,

  /// Android auto-retrieved the code and completed sign-in. No code entry needed.
  autoVerified,

  /// Firebase rejected the request (bad number, quota exhausted, app not attested).
  failed,
}

/// Outcome of exchanging a typed code for a Firebase ID token.
class OtpConfirmResult {
  /// Non-null only on success.
  final String? idToken;

  /// Firebase's code on failure (e.g. `invalid-verification-code`, `session-expired`).
  final String? errorCode;

  const OtpConfirmResult({this.idToken, this.errorCode});

  bool get isSuccess => idToken != null;
}

class OtpSendResult {
  final OtpSendStatus status;

  /// Passed back to [FirebaseOtpService.confirmCode] to tie the typed code to this send.
  final String? verificationId;

  /// Present only when [status] is [OtpSendStatus.autoVerified].
  final String? idToken;

  /// Firebase's error code (e.g. `invalid-phone-number`, `too-many-requests`), for logging and
  /// for choosing which localized message to show.
  final String? errorCode;

  const OtpSendResult({
    required this.status,
    this.verificationId,
    this.idToken,
    this.errorCode,
  });
}

/// Client half of Firebase Phone Authentication.
///
/// Firebase - not our backend - sends the SMS and checks the code. All our server ever sees is the
/// signed ID token produced afterwards, which it verifies via the Admin SDK. This class therefore
/// never handles an OTP value that our own code generated.
///
/// This is a separate path from the WhatsApp OTP flow in `ApiService.startRegistration`, which
/// remains in place as the fallback.
class FirebaseOtpService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upper bound on a send. Firebase normally calls back within seconds; well past its own 60s
  /// auto-retrieval window means nothing is coming and the user should be told, not left waiting.
  static const Duration _sendTimeout = Duration(seconds: 75);

  /// Firebase rejects anything that is not E.164, so callers must pass `+962...` form.
  static Future<OtpSendResult> sendCode(String phoneNumber) {
    if (kDebugMode) print('🔥 [FirebaseOtpService] sendCode called with EXACTLY: "$phoneNumber" (Length: ${phoneNumber.length})');
    // verifyPhoneNumber reports through callbacks rather than by returning, so the result is
    // bridged onto a Completer. Guarded because Android can fire both verificationCompleted and
    // codeSent for one request, and completing twice would throw.
    final completer = Completer<OtpSendResult>();

    void finish(OtpSendResult result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    // Deliberately NOT awaited. On Android the Future this returns does not settle until the
    // auto-retrieval window closes, which is a full minute after codeSent has already fired -
    // awaiting it would hold the caller's spinner for that entire window even though the result
    // was ready in seconds. Every outcome we care about arrives through the callbacks below.
    unawaited(
      _auth
          .verifyPhoneNumber(
        phoneNumber: phoneNumber,
        // Android only: the SMS was auto-retrieved, so sign in without asking the user to type.
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            final idToken = await userCredential.user?.getIdToken();
            finish(OtpSendResult(
              status: OtpSendStatus.autoVerified,
              idToken: idToken,
            ));
          } catch (e) {
            if (kDebugMode) print('FIREBASE OTP auto-verify failed: $e');
            finish(const OtpSendResult(
              status: OtpSendStatus.failed,
              errorCode: 'auto-verify-failed',
            ));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            print('FIREBASE OTP send failed: ${e.code} ${e.message}');
          }
          finish(OtpSendResult(
            status: OtpSendStatus.failed,
            errorCode: e.code,
          ));
        },
        codeSent: (String verificationId, int? resendToken) {
          // Marks the exact point Firebase accepted the send. If this appears, the console setup
          // and app attestation are both fine and any later failure is ours, not Firebase's.
          if (kDebugMode) print('FIREBASE OTP codeSent (verificationId received)');
          finish(OtpSendResult(
            status: OtpSendStatus.codeSent,
            verificationId: verificationId,
          ));
        },
        // Fires after the auto-retrieval window closes. By then codeSent has already completed the
        // Completer, so this only refreshes nothing - it must be supplied, but is a no-op for us.
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      )
          .catchError((Object e) {
        // A synchronous rejection (bad arguments, Firebase not initialized). verificationFailed
        // covers the flow's own errors, so this only catches what never reaches it.
        if (kDebugMode) print('FIREBASE OTP send exception: $e');
        finish(const OtpSendResult(
          status: OtpSendStatus.failed,
          errorCode: 'unknown',
        ));
      }),
    );

    // verifyPhoneNumber gives no guarantee that any callback fires. When the project is
    // misconfigured (Phone provider off), Play services are missing, iOS has no APNs token, or the
    // network silently drops, it can return having scheduled nothing - and an uncompleted Completer
    // would leave the caller awaiting forever with a spinner it can never clear. Bound it here so a
    // stuck send always surfaces as a failure the UI can render.
    return completer.future.timeout(
      _sendTimeout,
      onTimeout: () {
        if (kDebugMode) {
          print(
            'FIREBASE OTP timed out after ${_sendTimeout.inSeconds}s with no callback. '
            'Usual causes: Phone provider disabled in the Firebase console, emulator without '
            'Google Play services, iOS missing GoogleService-Info.plist or an APNs key.',
          );
        }
        return const OtpSendResult(
          status: OtpSendStatus.failed,
          errorCode: 'timeout',
        );
      },
    );
  }

  /// Exchanges the code the user typed for a Firebase ID token.
  ///
  /// The failure reason is carried back rather than collapsed into null: a wrong code and an
  /// expired session need different messages ("try again" vs "request a new code"), and a network
  /// failure is not the user's mistake at all. The raw Firebase code is logged for diagnosis.
  static Future<OtpConfirmResult> confirmCode({
    required String verificationId,
    required String smsCode,
  }) async {
    // Lengths only. An OTP written to a log is a credential written to a log, and debug output
    // routinely ends up pasted into tickets and chat.
    if (kDebugMode) {
      print(
        '[FirebaseOtpService] confirmCode: verificationId '
        '${verificationId.length} chars, smsCode ${smsCode.length} digits',
      );
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        // Sign-in succeeded but no token came back - not a bad code, so do not say so.
        if (kDebugMode) print('FIREBASE OTP confirm: signed in but getIdToken returned null');
        return const OtpConfirmResult(errorCode: 'no-id-token');
      }

      if (kDebugMode) {
        print('FIREBASE OTP confirm OK (idToken ${idToken.length} chars)');
      }
      return OtpConfirmResult(idToken: idToken);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FIREBASE OTP confirm failed: ${e.code} - ${e.message}');
      }
      return OtpConfirmResult(errorCode: e.code);
    } catch (e) {
      if (kDebugMode) print('FIREBASE OTP confirm exception: $e');
      return const OtpConfirmResult(errorCode: 'unknown');
    }
  }

  /// Clears the Firebase session. Our own JWT is what keeps the user logged in, so the Firebase
  /// one has done its job the moment the backend hands us a token - leaving it signed in would
  /// make a later phone-verify silently reuse the stale account.
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) print('FIREBASE sign-out failed: $e');
    }
  }
}
