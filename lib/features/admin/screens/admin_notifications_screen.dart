import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/notification_service.dart';
import '../../../providers/auth_provider.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  String _selectedFilter = 'All';

  void _clearAll(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.clearAllNotifications(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: userId == null ? null : () => _clearAll(userId),
            child: const Text('Clear All',
                style: TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('No admin session found.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _notificationService.watchNotifications(userId),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? const [];
                final filtered = notifications.where((n) {
                  if (_selectedFilter == 'Unread') {
                    return n['isRead'] == false;
                  }
                  return true;
                }).toList();

                return Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedFilter == 'All',
                            onSelected: (_) =>
                                setState(() => _selectedFilter = 'All'),
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.1),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Unread'),
                            selected: _selectedFilter == 'Unread',
                            onSelected: (_) =>
                                setState(() => _selectedFilter = 'Unread'),
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('No notifications.',
                                  style:
                                      TextStyle(color: AppColors.textMuted)))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final n = filtered[index];
                                final isRead = n['isRead'] == true;
                                return _AdminNotificationTile(
                                  data: n,
                                  isRead: isRead,
                                  onTap: () {
                                    if (!isRead) {
                                      _notificationService
                                          .markAsRead(n['id'].toString());
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _AdminNotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isRead;
  final VoidCallback onTap;

  const _AdminNotificationTile({
    required this.data,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = data['type']?.toString() ?? 'system';
    final icon = switch (type) {
      'hostel' => Icons.apartment,
      'complaint' => Icons.report_problem,
      'booking' => Icons.check_circle,
      'payout' => Icons.attach_money,
      _ => Icons.notifications,
    };

    return Container(
      color:
          isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isRead
              ? AppColors.surfaceVariant
              : AppColors.primary.withValues(alpha: 0.2),
          child: Icon(icon,
              color: isRead ? AppColors.textSecondary : AppColors.primary),
        ),
        title: Text(
          data['title']?.toString() ?? 'Notification',
          style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        subtitle: Text(data['body']?.toString() ?? '',
            style: const TextStyle(color: AppColors.textSecondary)),
        trailing: isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
        onTap: onTap,
      ),
    );
  }
}
