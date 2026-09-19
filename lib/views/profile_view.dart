import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/login_screen.dart';
import 'package:ghasele/providers/locale_provider.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/utils/jordan_phone.dart';
import 'package:ghasele/views/notifications_view.dart';
import 'package:ghasele/widgets/custom_toast.dart';

/// The account tab.
///
/// Open to guests on purpose. Everything here that is not tied to an account - the language,
/// the privacy policy - works without one, and the account half becomes an invitation rather
/// than a locked door. Sending a guest straight to a full-screen login instead reads as having
/// been signed out of an app they were happily using.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView> {
  String _userId = '';
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _username = '';

  /// True when nobody is signed in. The app is usable as a guest, so this screen has to render
  /// something sensible rather than assuming a stored profile exists.
  bool _isGuest = true;
  bool _isDeleting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Re-reads the session. Public so the tab can refresh itself after the user signs in
  /// somewhere else in the app without the whole screen being rebuilt from scratch.
  Future<void> refresh() => _loadUserData();

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    setState(() {
      _isGuest = token == null || token.isEmpty;
      _userId = prefs.getString('user_id') ?? '';
      _userName = prefs.getString('user_fullname') ?? '';
      _userEmail = prefs.getString('user_email') ?? '';
      _userPhone = prefs.getString('user_phone') ?? '';
      _username = prefs.getString('user_username') ?? '';
    });
  }

  // ---------------------------------------------------------------------------
  // Editing
  // ---------------------------------------------------------------------------

  /// Sends the whole profile with [fullName] or [phoneNumber] swapped for the new value.
  ///
  /// One method for both fields because the endpoint replaces the entire row either way -
  /// splitting it into save-name and save-phone would be two copies of the same call with a
  /// different argument moved.
  Future<void> _saveProfile({String? fullName, String? phoneNumber}) async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty || _userId.isEmpty || !mounted) return;

    final nextName = fullName ?? _userName;
    final nextPhone = phoneNumber ?? _userPhone;

    setState(() => _isSaving = true);
    try {
      final result = await ApiService.updateUserProfile(
        userId: _userId,
        fullName: nextName,
        phoneNumber: nextPhone,
        // Resent unchanged: the endpoint replaces the whole row. Falling back to the phone
        // number matches what the phone-first signup stores when no username was chosen.
        username: _username.isNotEmpty ? _username : nextPhone,
        email: _userEmail.isNotEmpty ? _userEmail : null,
        token: token,
      );
      if (!mounted) return;

      if (result['success'] != true) {
        CustomToast.show(
          context,
          message: _saveErrorMessage(result, l10n),
          type: ToastType.error,
        );
        return;
      }

      // Mirrored locally so the rest of the app - checkout, order contact details - reads the
      // new value without another round trip.
      await prefs.setString('user_fullname', nextName);
      await prefs.setString('user_phone', nextPhone);
      if (!mounted) return;

      // No success popup. CustomToast is a centre-screen card over a scrim, which is a
      // lot of ceremony for an edit whose result is already on screen: the setState
      // above repaints the row with the new value, which is the confirmation. Failures
      // still speak up, because those the customer cannot see for themselves.
      setState(() {
        _userName = nextName;
        _userPhone = nextPhone;
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// The one failure worth its own wording: the number belongs to somebody else's account, which
  /// the customer can act on, unlike a generic server error.
  String _saveErrorMessage(Map<String, dynamic> result, AppLocalizations l10n) {
    if (result['errorCode'] == 'auth.phone_already_exists') {
      return l10n.phoneAlreadyInUse;
    }
    return result['message']?.toString() ?? l10n.connectionError;
  }

  Future<void> _editName() async {
    final l10n = AppLocalizations.of(context)!;
    final value = await _showEditSheet(
      title: l10n.editName,
      label: l10n.fullName,
      note: l10n.nameChangeNote,
      icon: Icons.person_outline_rounded,
      initialValue: _userName,
      keyboardType: TextInputType.name,
      formatters: [LengthLimitingTextInputFormatter(60)],
      validator: (value) =>
          (value ?? '').trim().isEmpty ? l10n.pleaseEnterName : null,
    );
    if (value == null || !mounted) return;
    await _saveProfile(fullName: value.trim());
  }

  Future<void> _editPhone() async {
    final l10n = AppLocalizations.of(context)!;
    final value = await _showEditSheet(
      title: l10n.editPhoneNumber,
      label: l10n.phoneNumber,
      note: l10n.phoneChangeNote,
      icon: Icons.phone_outlined,
      // Shown as the bare local number so the field matches the "+962" prefix beside it.
      initialValue: localJordanDigits(_userPhone) ?? '',
      keyboardType: TextInputType.phone,
      formatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      prefixText: '+962 ',
      forceLtr: true,
      validator: (value) =>
          localJordanDigits(value ?? '') == null ? l10n.invalidPhoneNumber : null,
    );
    if (value == null || !mounted) return;
    // Stored in E.164, which is the only spelling the rest of the API accepts.
    await _saveProfile(phoneNumber: jordanPhoneToE164(value)!);
  }

  /// A single-field editor in a bottom sheet rather than a dialog: it sits above the keyboard
  /// instead of behind it, and the save button stays within thumb reach on a tall phone.
  ///
  /// Returns the raw text the user entered, or null if they backed out.
  Future<String?> _showEditSheet({
    required String title,
    required String label,
    required String note,
    required IconData icon,
    required String initialValue,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> formatters = const [],
    String? prefixText,
    bool forceLtr = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        // The sheet is its own route, so it has to lift itself clear of the keyboard; without
        // this the field it exists to show is the part that ends up hidden.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreenSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.neutral900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _maybeLtr(
                  forceLtr,
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: keyboardType,
                    inputFormatters: formatters,
                    textAlign: forceLtr ? TextAlign.left : TextAlign.start,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (formKey.currentState!.validate()) {
                        Navigator.of(sheetContext).pop(controller.text);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: label,
                      prefixText: prefixText,
                      filled: true,
                      fillColor: AppTheme.neutral50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.neutral200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.neutral200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
                      ),
                    ),
                    validator: validator,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 15, color: AppTheme.neutral400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppTheme.neutral500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.of(sheetContext).pop(controller.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      l10n.save,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.neutral500),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
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

  /// Phone numbers read left-to-right in every locale. Inheriting the ambient direction puts
  /// the "+962 " prefix on the right in Arabic, where it reads as a suffix.
  Widget _maybeLtr(bool force, Widget child) => force
      ? Directionality(textDirection: TextDirection.ltr, child: child)
      : child;

  // ---------------------------------------------------------------------------
  // Language
  // ---------------------------------------------------------------------------

  /// Offered to guests too: the language is a property of the phone in the customer's hand,
  /// not of an account, and an Arabic speaker should not have to register to read the app.
  Future<void> _chooseLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<LocaleProvider>();
    final current = provider.locale.languageCode;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.chooseLanguage,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 16),
            // Each option is written in its own language, never translated. Someone who has
            // the app in the wrong language needs to recognise their own by sight.
            _buildLanguageOption(sheetContext, 'العربية', 'ar', current),
            const SizedBox(height: 8),
            _buildLanguageOption(sheetContext, 'English', 'en', current),
          ],
        ),
      ),
    );

    if (selected == null || selected == current) return;
    await provider.setLocale(Locale(selected));
  }

  Widget _buildLanguageOption(
      BuildContext sheetContext, String label, String code, String current) {
    final isSelected = code == current;
    return Material(
      color: isSelected ? AppTheme.brandGreenSurface : AppTheme.neutral50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.of(sheetContext).pop(code),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppTheme.primaryDark : AppTheme.neutral700,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await _confirm(
      title: l10n.logout,
      message: l10n.logoutConfirm,
      confirmLabel: l10n.logout,
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        // Logging out drops back to the guest home tab, not the login screen: the app is
        // usable without an account, so signing out should not feel like being locked out.
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
          arguments: 2,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await _confirm(
      title: l10n.deleteAccountWarning,
      message: l10n.deleteAccountConfirm,
      confirmLabel: l10n.deleteAccount,
      titleColor: AppTheme.error,
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

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    Color titleColor = AppTheme.neutral900,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.w800, color: titleColor)),
        content: Text(message, style: const TextStyle(color: AppTheme.neutral600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel,
                style: const TextStyle(
                    color: AppTheme.neutral500, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Signs in without losing the tab. The login screen replaces itself with a fresh /main on
  /// success; backing out returns here, so the session is re-read either way.
  Future<void> _promptSignIn() async {
    await Navigator.of(context).pushNamed('/login');
    if (!mounted) return;
    await _loadUserData();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: Stack(
        children: [
          SingleChildScrollView(
            // AlwaysScrollable so the page still accepts a drag when its content happens to be
            // shorter than the viewport (large-text settings shrink nothing, but a small phone in
            // landscape can), rather than silently ignoring the gesture.
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              children: [
                _buildHeader(context, l10n),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isGuest) ...[
                        _buildGuestCard(l10n),
                        const SizedBox(height: 28),
                      ] else ...[
                        _buildSectionTitle(l10n.account),
                        const SizedBox(height: 10),
                        _buildCard([
                          _buildRow(
                            icon: Icons.person_outline_rounded,
                            color: AppTheme.primary,
                            title: l10n.name,
                            value: _userName,
                            onTap: _editName,
                          ),
                          _buildRow(
                            icon: Icons.phone_outlined,
                            color: const Color(0xFF3B82F6),
                            title: l10n.phone,
                            value: _userPhone,
                            onTap: _editPhone,
                            forceLtrValue: true,
                          ),
                          // Read-only: the phone-first signup never collects an email, and
                          // changing one would need a verification round this screen has no
                          // way to run.
                          if (_userEmail.isNotEmpty)
                            _buildRow(
                              icon: Icons.email_outlined,
                              color: const Color(0xFFF59E0B),
                              title: l10n.email,
                              value: _userEmail,
                              forceLtrValue: true,
                            ),
                        ]),
                        const SizedBox(height: 28),
                      ],
                      _buildSectionTitle(l10n.appPreferences),
                      const SizedBox(height: 10),
                      _buildCard([
                        _buildRow(
                          icon: Icons.language_rounded,
                          color: const Color(0xFF14B8A6),
                          title: l10n.language,
                          value: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'العربية'
                              : 'English',
                          onTap: _chooseLanguage,
                        ),
                        // Account-scoped: notifications are fetched with a token.
                        if (!_isGuest)
                          _buildRow(
                            icon: Icons.notifications_none_rounded,
                            color: const Color(0xFF8B5CF6),
                            title: l10n.notifications,
                            value: '',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const NotificationsView()),
                            ),
                          ),
                        _buildRow(
                          icon: Icons.privacy_tip_outlined,
                          color: AppTheme.neutral500,
                          title: l10n.privacyPolicy,
                          value: '',
                          onTap: () => Navigator.of(context).pushNamed('/privacy'),
                        ),
                      ]),
                      const SizedBox(height: 28),
                      if (!_isGuest) ...[
                        _buildLogoutButton(l10n),
                        const SizedBox(height: 12),
                        _buildDeleteAccountButton(l10n),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Covers the whole screen rather than one row: a save in flight replaces the row's
          // own value, so letting a second edit start would race the first.
          if (_isSaving)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 36),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white.withOpacity(0.16),
              child: _isGuest
                  ? const Icon(Icons.person_outline_rounded,
                      size: 42, color: Colors.white)
                  : Text(
                      _initials(_userName),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _isGuest ? l10n.guest : (_userName.isNotEmpty ? _userName : l10n.guest),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          // The phone number is the thing a signed-in customer recognises themselves by -
          // the phone-first signup means most accounts have no email to show here.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              _isGuest
                  ? l10n.browsingAsGuest
                  : (_userPhone.isNotEmpty
                      ? _userPhone
                      : (_userEmail.isNotEmpty ? _userEmail : l10n.welcomeBack)),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Up to two letters, so "Izz Kalbouneh" reads as IK rather than I.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  /// The guest half of the screen: what an account would add, then the way to get one. Framed
  /// as what is on offer rather than what is missing, and skippable - the settings below it
  /// work either way.
  Widget _buildGuestCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neutral900.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.guestBenefitsTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 18),
          _buildBenefit(Icons.receipt_long_rounded, l10n.guestBenefitOrders),
          const SizedBox(height: 14),
          _buildBenefit(Icons.place_outlined, l10n.guestBenefitAddresses),
          const SizedBox(height: 14),
          _buildBenefit(Icons.support_agent_rounded, l10n.guestBenefitSupport),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _promptSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.login_rounded, size: 20),
              label: Text(
                l10n.signIn,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.brandGreenSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: AppTheme.primaryDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: AppTheme.neutral400,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  /// One card per section with hairlines between the rows, rather than a separate card each.
  /// Grouping is what tells the eye that these rows belong together.
  Widget _buildCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neutral200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 64, right: 16),
                child: Divider(height: 1, thickness: 1, color: AppTheme.neutral100),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    VoidCallback? onTap,
    bool forceLtrValue = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasValue = value.isNotEmpty;
    final editsInPlace = title == l10n.name || title == l10n.phone;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral500,
                      ),
                    ),
                    if (hasValue) ...[
                      const SizedBox(height: 3),
                      _maybeLtr(
                        forceLtrValue,
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: forceLtrValue ? TextAlign.left : TextAlign.start,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.neutral900,
                          ),
                        ),
                      ),
                    ] else if (onTap != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        l10n.notSet,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutral300,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                // A pencil where tapping changes the stored value, a chevron where it opens
                // another screen - so the row says which of the two it is before it is tapped.
                Icon(
                  editsInPlace ? Icons.edit_outlined : Icons.arrow_forward_ios_rounded,
                  size: editsInPlace ? 17 : 13,
                  color: AppTheme.neutral300,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 54,
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
