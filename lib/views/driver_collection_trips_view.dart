import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/widgets/custom_toast.dart';
import 'package:ghasele/widgets/modern_widgets.dart';

/// Trips assigned to this driver that are still on the "client -> dry
/// cleaner" leg (backend `Trip.Status` Assigned/Collected). Tapping a trip
/// opens the stop list; saving items at a stop marks that order Collected,
/// and once every stop is done the driver hands the whole trip to the
/// cleaner - mirroring the admin dashboard's Collecting Trip flow.
class DriverCollectionTripsView extends StatefulWidget {
  const DriverCollectionTripsView({super.key});

  @override
  State<DriverCollectionTripsView> createState() => DriverCollectionTripsViewState();
}

class DriverCollectionTripsViewState extends State<DriverCollectionTripsView> {
  bool _loading = true;
  List<dynamic> _trips = [];
  Map<String, dynamic>? _openTrip;

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
        _trips = all.where((t) => t['status'] == 'Assigned' || t['status'] == 'Collected').toList();
        _loading = false;
        // Keep the open trip's data fresh without kicking the driver back to the list.
        if (_openTrip != null) {
          final refreshed = _trips.firstWhere((t) => t['id'] == _openTrip!['id'], orElse: () => null);
          _openTrip = refreshed as Map<String, dynamic>?;
        }
      });
    } else {
      setState(() => _loading = false);
      if (mounted) {
        CustomToast.show(context, message: result['message']?.toString() ?? 'Failed to load trips', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_openTrip != null) {
      return _TripCollectDetail(
        trip: _openTrip!,
        onBack: () => setState(() => _openTrip = null),
        onChanged: _load,
      );
    }

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
                icon: Icons.local_shipping_outlined,
                title: l10n.driverNoCollectionTrips,
                description: l10n.driverNoCollectionTripsDesc,
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
          final orders = (trip['orders'] as List<dynamic>? ?? []);
          final collected = orders.where((o) => o['status'] == 'Collected').length;

          return ModernCard(
            onTap: () => setState(() => _openTrip = trip),
            child: Row(
              children: [
                IconBox(icon: Icons.local_shipping_rounded),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${trip['referenceNumber']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${trip['cleanerName'] ?? ''}', style: const TextStyle(color: AppTheme.neutral500, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('$collected/${orders.length} ${l10n.driverCollected}', style: const TextStyle(fontSize: 12, color: AppTheme.neutral600)),
                    ],
                  ),
                ),
                StatusBadge(
                  label: trip['status'] == 'Collected' ? l10n.driverReadyForHandover : l10n.driverInProgress,
                  color: trip['status'] == 'Collected' ? AppTheme.success : AppTheme.warning,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TripCollectDetail extends StatefulWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onBack;
  final VoidCallback onChanged;

  const _TripCollectDetail({required this.trip, required this.onBack, required this.onChanged});

  @override
  State<_TripCollectDetail> createState() => _TripCollectDetailState();
}

class _TripCollectDetailState extends State<_TripCollectDetail> {
  String? _selectedOrderId;
  final List<Map<String, dynamic>> _basket = [];
  final _typeController = TextEditingController();
  int _quantity = 1;
  String _serviceType = 'Both';
  bool _saving = false;
  bool _handingOver = false;

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  List<dynamic> get _orders => widget.trip['orders'] as List<dynamic>? ?? [];

  bool get _allCollected => _orders.isNotEmpty && _orders.every((o) => o['status'] == 'Collected');

  Future<void> _openMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=Current+Location&destination=$lat,$lng&travelmode=driving');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _saveAndCollect() async {
    if (_selectedOrderId == null || _basket.isEmpty) return;
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final itemsResult = await ApiService.addOrderItems(
      orderId: _selectedOrderId!,
      items: _basket,
      token: token,
    );

    if (!itemsResult['success']) {
      if (mounted) {
        setState(() => _saving = false);
        CustomToast.show(context, message: itemsResult['message']?.toString() ?? 'Failed to save items', type: ToastType.error);
      }
      return;
    }

    final collectResult = await ApiService.collectOrder(orderId: _selectedOrderId!, token: token);

    if (!mounted) return;
    setState(() => _saving = false);

    if (collectResult['success']) {
      _basket.clear();
      widget.onChanged();
      CustomToast.show(context, message: AppLocalizations.of(context)!.driverItemsSaved, type: ToastType.success);
      setState(() {
        widget.trip['orders'] = collectResult['data']['orders'];
        widget.trip['status'] = collectResult['data']['status'];
        final next = _orders.cast<Map<String, dynamic>>().firstWhere(
              (o) => o['status'] != 'Collected',
              orElse: () => {},
            );
        _selectedOrderId = next.isNotEmpty ? next['id'] as String : null;
      });
    } else {
      CustomToast.show(context, message: collectResult['message']?.toString() ?? 'Failed to mark collected', type: ToastType.error);
    }
  }

  Future<void> _handOver() async {
    setState(() => _handingOver = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final result = await ApiService.deliverToCleaner(tripId: widget.trip['id'] as String, token: token);

    if (!mounted) return;
    setState(() => _handingOver = false);

    if (result['success']) {
      widget.onChanged();
      widget.onBack();
    } else {
      CustomToast.show(context, message: result['message']?.toString() ?? 'Failed to hand over trip', type: ToastType.error);
    }
  }

  void _addToBasket() {
    if (_typeController.text.trim().isEmpty) return;
    setState(() {
      _basket.add({
        'itemType': _typeController.text.trim(),
        'quantity': _quantity,
        'serviceType': _serviceType,
      });
      _typeController.clear();
      _quantity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: Text('#${widget.trip['referenceNumber']}'),
      ),
      body: _allCollected
          ? _buildHandover(l10n)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(l10n.driverStops, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._orders.cast<Map<String, dynamic>>().map((order) {
                        final collected = order['status'] == 'Collected';
                        final selected = order['id'] == _selectedOrderId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ModernCard(
                            onTap: collected ? null : () => setState(() => _selectedOrderId = order['id'] as String),
                            child: Row(
                              children: [
                                Icon(
                                  collected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: collected ? AppTheme.success : (selected ? AppTheme.primary : AppTheme.neutral400),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('#${order['referenceNumber']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text('${order['userFullName'] ?? ''}', style: const TextStyle(fontSize: 13)),
                                      if (order['userPhoneNumber'] != null)
                                        Text('${order['userPhoneNumber']}', style: const TextStyle(fontSize: 12, color: AppTheme.neutral500)),
                                    ],
                                  ),
                                ),
                                if (!collected)
                                  IconButton(
                                    icon: const Icon(Icons.directions_rounded, color: AppTheme.primary),
                                    onPressed: () => _openMaps(
                                      (order['lat'] as num?)?.toDouble(),
                                      (order['long'] as num?)?.toDouble(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (_selectedOrderId != null) ...[
                        const SizedBox(height: 16),
                        Text(l10n.driverAddItems, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ModernCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _typeController,
                                      decoration: InputDecoration(hintText: l10n.driverItemType),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                      initialValue: '1',
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(hintText: l10n.driverQuantity),
                                      onChanged: (v) => _quantity = int.tryParse(v) ?? 1,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primary),
                                    onPressed: _addToBasket,
                                  ),
                                ],
                              ),
                              if (_basket.isNotEmpty)
                                Column(
                                  children: _basket
                                      .map((item) => ListTile(
                                            dense: true,
                                            title: Text('${item['quantity']}x ${item['itemType']}'),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.close_rounded, size: 18),
                                              onPressed: () => setState(() => _basket.remove(item)),
                                            ),
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: l10n.driverSaveAndCollect,
                          isLoading: _saving,
                          onPressed: _basket.isEmpty ? null : _saveAndCollect,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHandover(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 64, color: AppTheme.success),
            const SizedBox(height: 16),
            Text(l10n.driverAllCollected(_orders.length), style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('${widget.trip['cleanerName'] ?? ''}', style: const TextStyle(color: AppTheme.neutral500)),
            const SizedBox(height: 24),
            SecondaryButton(
              text: l10n.driverNavigateToCleaner,
              icon: Icons.directions_rounded,
              onPressed: () => _openMaps(
                (widget.trip['cleanerLat'] as num?)?.toDouble(),
                (widget.trip['cleanerLng'] as num?)?.toDouble(),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: l10n.driverHandOverToCleaner,
              icon: Icons.done_all_rounded,
              isLoading: _handingOver,
              onPressed: _handOver,
            ),
          ],
        ),
      ),
    );
  }
}
