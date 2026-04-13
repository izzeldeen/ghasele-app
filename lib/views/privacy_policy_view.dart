import 'package:flutter/material.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/theme/app_theme.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.neutral900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyPolicy,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
             _buildSection(
              isAr ? "1. المعلومات التي نجمعها" : "1. Information We Collect",
              isAr 
                ? "نحن نجمع معلومات معينة لتقديم خدماتنا، بما في ذلك الاسم ورقم الهاتف والموقع الجغرافي الدقيق لغايات الاستلام والتوصيل."
                : "We collect certain information to provide our services, including Name, Phone Number, and Precise Location for pickup and delivery purposes.",
            ),
            _buildSection(
              isAr ? "2. كيف نستخدم معلوماتك" : "2. How We Use Your Information",
              isAr 
                ? "نستخدم معلوماتك لمعالجة طلبات التنظيف، وتتبع السائقين، والتواصل معك بخصوص حالة طلبك."
                : "We use your information to process laundry orders, track drivers, and communicate with you about your order status.",
            ),
            _buildSection(
              isAr ? "3. مشاركة البيانات" : "3. Data Sharing",
              isAr 
                ? "نحن لا نبيع بياناتك الشخصية. قد نشارك معلومات الموقع مع السائقين لتمكين الاستلام والتوصيل فقط."
                : "We do not sell your personal data. We may share location information with drivers to enable pickup and delivery only.",
            ),
            _buildSection(
              isAr ? "4. حذف الحساب" : "4. Account Deletion",
              isAr 
                ? "يمكنك طلب حذف حسابك وبياناتك في أي وقت من خلال إعدادات الحساب في التطبيق."
                : "You can request the deletion of your account and data at any time through the account settings in the app.",
            ),
            _buildSection(
              isAr ? "5. اتصل بنا" : "5. Contact Us",
              isAr 
                ? "إذا كان لديك أي أسئلة حول سياسة الخصوصية، يرجى التواصل معنا عبر قسم الدعم."
                : "If you have any questions about this Privacy Policy, please contact us via the support section.",
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                isAr ? "آخر تحديث: أبريل 2026" : "Last Updated: April 2026",
                style: const TextStyle(color: AppTheme.neutral400, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.neutral600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
