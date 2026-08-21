import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/widgets/custom_toast.dart';
import 'package:ghasele/widgets/modern_widgets.dart';

/// Trips assigned to this driver that are on the "dry cleaner -> client" leg
/// (backend `Trip.Status` Cleaning). Each order progresses Ready -> Out for
/// delivery -> Delivered, mirroring the admin dashboard's Delivery Trips page.
class DriverDeliveryTripsView extends StatefulWidget {
  const DriverDeliveryTripsView({super.key});

  @override
  State<DriverDeliveryTripsView> createState() => DriverDeliveryTripsViewState();
}

class DriverDeliveryTripsViewState extends State<DriverDeliveryTripsView> {
  bool _loading = true;
  List<dynamic> _trips = [];
  String? _expandedTripId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final result = await ApiService.getMyTrips(token: token);

    if (!mounted) return;
    if (result['success']) {
      final all = result['data'] as List<dynamic>;
      setState(() {
        _trips = all.where((t) => t['status'] == 'Cleaning').toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (mounted) {
        CustomToast.show(context, message: result['message']?.toString() ?? 'Failed to load trips', type: ToastType.error);
      }
    }
  }

  Future<void> _openMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=Current+Location&destination=$lat,$lng&travelmode=driving');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _advance(Map<String, dynamic> order, String nextStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final result = nextStatus == 'Delivered'
        ? await ApiService.deliverOrder(orderId: order['id'] as String, token: token)
        : await ApiService.updateOrderStatus(orderId: order['id'] as String, status: nextStatus, token: token);

    if (!mounted) return;
    if (result['success']) {
      await _load();
    } else {
      CustomToast.show(context, message: result['message']?.toString() ?? 'Failed to update order', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: EmptyState(
                icon: Icons.home_work_outlined,
                title: l10n.driverNoDeliveryTrips,
                description: l10n.driverNoDeliveryTripsDesc,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final trip = _trips[i] as Map<String, dynamic>;
          final orders = (trip['orders'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          final delivered = orders.where((o) => o['status'] == 'Delivered').length;
          final expanded = _expandedTripId == trip['id'];

          return ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _expandedTripId = expanded ? null : trip['id'] as String),
                  child: Row(
                    children: [
                      const IconBox(icon: Icons.home_work_rounded),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#${trip['referenceNumber']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('$delivered/${orders.length} ${l10n.driverDelivered}', style: const TextStyle(fontSize: 12, color: AppTheme.neutral600)),
                          ],
                        ),
                      ),
                      Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                    ],
                  ),
                ),
                if (expanded) ...[
                  const Divider(height: 24),
                  ...orders.map((order) => _buildOrderRow(order, l10n)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order, AppLocalizations l10n) {
    final status = order['status'] as String? ?? '';

    Widget? actionButton;
    if (status == 'Ready') {
      actionButton = PrimaryButton(
        text: l10n.driverOutForDelivery,
        icon: Icons.local_shipping_rounded,
        onPressed: () => _advance(order, 'OutForDelivery'),
      );
    } else if (status == 'OutForDelivery') {
      actionButton = PrimaryButton(
        text: l10n.driverMarkDelivered,
        icon: Icons.check_circle_rounded,
        onPressed: () => _advance(order, 'Delivered'),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.neutral200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${order['referenceNumber']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('${order['userFullName'] ?? ''}', style: const TextStyle(fontSize: 13)),
                      if (order['userPhoneNumber'] != null)
                        Text('${order['userPhoneNumber']}', style: const TextStyle(fontSize: 12, color: AppTheme.neutral500)),
                    ],
                  ),
                ),
                StatusBadge(label: status, color: _statusColor(status)),
                if (status != 'Delivered')
                  IconButton(
                    icon: const Icon(Icons.directions_rounded, color: AppTheme.primary),
                    onPressed: () => _openMaps(
                      (order['lat'] as num?)?.toDouble(),
                      (order['long'] as num?)?.toDouble(),
                    ),
                  ),
              ],
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 8),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Ready':
        return AppTheme.success;
      case 'OutForDelivery':
        return AppTheme.warning;
      case 'Delivered':
        return AppTheme.info;
      default:
        return AppTheme.neutral500;
    }
  }
}
