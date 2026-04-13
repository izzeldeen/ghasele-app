import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'views/home_view.dart';
import 'views/orders_view.dart';
import 'views/notifications_view.dart';
import 'views/profile_view.dart';
import 'views/support_view.dart';
import 'views/pricing_view.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/locale_provider.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 2});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final GlobalKey<HomeViewState> _homeKey = GlobalKey<HomeViewState>();
  final GlobalKey<OrdersViewState> _ordersKey = GlobalKey<OrdersViewState>();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final result = await ApiService.getNotifications(token);
        if (result['success']) {
          final List notifications = result['data'];
          if (mounted) {
            setState(() {
              _unreadCount = notifications.where((n) => n['isRead'] == false).length;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    final List<Widget> views = [
      OrdersView(key: _ordersKey),
      const PricingView(),
      HomeView(key: _homeKey),
      const SupportView(),
      const ProfileView(),
    ];
    
    final titles = [
      l10n.orders,
      l10n.pricing,
      l10n.home,
      l10n.support,
      l10n.profile,
    ];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsView()),
              );
              _fetchUnreadCount(); // Refresh count when returning
            },
          ),
          IconButton(
            icon: const Icon(Icons.language_rounded),
            onPressed: () {
              localeProvider.toggleLocale();
            },
            tooltip: localeProvider.locale.languageCode == 'ar' ? 'English' : 'العربية',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: views,
      ),
      bottomNavigationBar: _buildModernBottomNav(l10n),
    );
  }

  Widget _buildModernBottomNav(AppLocalizations l10n) {
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
                icon: Icons.receipt_long_rounded,
                label: l10n.orders,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.sell_rounded,
                label: l10n.pricing,
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.home_rounded,
                label: l10n.home,
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.support_agent_rounded,
                label: l10n.support,
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: l10n.profile,
                index: 4,
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
        setState(() {
          _currentIndex = index;
        });
        if (index == 0) {
          _ordersKey.currentState?.fetchOrders();
        } else if (index == 2) {
          _homeKey.currentState?.refresh();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.neutral400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
