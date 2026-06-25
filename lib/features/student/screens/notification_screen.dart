import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/notification_service.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/notification_card.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final IconData icon;
  final Color iconBgColor;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.icon,
    required this.iconBgColor,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSub;
  String? _listeningUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startListening();
  }

  @override
  void dispose() {
    _notificationsSub?.cancel();
    super.dispose();
  }

  void _startListening() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == _listeningUserId) return;

    _notificationsSub?.cancel();
    _listeningUserId = userId;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    _notificationsSub =
        _notificationService.watchNotifications(userId).listen((data) {
      if (!mounted) return;
      setState(() {
        _notifications = data.map(_toNotificationItem).toList();
        _isLoading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  NotificationItem _toNotificationItem(Map<String, dynamic> n) {
    IconData icon;
    Color color;
    switch (n['type']) {
      case 'booking':
        icon = Icons.check_circle_rounded;
        color = AppColors.emerald;
        break;
      case 'complaint':
        icon = Icons.report_problem_rounded;
        color = AppColors.red;
        break;
      case 'payment':
      case 'payout':
        icon = Icons.account_balance_wallet_rounded;
        color = AppColors.emerald;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppColors.primary;
    }

    return NotificationItem(
      id: n['id'],
      title: n['title'] ?? 'Notification',
      message: n['body'] ?? '',
      time: _formatTime(n['createdAt'], n['createdAtIso']),
      isRead: n['isRead'] ?? false,
      icon: icon,
      iconBgColor: color,
    );
  }

  String _formatTime(dynamic createdAt, [dynamic fallback]) {
    final date = NotificationService.parseCreatedAt(createdAt) ??
        NotificationService.parseCreatedAt(fallback);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void _clearAllNotifications() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

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

    if (confirmed != true) return;

    await _notificationService.clearAllNotifications(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All notifications cleared'),
            duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _notifications.isEmpty ? null : _clearAllNotifications,
            child: const Text('Clear All',
                style: TextStyle(
                    color: AppColors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return NotificationCard(
                      notification: item,
                      onTap: () async {
                        await _notificationService.markAsRead(item.id);
                        setState(() {
                          _notifications[index] = NotificationItem(
                            id: item.id,
                            title: item.title,
                            message: item.message,
                            time: item.time,
                            isRead: true,
                            icon: item.icon,
                            iconBgColor: item.iconBgColor,
                          );
                        });
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 20),
          const Text('No notifications yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('We\'ll notify you when something important happens.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
