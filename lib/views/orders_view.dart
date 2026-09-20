import 'package:flutter/material.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/widgets/custom_toast.dart';
import 'package:ghasele/widgets/reschedule_sheet.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => OrdersViewState();
}

class OrdersViewState extends State<OrdersView> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    fetchOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    // Trigger the next page a bit before hitting the physical bottom.
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _loadMoreOrders();
    }
  }

  /// Loads one page of orders for whoever is using the app.
  ///
  /// A guest has no account to look orders up by, so their orders are fetched by the
  /// device token instead - the same value that was stamped on them at checkout.
  Future<Map<String, dynamic>> _fetchPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');

    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      return ApiService.getGuestOrders(page: page, pageSize: _pageSize);
    }

    return ApiService.getUserOrders(
      userId: userId,
      token: token,
      page: page,
      pageSize: _pageSize,
    );
  }

  Future<void> fetchOrders() async {
    try {
      final result = await _fetchPage(1);
      if (mounted) {
        if (result['success']) {
          final data = result['data'] as List<dynamic>;
          setState(() {
            _orders = data;
            // Sort by createdAt descending
            _orders.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
            _page = 1;
            _hasMore = data.length == _pageSize;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await _fetchPage(nextPage);
      if (mounted) {
        if (result['success']) {
          final data = result['data'] as List<dynamic>;
          setState(() {
            _orders.addAll(data);
            _orders.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
            _page = nextPage;
            _hasMore = data.length == _pageSize;
            _isLoadingMore = false;
          });
        } else {
          setState(() => _isLoadingMore = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  String _getStatusTranslation(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'pendingcollection':
      case 'pending':
        return l10n.statusPendingCollection;
      case 'assigned':
        return l10n.statusAssigned;
      case 'collected':
        return l10n.statusCollected;
      case 'cleaning':
      case 'inprogress':
        return l10n.statusCleaning;
      case 'ready':
      case 'completed':
        return l10n.statusReady;
      case 'outfordelivery':
        return l10n.statusOutForDelivery;
      case 'delivered':
        return l10n.statusDelivered;
      case 'cancelled':
        return l10n.statusCancelled;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendingcollection':
      case 'pending':
        return AppTheme.info;
      case 'assigned':
        return AppTheme.primary;
      case 'collected':
        return AppTheme.primary;
      case 'cleaning':
      case 'inprogress':
        return AppTheme.warning;
      case 'ready':
      case 'completed':
        return AppTheme.success;
      case 'outfordelivery':
        return AppTheme.primary;
      case 'delivered':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.neutral500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      );
    }

    if (_orders.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return RefreshIndicator(
      onRefresh: fetchOrders,
      color: AppTheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: _orders.length + 1 + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.orderHistory,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.neutral900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_orders.length} ${l10n.orders}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            );
          }
          if (index == _orders.length + 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ),
            );
          }
          final order = _orders[index - 1];
          final status = order['status'] as String;
          final refNum = order['referenceNumber'] ?? '#${order['id'].toString().substring(0, 8)}';
          
          return _buildOrderCard(
            context: context,
            order: order,
            orderId: refNum,
            date: _formatDate(order['createdAt']),
            status: _getStatusTranslation(context, status),
            statusColor: _getStatusColor(status),
            total: '${order['totalAmount']} ${l10n.jod}',
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              size: 64,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.orderHistory,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No orders found yet', // Should be localized if possible
            style: TextStyle(color: AppTheme.neutral500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Opens the phone dialer on the driver's number.
  ///
  /// Deliberately `tel:` and not a direct dial: placing the call outright would need the
  /// CALL_PHONE permission, and a misplaced tap would then ring the driver with nothing
  /// the customer could do about it. The dialer opens pre-filled and the customer presses
  /// the green button, which is also what every other app on the phone does.
  ///
  /// The number is stored as typed, so it arrives in any of the spellings
  /// [jordanPhoneToE164] accepts ("0791234567", "+962 79 123 4567"). Everything but the
  /// digits and a leading "+" is stripped, because spaces and dashes in a `tel:` URI are
  /// escaped rather than ignored and the dialer then opens on a number that will not ring.
  Future<void> _callDriver(BuildContext context, String rawNumber) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final trimmed = rawNumber.trim();
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final dialable = trimmed.startsWith('+') ? '+$digits' : digits;

    // Failure is reported rather than swallowed: on a device with no dialer (a tablet, or
    // an emulator) the tap would otherwise do nothing at all and read as a broken button.
    try {
      final launched = await launchUrl(
        Uri(scheme: 'tel', path: dialable),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.callDriverFailed)));
      }
    } catch (e) {
      debugPrint('Could not open the dialer for $dialable: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.callDriverFailed)));
    }
  }

  /// Whether the customer may still cancel this order or move its collection time.
  ///
  /// PendingCollection is the whole rule: an order joins a trip by moving to Assigned, so
  /// anything further along is already on a driver's list. The server enforces this again
  /// - and can see whether the trip has actually set off, which the app cannot - so this
  /// only decides whether the buttons are worth offering.
  bool _isChangeable(Map<String, dynamic> order) =>
      (order['status'] as String?)?.toLowerCase() == 'pendingcollection';

  /// The signed-in customer's token, or null when the app is being used as a guest.
  ///
  /// A guest is not turned away: their order is identified by the device token
  /// [ApiService] sends on every request, which is what it was placed with.
  Future<String?> _authToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return (token == null || token.isEmpty) ? null : token;
  }

  /// Opens the schedule so the customer can move this order to another collection slot.
  Future<void> _changeCollectionTime(Map<String, dynamic> order) async {
    final token = await _authToken();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final rawDate = order['scheduledDate'] as String?;

    final updated = await showRescheduleSheet(
      context,
      orderId: order['id'] as String,
      token: token,
      currentWindowId: order['deliveryWindowId'] as String?,
      // The slot list keys dates as "yyyy-MM-dd"; the order carries the same date, but
      // a server that serialises it with a time component would not compare equal.
      currentDateKey: rawDate == null || rawDate.length < 10
          ? null
          : rawDate.substring(0, 10),
    );

    // Null means they closed the sheet without choosing - nothing changed, so nothing to
    // say and nothing to reload.
    if (!mounted || updated == null) return;

    CustomToast.show(
      context,
      message: l10n.collectionTimeUpdated,
      type: ToastType.success,
    );
    fetchOrders();
  }

  /// Confirms, then cancels the order.
  ///
  /// Confirmed first because it cannot be undone: the order is closed and its collection
  /// slot goes back to the schedule, where someone else can take it.
  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.cancelOrderTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          l10n.cancelOrderMessage,
          style: TextStyle(color: AppTheme.neutral600, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              l10n.keepOrder,
              style: const TextStyle(
                color: AppTheme.neutral700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.cancelOrder,
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final token = await _authToken();
    final result = await ApiService.cancelOrder(
      orderId: order['id'] as String,
      token: token,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      CustomToast.show(
        context,
        message: l10n.orderCancelled,
        type: ToastType.success,
      );
      fetchOrders();
      return;
    }

    // The server's own message says why - the order may have been picked up while this
    // screen sat open - and it is already in the customer's language.
    CustomToast.show(
      context,
      message: (result['message'] as String?) ?? l10n.orderChangeFailed,
      type: ToastType.error,
    );
    // Whatever the reason, this screen is showing a stale order. Reload so the buttons
    // match what the order actually is now.
    fetchOrders();
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    final l10n = AppLocalizations.of(context)!;
    final items = order['items'] as List<dynamic>? ?? [];
    final status = order['status'] as String;
    final appointment = _formatAppointment(context, order);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['referenceNumber'] ?? l10n.orderHistory,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neutral900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusTranslation(context, status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (appointment != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.collectionTime}: $appointment',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neutral800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            Text(
              l10n.items,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text('No items added yet', style: TextStyle(color: AppTheme.neutral500)),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['itemType'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutral800,
                        ),
                      ),
                      if (item['serviceType'] != null)
                        Text(
                          item['serviceType'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutral500,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'x${item['quantity']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            )),
            if (order['driverName'] != null) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  const Icon(Icons.delivery_dining_outlined, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.driverName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutral900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.person, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['driverName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neutral900,
                            ),
                          ),
                          if (order['driverPhoneNumber'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              order['driverPhoneNumber'],
                              style: TextStyle(
                                color: AppTheme.neutral600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (order['driverPhoneNumber'] != null)
                      IconButton(
                        icon: const Icon(Icons.phone_forwarded_outlined, color: AppTheme.primary),
                        tooltip: l10n.callDriver,
                        onPressed: () => _callDriver(
                          context,
                          order['driverPhoneNumber'].toString(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const Divider(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.deliveryFee,
                  style: TextStyle(
                    color: AppTheme.neutral600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${order['deliveryAmount']} ${l10n.jod}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutral900,
                  ),
                ),
              ],
            ),
            if (order['marketingDiscount'] != null && order['marketingDiscount'] > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Discount",
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '-${order['marketingDiscount']} ${l10n.jod}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.total,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neutral900,
                  ),
                ),
                Text(
                  '${order['totalAmount']} ${l10n.jod}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Only while the order is still the customer's to change. Both actions close
            // this sheet first: each one opens something of its own, and the details
            // behind it would be stale the moment either succeeds.
            if (_isChangeable(order)) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _changeCollectionTime(order);
                  },
                  icon: const Icon(Icons.event_repeat_rounded, size: 18),
                  label: Text(
                    l10n.changeCollectionTime,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _cancelOrder(order);
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(
                    l10n.cancelOrder,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.close,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The booked collection appointment, e.g. "غداً - 1:00 م - 2:00 م".
  ///
  /// Read from the order's own stored schedule, never recomputed from the window: an
  /// order booked for tomorrow must keep reading as tomorrow, and the stored date is
  /// the only value that stays true as the days roll over.
  ///
  /// Null for orders placed before scheduling existed, which have no appointment to show.
  String? _formatAppointment(BuildContext context, Map<String, dynamic> order) {
    final rawDate = order['scheduledDate'] as String?;
    if (rawDate == null) return null;

    final date = DateTime.tryParse(rawDate);
    if (date == null) return null;

    final l10n = AppLocalizations.of(context)!;
    final tag = Localizations.localeOf(context).toLanguageTag();

    final today = DateUtils.dateOnly(DateTime.now());
    final days = DateUtils.dateOnly(date).difference(today).inDays;
    final dayLabel = days == 0
        ? l10n.today
        : days == 1
            ? l10n.tomorrow
            : DateFormat.yMMMEd(tag).format(date);

    final start = order['scheduledStart'] as String?;
    final end = order['scheduledEnd'] as String?;
    if (start == null || end == null) return dayLabel;

    final time = DateFormat.jm(tag);
    return '$dayLabel - ${time.format(_at(date, start))} - ${time.format(_at(date, end))}';
  }

  /// Puts an "HH:mm" from the server onto [date] so only the time needs formatting.
  DateTime _at(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required Map<String, dynamic> order,
    required String orderId,
    required String date,
    required String status,
    required Color statusColor,
    required String total,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final appointment = _formatAppointment(context, order);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showOrderDetails(context, order),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.neutral900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: TextStyle(
                              color: AppTheme.neutral500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (appointment != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.event_outlined, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n.collectionTime}: $appointment',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.neutral800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((order['driverName'] ?? order['DriverName']) != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining_outlined, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['driverName'] ?? order['DriverName'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.neutral800,
                                ),
                              ),
                              if ((order['driverPhoneNumber'] ?? order['DriverPhoneNumber']) != null)
                                Text(
                                  order['driverPhoneNumber'] ?? order['DriverPhoneNumber'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.neutral500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 18, color: AppTheme.neutral400),
                          const SizedBox(width: 8),
                          Text(
                            l10n.total,
                            style: TextStyle(
                              color: AppTheme.neutral600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        total,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
