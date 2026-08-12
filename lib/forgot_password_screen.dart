import 'package:ghasele/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/widgets/custom_toast.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String phone = _phoneController.text.trim();
        if (phone.startsWith('0')) {
          phone = phone.substring(1);
        } else if (phone.startsWith('+962')) {
          phone = phone.substring(4);
        } else if (phone.startsWith('962')) {
          phone = phone.substring(3);
        }

        if (phone.length != 9) {
          setState(() => _isLoading = false);
          CustomToast.show(context, message: "Phone number must be 9 digits (7XXXXXXXX)", type: ToastType.error);
          return;
        }

        final fullPhone = '+962$phone';

        final result = await ApiService.forgotPassword(fullPhone);

        if (mounted) {
          if (result['success']) {
            CustomToast.show(context, message: result['message'] ?? 'OTP sent successfully', type: ToastType.success);
            Navigator.of(context).pushNamed(
              '/verify-otp',
              arguments: fullPhone,
            );
          } else {
            CustomToast.show(context, message: result['message'] ?? 'Failed to send OTP', type: ToastType.error);
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
        title: Text(l10n.forgotPassword),
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
                  "Enter your registered phone number. We'll send you a WhatsApp message with an OTP to reset your password.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 30),
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
                      LengthLimitingTextInputFormatter(10),
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
                            "Send OTP",
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
