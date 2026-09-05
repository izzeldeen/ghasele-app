import 'package:flutter/material.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/services/firebase_otp_service.dart';
import 'package:ghasele/services/notification_service.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Step 3 (final) of the phone-first registration flow. The phone number is already verified,
/// so this screen collects a name and password, creates the account, and logs the user in.
/// Serves both verification paths. The WhatsApp OTP flow passes only [phoneNumber] and the backend
/// looks up the pending registration; the Firebase SMS flow creates no pending row, so it passes
/// [firebaseIdToken] and the account is created from that verified token instead.
class CompleteRegistrationScreen extends StatefulWidget {
  final String phoneNumber;

  /// Set only on the Firebase path. Its presence is what selects which endpoint to call.
  final String? firebaseIdToken;

  const CompleteRegistrationScreen({
    super.key,
    required this.phoneNumber,
    this.firebaseIdToken,
  });

  @override
  State<CompleteRegistrationScreen> createState() =>
      _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState
    extends State<CompleteRegistrationScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final idToken = widget.firebaseIdToken;
      final result = idToken != null
          // Firebase path: the verified token is the proof of phone ownership, and the account is
          // created with this password rather than the empty one firebase-login would leave.
          ? await ApiService.firebaseCompleteRegistration(
              idToken: idToken,
              fullName: _nameController.text.trim(),
              password: _passwordController.text,
            )
          : await ApiService.completeRegistration(
              phoneNumber: widget.phoneNumber,
              fullName: _nameController.text.trim(),
              password: _passwordController.text,
            );

      if (!mounted) return;

      if (result['success']) {
        if (idToken != null) {
          // Our own JWT keeps the user signed in from here. Leaving the Firebase session active
          // would make the next phone verification silently reuse this account.
          await FirebaseOtpService.signOut();
          if (!mounted) return;
        }
        await _handleAuthSuccess(result['data']);
      } else {
        setState(() => _errorText = result['message'] ??
            AppLocalizations.of(context)!.connectionError);
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _errorText = AppLocalizations.of(context)!.connectionError);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Leaves registration without creating the account, returning to the phone-number step.
  ///
  /// Goes back to signup rather than to the code screen: the verification the user just passed is
  /// spent, so the only useful thing to return to is entering a number again. The route is
  /// replaced, not pushed, so the stack stays login -> signup with nothing dead beneath it.
  ///
  /// The Firebase session is signed out on the way out. Its token stays valid for an hour, and
  /// leaving it active would make the next phone verification silently reuse this account instead
  /// of starting fresh - the same reason _submit signs out once the account exists.
  Future<void> _cancel() async {
    if (_isLoading) return;

    if (widget.firebaseIdToken != null) {
      await FirebaseOtpService.signOut();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/signup');
  }

  /// Persists the auth payload and routes into the app - mirrors LoginScreen.
  Future<void> _handleAuthSuccess(dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', data['token']);
    await prefs.setString('user_id', data['id']);
    await prefs.setString('user_username', data['username'] ?? '');
    await prefs.setString('user_email', data['email'] ?? '');
    await prefs.setString('user_fullname', data['fullName'] ?? '');
    await prefs.setString('user_phone', data['phoneNumber'] ?? '');
    final role = data['role'] ?? 'Client';
    await prefs.setString('user_role', role);

    try {
      await NotificationService.updateToken();
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
    }

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        role == 'Driver' ? '/driver-main' : '/main',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const primaryColor = AppTheme.brandGreen;
    const accentColor = AppTheme.brandGreenLight;

    return PopScope(
      // The arrow below and the Android back gesture must do the same thing: leave without
      // creating the account, and drop the Firebase session on the way out. canPop is false
      // so the gesture routes through _cancel rather than popping straight to the login
      // screen and leaving that session behind.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(l10n.completeProfile),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          // Explicit rather than automaticallyImplyLeading, so the arrow runs _cancel and clears
          // the Firebase session instead of popping blindly to whatever sits underneath.
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: primaryColor),
            // Nothing to go back to mid-submit: the account may already exist by the time the
            // request returns, so leaving now would strand it.
            onPressed: _isLoading ? null : _cancel,
          ),
          iconTheme: const IconThemeData(color: primaryColor),
          titleTextStyle: const TextStyle(
              color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.completeProfileSubtitle,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),

                  // Full Name
                  _buildInputLabel(l10n.fullName),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: l10n.pleaseEnterName,
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.pleaseEnterName : null,
                  ),
                  const SizedBox(height: 20),

                  // Password
                  _buildInputLabel(l10n.password),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    hint: l10n.password,
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscure: _obscurePassword,
                    onToggleVisibility: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    validator: (v) =>
                        v == null || v.length < 6 ? l10n.minCharacters : null,
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password
                  _buildInputLabel(l10n.confirmPassword),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: l10n.confirmPassword,
                    icon: Icons.lock_reset_rounded,
                    isPassword: true,
                    obscure: _obscureConfirmPassword,
                    onToggleVisibility: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.pleaseEnterPassword;
                      if (v != _passwordController.text) {
                        return l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 20),
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
                    onPressed: _isLoading ? null : _submit,
                    isLoading: _isLoading,
                    label: l10n.completeSignup,
                    primaryColor: primaryColor,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
          ),
        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.brandGreen),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey,
                    size: 20),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: _buildBorder(),
        enabledBorder: _buildBorder(),
        focusedBorder: _buildBorder(color: AppTheme.brandGreen),
      ),
      validator: validator,
    );
  }

  OutlineInputBorder _buildBorder({Color color = AppTheme.neutral200}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}
