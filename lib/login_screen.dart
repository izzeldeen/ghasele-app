import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/widgets/custom_toast.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String phone = _phoneController.text.trim();
        // Remove common mistakes: leading 0, 962, +962
        if (phone.startsWith('0')) {
          phone = phone.substring(1);
        } else if (phone.startsWith('+962')) {
          phone = phone.substring(4);
        } else if (phone.startsWith('962')) {
          phone = phone.substring(3);
        }
        
        // Final guard: should be exactly 9 digits for Jordan (7XXXXXXXX)
        if (phone.length != 9) {
          setState(() => _isLoading = false);
          CustomToast.show(context, message: "Phone number must be 9 digits (7XXXXXXXX)", type: ToastType.error);
          return;
        }

        final fullPhone = '+962$phone';
        
        debugPrint('LOGIN REQUEST: phone=$fullPhone, password=${_passwordController.text}');

        final result = await ApiService.login(
          phoneNumber: fullPhone,
          password: _passwordController.text,
        );

        if (mounted) {
          if (result['success']) {
            final data = result['data'];
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', data['token']);
            await prefs.setString('user_id', data['id']);
            await prefs.setString('user_username', data['username'] ?? '');
            await prefs.setString('user_email', data['email'] ?? '');
            await prefs.setString('user_fullname', data['fullName'] ?? '');
            await prefs.setString('user_phone', data['phoneNumber'] ?? '');

            try {
              await NotificationService.updateToken();
            } catch (e) {
              debugPrint('Failed to update FCM token: $e');
            }

            if (mounted) {
              CustomToast.show(context,
                  message: AppLocalizations.of(context)!.loginSuccess,
                  type: ToastType.success);
              Navigator.of(context).pushReplacementNamed('/main');
            }
          } else {
            if (mounted) {
              CustomToast.show(context,
                  message: l10n.invalidCredentials,
                  type: ToastType.error);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          CustomToast.show(context,
              message: 'Error: $e', type: ToastType.error);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const primaryColor = Color(0xFF005293);
    const accentColor = Color(0xFF00A3FF);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      body: Stack(
        children: [
          // Abstract Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.1), accentColor.withOpacity(0.05)],
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
                    const SizedBox(height: 100),
                    // Logo Section
                    Center(
                      child: Image.asset(
                        'assets/logo/Login-Logo.png',
                        height: 120, // Slightly larger since the container is gone
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Phone Input
                    _buildInputLabel(l10n.phoneNumber),
                    const SizedBox(height: 10),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.start,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10), // Allow for 0XXXXXXXX or 7XXXXXXXX
                        ],
                        decoration: InputDecoration(
                          hintText: '7XXXXXXXX',
                          prefixIcon: const Icon(Icons.phone_iphone_rounded, color: primaryColor),
                          prefixText: '+962 ',
                          prefixStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: _buildBorder(),
                          enabledBorder: _buildBorder(),
                          focusedBorder: _buildBorder(color: primaryColor),
                        ),
                        validator: (v) => v == null || v.isEmpty ? l10n.pleaseEnterPhoneNumber : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Password Input
                    _buildInputLabel(l10n.password),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: l10n.enterPassword,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: _buildBorder(),
                        enabledBorder: _buildBorder(),
                        focusedBorder: _buildBorder(color: primaryColor),
                      ),
                      validator: (v) => v == null || v.length < 6 ? l10n.minCharacters : null,
                    ),
                    
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Forgot Password logic
                        },
                        child: Text(
                          l10n.forgotPassword,
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sign In Button
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
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                l10n.signIn,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/privacy'),
                        child: Text(
                          l10n.privacyPolicy,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.dontHaveAccount, style: TextStyle(color: Colors.grey[600])),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/signup'),
                          child: Text(
                            l10n.signup,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
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

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }

  OutlineInputBorder _buildBorder({Color color = const Color(0xFFE5E7EB)}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}
