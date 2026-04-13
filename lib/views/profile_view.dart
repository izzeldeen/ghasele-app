import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/login_screen.dart';
import 'package:ghasele/services/api_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_fullname') ?? 'User';
      _userEmail = prefs.getString('user_email') ?? '';
      _userPhone = prefs.getString('user_phone') ?? '';
    });
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.logout, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.neutral900)),
        content: Text(l10n.logoutConfirm, style: const TextStyle(color: AppTheme.neutral600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppTheme.neutral500, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.logout, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.deleteAccountWarning, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.error)),
        content: Text(l10n.deleteAccountConfirm, style: const TextStyle(color: AppTheme.neutral600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppTheme.neutral500, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.deleteAccount, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? '';
        final token = prefs.getString('auth_token') ?? '';

        // Call backend to delete all user data (required by Apple & Google policy)
        if (userId.isNotEmpty && token.isNotEmpty) {
          final result = await ApiService.deleteAccount(
            userId: userId,
            token: token,
          );
          if (!result['success'] && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to delete account. Please try again.')),
            );
            setState(() => _isDeleting = false);
            return;
          }
        }

        await prefs.clear();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: $e')),
          );
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context, l10n),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(l10n.account),
                  const SizedBox(height: 12),
                  _buildProfileItem(
                    icon: Icons.person_outline_rounded,
                    title: l10n.name,
                    subtitle: _userName,
                    color: Colors.blue,
                  ),
                  _buildProfileItem(
                    icon: Icons.email_outlined,
                    title: l10n.email,
                    subtitle: _userEmail,
                    color: Colors.orange,
                  ),
                  _buildProfileItem(
                    icon: Icons.phone_outlined,
                    title: l10n.phone,
                    subtitle: _userPhone,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(l10n.settings),
                  const SizedBox(height: 12),
                  _buildProfileItem(
                    icon: Icons.notifications_none_rounded,
                    title: l10n.notifications,
                    subtitle: l10n.noNotifications,
                    onTap: () {},
                    color: Colors.purple,
                  ),
                  _buildProfileItem(
                    icon: Icons.language_rounded,
                    title: l10n.language,
                    subtitle: Localizations.localeOf(context).languageCode == 'ar' ? 'العربية' : 'English',
                    onTap: () {},
                    color: Colors.teal,
                  ),
                  _buildProfileItem(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacyPolicy,
                    subtitle: '',
                    onTap: () => Navigator.of(context).pushNamed('/privacy'),
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 32),
                  _buildLogoutButton(l10n),
                  const SizedBox(height: 16),
                  _buildDeleteAccountButton(l10n),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withOpacity(0.1),
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userEmail.isNotEmpty ? _userEmail : l10n.welcomeBack,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppTheme.neutral400,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutral500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle.isNotEmpty ? subtitle : '—',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.neutral900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.neutral300,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.error,
          elevation: 0,
          side: const BorderSide(color: AppTheme.error, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          l10n.logout,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: _isDeleting ? null : _handleDeleteAccount,
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.neutral400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isDeleting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.error),
              )
            : Text(
                l10n.deleteAccount,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
              ),
      ),
    );
  }
}
