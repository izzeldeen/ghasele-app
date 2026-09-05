import 'package:ghasele/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/services/firebase_otp_service.dart';

/// Step 2 of the phone-first registration flow. Confirms the OTP sent by [signup_screen.dart].
/// Success does not create an account or log the user in - it just verifies the phone and sends
/// the user on to CompleteRegistrationScreen to pick a name and password.
class RegistrationOtpScreen extends StatefulWidget {
  final String phoneNumber;

  /// Firebase path only. Ties the code the user types back to the specific send that produced it.
  /// Null on the WhatsApp path, which is what selects the original behaviour below.
  final String? firebaseVerificationId;

  /// Firebase path only, and only when Android auto-retrieved the SMS: verification is already
  /// done, so the screen exchanges this immediately instead of waiting for input.
  final String? firebaseIdToken;

  const RegistrationOtpScreen({
    super.key,
    required this.phoneNumber,
    this.firebaseVerificationId,
    this.firebaseIdToken,
  });

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  static const int _otpLength = 6;

  String _otp = '';
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorText;

  /// Firebase path only. Held in state rather than read straight off the widget because a resend
  /// produces a new id, and confirming against the previous one would always fail.
  String? _verificationId;

  /// True when this screen was opened by the Firebase path rather than the WhatsApp one.
  bool get _isFirebase =>
      widget.firebaseVerificationId != null || widget.firebaseIdToken != null;

  @override
  void initState() {
    super.initState();

    _verificationId = widget.firebaseVerificationId;

    // Android auto-retrieved the SMS, so there is nothing to type - finish the exchange as soon
    // as the first frame is up, so the loading state has somewhere to render.
    final autoToken = widget.firebaseIdToken;
    if (autoToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _exchangeFirebaseToken(autoToken);
      });
    }
  }

  Future<void> _verify() async {
    if (_otp.length != _otpLength || _isLoading) return;

    if (_isFirebase) {
      await _verifyWithFirebase();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final result = await ApiService.verifyRegistrationOtp(
        phoneNumber: widget.phoneNumber,
        otp: _otp,
      );

      if (!mounted) return;

      if (result['success']) {
        // No confirmation popup - moving to the next screen is the confirmation.
        Navigator.of(context).pushReplacementNamed(
          '/complete-registration',
          arguments: widget.phoneNumber,
        );
      } else {
        setState(
          () => _errorText =
              result['message'] ??
              AppLocalizations.of(context)!.connectionError,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorText = AppLocalizations.of(context)!.connectionError,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Firebase path resend. Firebase issues a fresh verificationId, so the old one is replaced -
  /// otherwise the next confirm would be checked against a send that no longer applies.
  Future<void> _resendViaFirebase() async {
    final result = await FirebaseOtpService.sendCode(widget.phoneNumber);

    if (!mounted) return;

    switch (result.status) {
      case OtpSendStatus.codeSent:
        setState(() => _verificationId = result.verificationId);
      case OtpSendStatus.autoVerified:
        final token = result.idToken;
        if (token != null) await _exchangeFirebaseToken(token);
      case OtpSendStatus.failed:
        setState(
          () => _errorText = AppLocalizations.of(context)!.connectionError,
        );
    }
  }

  /// Firebase path: hand the typed code to Firebase, then trade the ID token it returns for one
  /// of our own. Our backend never sees the code itself.
  Future<void> _verifyWithFirebase() async {
    final verificationId = _verificationId;
    if (verificationId == null) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final result = await FirebaseOtpService.confirmCode(
      verificationId: verificationId,
      smsCode: _otp,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _isLoading = false;
        _errorText = _confirmErrorText(result.errorCode);
      });
      return;
    }

    await _exchangeFirebaseToken(result.idToken!);
  }

  /// Turns Firebase's confirm-stage error code into something the user can act on.
  ///
  /// A wrong code and an expired session both mean "that code will not work", so both point at
  /// the invalid-code message; anything else is an app or network problem and must not be blamed
  /// on what the user typed.
  String _confirmErrorText(String? code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'invalid-verification-code':
      case 'session-expired':
      case 'invalid-verification-id':
        return l10n.invalidOtp;
      default:
        return l10n.connectionError;
    }
  }

  /// Carries the verified Firebase token on to CompleteRegistrationScreen.
  ///
  /// This used to call firebase-login and drop the user straight into the app. That created the
  /// account with an empty password, so the same user could never sign in through the login screen
  /// afterwards - it failed with invalid credentials against a hash that was never set. Both paths
  /// now finish on the same screen, and the account is created with the password chosen there.
  ///
  /// The Firebase session is deliberately left signed in: the token is the credential
  /// CompleteRegistrationScreen presents, and it signs out once the account exists.
  Future<void> _exchangeFirebaseToken(String idToken) async {
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacementNamed(
      '/complete-registration',
      arguments: {
        'phone': widget.phoneNumber,
        'idToken': idToken,
      },
    );
  }

  Future<void> _resend() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _errorText = null;
    });
    try {
      if (_isFirebase) {
        await _resendViaFirebase();
        return;
      }

      final result = await ApiService.resendRegistrationOtp(widget.phoneNumber);
      // Success is silent; only surface a failure.
      if (mounted && result['success'] != true) {
        setState(
          () => _errorText =
              result['message'] ??
              AppLocalizations.of(context)!.connectionError,
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppTheme.brandGreen;
    const accentColor = AppTheme.brandGreenLight;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.verifyPhoneNumber),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: const TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text(
                _isFirebase ? l10n.codeSentToSms : l10n.codeSentToWhatsapp,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.enterVerificationCode,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              _OtpBoxes(
                length: _otpLength,
                hasError: _errorText != null,
                onChanged: (value) {
                  setState(() {
                    _otp = value;
                    if (_errorText != null) _errorText = null;
                  });
                },
                onCompleted: (_) => _verify(),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextButton(
                onPressed: _isResending ? null : _resend,
                child: _isResending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.resendCode,
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [primaryColor, accentColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading || _otp.length != _otpLength
                      ? null
                      : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.verify,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of single-digit boxes for entering an OTP. Focus auto-advances on input
/// and steps back on backspace; the joined value is reported through [onChanged],
/// and [onCompleted] fires once every box is filled.
class _OtpBoxes extends StatefulWidget {
  final int length;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;

  const _OtpBoxes({
    required this.length,
    required this.onChanged,
    this.onCompleted,
    this.hasError = false,
  });

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Pasted / autofilled the whole code into one box - spread it across.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final filled = digits.length.clamp(0, widget.length);
      _nodes[(filled - 1).clamp(0, widget.length - 1)].requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }

    widget.onChanged(_value);
    if (_value.length == widget.length) {
      _nodes[widget.length - 1].unfocus();
      widget.onCompleted?.call(_value);
    }
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _nodes[index - 1].requestFocus();
      widget.onChanged(_value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError ? AppTheme.error : AppTheme.neutral200;

    // Keep the boxes left-to-right and box 1 on the left even in Arabic (RTL) -
    // a numeric code is read and typed the same way in both languages.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (i) {
          return SizedBox(
            width: 46,
            height: 56,
            child: Focus(
              onKeyEvent: (_, event) => _onKey(i, event),
              child: TextField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.next,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.hasError
                          ? AppTheme.error
                          : AppTheme.brandGreen,
                      width: 2,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor, width: 1.5),
                  ),
                ),
                onChanged: (v) => _onChanged(i, v),
              ),
            ),
          );
        }),
      ),
    );
  }
}
