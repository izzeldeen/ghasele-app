import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Why a Google sign-in attempt ended.
enum GoogleSignInStatus {
  /// Signed in with Firebase. [GoogleSignInResult.idToken] is set.
  success,

  /// The user dismissed the account picker. Not an error - show nothing.
  cancelled,

  /// Anything else: no ID token, Firebase rejected the credential, network failure.
  failed,
}

class GoogleSignInResult {
  final GoogleSignInStatus status;

  /// Firebase ID token to hand to `POST /api/auth/google`. Non-null only on success.
  final String? idToken;

  /// Underlying error code, for logging and for picking a message.
  final String? errorCode;

  const GoogleSignInResult({
    required this.status,
    this.idToken,
    this.errorCode,
  });
}

/// Client half of Google sign-in.
///
/// The Google credential is exchanged for a Firebase one, so what the backend receives is a
/// Firebase ID token - the same kind the phone flow produces, verified by the same Admin SDK.
/// It goes to its own endpoint (`/api/auth/google`) because it carries an email claim rather than
/// a phone_number one, which `/api/auth/firebase-login` requires.
///
/// Separate from [FirebaseOtpService] so neither flow can break the other.
class GoogleSignInService {
  /// google_sign_in 7.x requires an explicit one-time initialize() before authenticate().
  static bool _initialized = false;

  /// Normally left empty. Android reads the web client id from the `default_web_client_id`
  /// string resource the google-services Gradle plugin generates out of google-services.json, and
  /// iOS reads CLIENT_ID from GoogleService-Info.plist - so neither platform needs this hardcoded.
  /// Overridable only as an escape hatch if those files are ever out of step with the console.
  static const String _serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    _initialized = true;
  }

  /// Runs the full flow: Google account picker, then Firebase sign-in with the resulting credential.
  static Future<GoogleSignInResult> signIn() async {
    try {
      await _ensureInitialized();

      // authenticate() is the 7.x replacement for signIn(). It throws rather than returning null
      // when the user backs out, which is why cancellation is handled in the catch below.
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();

      final String? googleIdToken = account.authentication.idToken;
      if (googleIdToken == null) {
        // On Android this means the web client id was not found - Google sign-in is enabled in the
        // console but google-services.json predates it and has no client_type 3 entry.
        if (kDebugMode) {
          print(
            'GOOGLE sign-in: no idToken returned. On Android this usually means '
            'google-services.json has no web client (client_type 3) - re-download it '
            'after enabling Google in the Firebase console.',
          );
        }
        return const GoogleSignInResult(
          status: GoogleSignInStatus.failed,
          errorCode: 'no-google-id-token',
        );
      }

      // Firebase accepts the Google ID token on its own; an access token is only needed for
      // calling Google APIs, which this app does not do.
      final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final String? firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null) {
        if (kDebugMode) {
          print('GOOGLE sign-in: Firebase signed in but getIdToken returned null');
        }
        return const GoogleSignInResult(
          status: GoogleSignInStatus.failed,
          errorCode: 'no-id-token',
        );
      }

      if (kDebugMode) {
        print('GOOGLE sign-in OK (idToken ${firebaseIdToken.length} chars)');
      }
      return GoogleSignInResult(
        status: GoogleSignInStatus.success,
        idToken: firebaseIdToken,
      );
    } on GoogleSignInException catch (e) {
      // Backing out of the account picker is a normal outcome, not a failure to report.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleSignInResult(status: GoogleSignInStatus.cancelled);
      }
      if (kDebugMode) {
        print('GOOGLE sign-in failed: ${e.code} ${e.description}');
      }
      return GoogleSignInResult(
        status: GoogleSignInStatus.failed,
        errorCode: e.code.name,
      );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('GOOGLE sign-in Firebase rejected credential: ${e.code} ${e.message}');
      }
      return GoogleSignInResult(
        status: GoogleSignInStatus.failed,
        errorCode: e.code,
      );
    } catch (e) {
      if (kDebugMode) print('GOOGLE sign-in exception: $e');
      return const GoogleSignInResult(
        status: GoogleSignInStatus.failed,
        errorCode: 'unknown',
      );
    }
  }

  /// Clears both sessions. Our own JWT is what keeps the user logged in, so leaving either of
  /// these signed in would make the next sign-in silently reuse the previous account instead of
  /// showing the picker.
  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      if (kDebugMode) print('GOOGLE sign-out failed: $e');
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (kDebugMode) print('FIREBASE sign-out failed: $e');
    }
  }
}
