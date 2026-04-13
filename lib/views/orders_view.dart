import 'package:flutter/material.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => OrdersViewState();
}

class OrdersViewState extends State<OrdersView> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) return;

      final result = await ApiService.getUserOrders(userId: userId, token: token);
      if (mounted) {
        if (result['success']) {
          setState(() {
            _orders = result['data'];
            // Sort by createdAt descending
            _orders.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
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
        return AppTheme.primaryBlue;
      case 'collected':
        return AppTheme.primaryBlue;
      case 'cleaning':
      case 'inprogress':
        return AppTheme.warning;
      case 'ready':
      case 'completed':
        return AppTheme.success;
      case 'outfordelivery':
        return AppTheme.primaryBlue;
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
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        ),
      );
    }

    if (_orders.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return RefreshIndicator(
      onRefresh: fetchOrders,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: _orders.length + 1,
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
              color: AppTheme.primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              size: 64,
              color: AppTheme.primaryBlue,
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

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    final l10n = AppLocalizations.of(context)!;
    final items = order['items'] as List<dynamic>? ?? [];
    final status = order['status'] as String;
    
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
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            )).toList(),
            if (order['driverName'] != null) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  const Icon(Icons.delivery_dining_outlined, size: 20, color: AppTheme.primaryBlue),
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
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      child: const Icon(Icons.person, color: AppTheme.primaryBlue),
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
                        icon: const Icon(Icons.phone_forwarded_outlined, color: AppTheme.primaryBlue),
                        onPressed: () {
                          // Note: url_launcher would be needed here for real calls
                        },
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
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
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
                  if ((order['driverName'] ?? order['DriverName']) != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining_outlined, size: 16, color: AppTheme.primaryBlue),
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
                          color: AppTheme.primaryBlue,
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
