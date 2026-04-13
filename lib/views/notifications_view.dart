import 'package:flutter/material.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      timestamp: DateTime.parse(json['createdAt']),
      isRead: json['isRead'],
    );
  }
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final result = await ApiService.getNotifications(token);
        if (result['success']) {
          setState(() {
            _notifications = (result['data'] as List)
                .map((n) => NotificationModel.fromJson(n))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final result = await ApiService.markAllAsRead(token);
        if (result['success']) {
          setState(() {
            for (var n in _notifications) {
              n.isRead = true;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _markSingleRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final result = await ApiService.markAsRead(notification.id, token);
        if (result['success']) {
          setState(() {
            notification.isRead = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final result = await ApiService.deleteNotification(id, token);
        if (result['success']) {
          setState(() {
            _notifications.removeWhere((n) => n.id == id);
          });
        }
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(isAr ? 'الإشعارات' : 'Notifications'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                isAr ? 'تحديد الكل كمقروء' : 'Mark all read',
                style: const TextStyle(color: AppTheme.primaryBlue),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? _buildEmptyState(isAr)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red.shade100,
                          child: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                        onDismissed: (_) => _deleteNotification(notification.id),
                        child: _buildNotificationCard(notification, isAr),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: AppTheme.neutral300,
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? 'لا توجد إشعارات' : 'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'سنخطرك عند وجود تحديثات على طلباتك' : 'We will notify you of updates',
            style: TextStyle(
              color: AppTheme.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, bool isAr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead ? Colors.transparent : AppTheme.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: notification.isRead ? Colors.white : AppTheme.primaryBlue.withOpacity(0.02),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (notification.isRead ? AppTheme.neutral100 : AppTheme.primaryBlue.withOpacity(0.1)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification.title.contains('استلام') || notification.title.contains('Collect')
                ? Icons.local_shipping_outlined
                : Icons.inventory_2_outlined,
            color: notification.isRead ? AppTheme.neutral500 : AppTheme.primaryBlue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(
                color: AppTheme.neutral600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat.jm(isAr ? 'ar' : 'en').format(notification.timestamp.toLocal()),
              style: TextStyle(
                color: AppTheme.neutral400,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => _markSingleRead(notification),
      ),
    );
  }
}
