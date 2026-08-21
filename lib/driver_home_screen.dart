import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/login_screen.dart';
import 'package:ghasele/providers/locale_provider.dart';
import 'views/driver_collection_trips_view.dart';
import 'views/driver_delivery_trips_view.dart';

/// Post-login shell for the Driver role: exactly two tabs, mirroring the two
/// flows the admin dashboard already runs - collecting orders from clients
/// and taking them to the dry cleaner, then collecting from the dry cleaner
/// and delivering them back to clients.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<DriverCollectionTripsViewState> _collectionKey =
      GlobalKey<DriverCollectionTripsViewState>();
  final GlobalKey<DriverDeliveryTripsViewState> _deliveryKey =
      GlobalKey<DriverDeliveryTripsViewState>();

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.logout, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(l10n.logout),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    final titles = [l10n.driverCollectionTab, l10n.driverDeliveryTab];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            onPressed: () => localeProvider.toggleLocale(),
            tooltip: localeProvider.locale.languageCode == 'ar' ? 'English' : 'العربية',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: l10n.logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DriverCollectionTripsView(key: _collectionKey),
          DriverDeliveryTripsView(key: _deliveryKey),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(l10n),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.local_shipping_rounded,
                label: l10n.driverCollectionTab,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.home_work_rounded,
                label: l10n.driverDeliveryTab,
                index: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) {
          _collectionKey.currentState?.refresh();
        } else {
          _deliveryKey.currentState?.refresh();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.neutral400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
