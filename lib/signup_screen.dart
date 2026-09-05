import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/config/auth_config.dart';
import 'package:ghasele/services/firebase_otp_service.dart';

/// Step 1 of the phone-first registration flow: the user enters only a phone number and we send
/// a verification code. Which channel carries it depends on [AuthConfig.useFirebaseOtp] - Firebase
/// Phone Auth (Google sends the SMS) or the original WhatsApp OTP.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  // Server-side error (e.g. number already registered), shown inline under the
  // field. Local "required"/format checks go through the form validator instead.
  String? _errorText;

  /// Original path: the backend generates the code and sends it over WhatsApp. Unchanged.
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Strips a leading 0 / 962 / +962 and returns the bare 9-digit local number,
  /// or null if it is not a valid Jordan mobile number.
  String? _normalizedPhone() {
    String phone = _phoneController.text.trim();
    if (phone.startsWith('+962')) {
      phone = phone.substring(4);
    } else if (phone.startsWith('962')) {
      phone = phone.substring(3);
    } else if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    return phone.length == 9 ? phone : null;
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _normalizedPhone();
    if (phone == null) {
      setState(() => _errorText = AppLocalizations.of(context)!.invalidPhoneNumber);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final fullPhone = '+962$phone';

      // Ask before sending anything. The Firebase path hands straight to Google and does not
      // reach our API until complete-registration, so without this check a number that already
      // has an account got an SMS, a name prompt and a password prompt before being refused.
      final check = await ApiService.isPhoneRegistered(fullPhone);
      if (!mounted) return;
      if (check != null && check.registered) {
        setState(() => _errorText =
            check.message ?? AppLocalizations.of(context)!.connectionError);
        return;
      }

      if (AuthConfig.useFirebaseOtp) {
        await _sendViaFirebase(fullPhone);
      } else {
        await _sendViaWhatsApp(fullPhone);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = AppLocalizations.of(context)!.connectionError);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendViaWhatsApp(String fullPhone) async {
    final result = await ApiService.startRegistration(fullPhone);

    if (!mounted) return;

    if (result['success']) {
      // No confirmation popup - landing on the code screen is the confirmation.
      Navigator.of(context).pushReplacementNamed(
        '/verify-registration-otp',
        arguments: fullPhone,
      );
    } else {
      setState(() => _errorText =
          result['message'] ?? AppLocalizations.of(context)!.connectionError);
    }
  }

  /// Firebase path: Google sends and later checks the SMS, so nothing reaches our backend until
  /// the user has proven the number and we hold a signed ID token.
  Future<void> _sendViaFirebase(String fullPhone) async {
    final result = await FirebaseOtpService.sendCode(fullPhone);

    if (!mounted) return;

    switch (result.status) {
      case OtpSendStatus.codeSent:
        Navigator.of(context).pushReplacementNamed(
          '/verify-registration-otp',
          arguments: {
            'phone': fullPhone,
            'verificationId': result.verificationId,
          },
        );
      case OtpSendStatus.autoVerified:
        // Android read the SMS by itself. Still route through the code screen rather than
        // duplicating the token exchange here - it sees the token and finishes immediately.
        Navigator.of(context).pushReplacementNamed(
          '/verify-registration-otp',
          arguments: {
            'phone': fullPhone,
            'idToken': result.idToken,
          },
        );
      case OtpSendStatus.failed:
        setState(() => _errorText = _firebaseSendError(result.errorCode));
    }
  }

  /// Maps Firebase's error codes onto the strings this app already ships. Anything unrecognised
  /// falls back to the generic connection message rather than surfacing a raw Firebase code.
  String _firebaseSendError(String? code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'invalid-phone-number':
        return l10n.invalidPhoneNumber;
      default:
        return l10n.connectionError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const primaryColor = AppTheme.brandGreen;
    const accentColor = AppTheme.brandGreenLight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Abstract Background
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.05),
                    accentColor.withOpacity(0.1)
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: primaryColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 50),
                      // Logo Section
                      Center(
                        child: Image.asset(
                          'assets/logo/logo-trans.png',
                          height: 120,
                          fit: BoxFit.contain,
                          // Source is 1024x1024 (~4MB decoded); cap the decode to
                          // what a 3x screen actually needs at this size.
                          cacheWidth: 512,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text(
                        l10n.signup,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neutral900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.enterPhoneToRegister,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 30),

                      // Phone Input
                      _buildInputLabel(l10n.phoneNumber),
                      const SizedBox(height: 8),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textAlign: TextAlign.start,
                          onChanged: (_) {
                            if (_errorText != null) {
                              setState(() => _errorText = null);
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: _buildInputDecoration(
                            hint: '7XXXXXXXX',
                            icon: Icons.phone_iphone_rounded,
                            prefixText: '+962 ',
                            primaryColor: primaryColor,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.pleaseEnterPhoneNumber;
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorText!,
                          style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                      const SizedBox(height: 40),

                      _buildActionButton(
                        onPressed: _isLoading ? null : _sendCode,
                        isLoading: _isLoading,
                        label: l10n.sendCode,
                        primaryColor: primaryColor,
                        accentColor: accentColor,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/privacy'),
                          child: Text(
                            l10n.privacyPolicy,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.alreadyHaveAccount,
                              style: TextStyle(color: Colors.grey[600])),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushReplacementNamed('/login'),
                            child: Text(
                              l10n.signIn,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String label,
    bool isLoading = false,
    required Color primaryColor,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [primaryColor, accentColor]),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(
                label,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.neutral900),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    String? prefixText,
    required Color primaryColor,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryColor),
      prefixText: prefixText,
      prefixStyle: prefixText != null
          ? TextStyle(
              color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: _buildBorder(),
      enabledBorder: _buildBorder(),
      focusedBorder: _buildBorder(color: primaryColor),
    );
  }

  OutlineInputBorder _buildBorder({Color color = AppTheme.neutral200}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}
