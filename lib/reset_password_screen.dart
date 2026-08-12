import 'package:ghasele/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/widgets/custom_toast.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phoneNumber;
  final String otp;

  const ResetPasswordScreen({super.key, required this.phoneNumber, required this.otp});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        CustomToast.show(context, message: 'Passwords do not match', type: ToastType.error);
        return;
      }

      setState(() => _isLoading = true);

      try {
        final result = await ApiService.resetPassword(
          widget.phoneNumber,
          widget.otp,
          _passwordController.text,
        );

        if (mounted) {
          if (result['success']) {
            CustomToast.show(context, message: 'Password reset successfully. Please login.', type: ToastType.success);
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          } else {
            CustomToast.show(context, message: result['message'] ?? 'Failed to reset password', type: ToastType.error);
          }
        }
      } catch (e) {
        if (mounted) {
          CustomToast.show(context, message: 'Error: $e', type: ToastType.error);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: const TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Create a new password for your account.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 30),
                
                // Password Input
                _buildInputLabel(l10n.password),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'New Password',
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
                const SizedBox(height: 24),
                
                // Confirm Password Input
                _buildInputLabel('Confirm Password'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                const SizedBox(height: 32),
                
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
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            "Save Password",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
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
        color: AppTheme.neutral900,
      ),
    );
  }

  OutlineInputBorder _buildBorder({Color color = AppTheme.neutral200}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}
