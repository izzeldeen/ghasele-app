import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/widgets/custom_toast.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() => _currentStep = 1);
    }
  }

  void _previousStep() {
    setState(() => _currentStep = 0);
  }

  Future<void> _signUp() async {
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
          setState(() {
            _isLoading = false;
            _currentStep = 0; // Go back to step 1 to fix phone
          });
          CustomToast.show(context, message: "Phone number must be 9 digits (7XXXXXXXX)", type: ToastType.error);
          return;
        }

        final fullPhone = '+962$phone';
        
        debugPrint('SIGNUP REQUEST: phone=$fullPhone, name=${_nameController.text.trim()}, password=${_passwordController.text}');

        final result = await ApiService.signup(
          phoneNumber: fullPhone,
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );

        debugPrint('SIGNUP RESULT: $result');

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
                  message: AppLocalizations.of(context)!.signupSuccess,
                  type: ToastType.success);
              Navigator.of(context).pushReplacementNamed('/main');
            }
          } else {
            CustomToast.show(context,
                message: result['message'] ?? 'Sign up failed',
                type: ToastType.error);
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
                  colors: [primaryColor.withOpacity(0.05), accentColor.withOpacity(0.1)],
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
                      onPressed: () {
                        if (_currentStep == 1) {
                          _previousStep();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    
                    const SizedBox(height: 40),
                    // Logo Section
                    Center(
                      child: Image.asset(
                        'assets/logo/Login-Logo.png',
                        height: 100, // Balanced size for signup
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),

                if (_currentStep == 0) ...[
                  // Full Name
                  _buildInputLabel(l10n.fullName),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hint: l10n.pleaseEnterName,
                        icon: Icons.person_outline_rounded,
                        validator: (v) => v == null || v.isEmpty ? l10n.pleaseEnterName : null,
                      ),
                      const SizedBox(height: 20),

                      // Phone Input
                      _buildInputLabel(l10n.phoneNumber),
                      const SizedBox(height: 8),
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
                          decoration: _buildInputDecoration(
                            hint: '7XXXXXXXX',
                            icon: Icons.phone_iphone_rounded,
                            prefixText: '+962 ',
                            primaryColor: primaryColor,
                          ),
                          validator: (v) => v == null || v.isEmpty ? l10n.pleaseEnterPhoneNumber : null,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Next Button
                      _buildActionButton(
                        onPressed: _nextStep,
                        label: l10n.next,
                        primaryColor: primaryColor,
                        accentColor: accentColor,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/privacy'),
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
                    ] else ...[
                      // Password
                      _buildInputLabel(l10n.password),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _passwordController,
                        hint: l10n.password,
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscure: _obscurePassword,
                        onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                        validator: (v) => v == null || v.length < 6 ? l10n.minCharacters : null,
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
                        onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.pleaseEnterPassword;
                          if (v != _passwordController.text) return l10n.passwordsDoNotMatch;
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      _buildActionButton(
                        onPressed: _isLoading ? null : _signUp,
                        isLoading: _isLoading,
                        label: l10n.signup,
                        primaryColor: primaryColor,
                        accentColor: accentColor,
                      ),

                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: _isLoading ? null : _previousStep,
                          child: Text(l10n.backToPersonalInfo, 
                            style: TextStyle(color: _isLoading ? Colors.grey[400] : Colors.grey[600])),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.alreadyHaveAccount, style: TextStyle(color: Colors.grey[600])),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                          child: Text(
                            l10n.signIn,
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
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
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
      decoration: _buildInputDecoration(
        hint: hint,
        icon: icon,
        isPassword: isPassword,
        obscure: obscure,
        onToggleVisibility: onToggleVisibility,
        primaryColor: const Color(0xFF005293),
      ),
      validator: validator,
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    String? prefixText,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
    required Color primaryColor,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryColor),
      prefixText: prefixText,
      prefixStyle: prefixText != null ? TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16) : null,
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20),
              onPressed: onToggleVisibility,
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: _buildBorder(),
      enabledBorder: _buildBorder(),
      focusedBorder: _buildBorder(color: primaryColor),
    );
  }

  OutlineInputBorder _buildBorder({Color color = const Color(0xFFE5E7EB)}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}
