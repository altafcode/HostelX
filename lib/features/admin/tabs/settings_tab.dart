import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';
import '../../../data/services/notification_service.dart';
import '../../profile/edit_profile_screen.dart';
import '../providers/admin_provider.dart';
import '../screens/admin_pending_listings_screen.dart';
import '../screens/admin_complaints_screen.dart';
import '../screens/admin_booking_history_screen.dart';
import '../screens/admin_payment_logs_screen.dart';
import '../widgets/admin_setting_tiles.dart';

class AdminSettingsTab extends StatelessWidget {
  final Function(String)? onNavigateToUsers;
  const AdminSettingsTab({super.key, this.onNavigateToUsers});

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final adminUser = context.watch<AuthProvider>().user;
    final pendingCount = adminProv.hostels.where((h) => h.approvalStatus == ApprovalStatus.pending).length;
    final complaintsCount = adminProv.complaints.where((c) => c.status == 'Open').length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          
          // Admin Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _initial(adminUser?.name ?? 'A'),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(adminUser?.name ?? 'Admin', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(adminUser?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('PLATFORM SETTINGS'),
          AdminSettingTile(
            icon: Icons.percent_rounded,
            iconColor: AppColors.primary,
            title: 'Platform Fee',
            subtitle: 'Current: ${(adminProv.commissionRate * 100).toInt()}% per booking',
            onTap: () => _showEditCommissionDialog(context, adminProv),
          ),
          const SizedBox(height: 10),
          AdminSettingTile(
            icon: Icons.campaign_rounded,
            iconColor: Colors.orange,
            title: 'Platform Announcement',
            subtitle: 'Send notification to all users',
            onTap: () => _showAnnouncementDialog(context),
          ),
          const SizedBox(height: 10),
          AdminToggleTile(
            icon: Icons.add_business_rounded,
            iconColor: AppColors.accent,
            title: 'Allow New Listings',
            subtitle: 'Owners can submit new hostels',
            value: adminProv.allowNewListings,
            onChanged: (value) => adminProv.updatePlatformSetting(
              'allowNewListings',
              value,
            ),
          ),
          const SizedBox(height: 10),
          AdminToggleTile(
            icon: Icons.build_circle_outlined,
            iconColor: AppColors.red,
            title: 'Maintenance Mode',
            subtitle: 'Disable app for all users',
            value: adminProv.maintenanceMode,
            onChanged: (value) => adminProv.updatePlatformSetting(
              'maintenanceMode',
              value,
            ),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('MODERATION'),
          AdminSettingTile(
            icon: Icons.pending_actions_rounded,
            iconColor: AppColors.accent,
            title: 'Pending Listings',
            subtitle: 'Review new hostel submissions',
            badge: pendingCount > 0 ? pendingCount.toString() : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPendingListingsScreen())),
          ),
          const SizedBox(height: 10),
          AdminSettingTile(
            icon: Icons.report_problem_rounded,
            iconColor: AppColors.red,
            title: 'Open Complaints',
            subtitle: 'Resolve tenant or owner issues',
            badge: complaintsCount > 0 ? complaintsCount.toString() : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminComplaintsScreen())),
          ),
          const SizedBox(height: 10),
          AdminSettingTile(
            icon: Icons.person_off_rounded,
            iconColor: AppColors.textMuted,
            title: 'Disabled Users',
            subtitle: 'Manage restricted accounts',
            onTap: () {
              onNavigateToUsers?.call('Disabled');
            },
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('DATA & REPORTS'),
          AdminSettingTile(
            icon: Icons.history_rounded,
            iconColor: AppColors.primary,
            title: 'View Booking History',
            subtitle: 'Logs of all past and active bookings',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBookingHistoryScreen())),
          ),
          const SizedBox(height: 10),
          AdminSettingTile(
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.emerald,
            title: 'View Payment Logs',
            subtitle: 'Track all platform transactions',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPaymentLogsScreen())),
          ),
          const SizedBox(height: 10),
          AdminSettingTile(
            icon: Icons.file_download_rounded,
            iconColor: Colors.blue,
            title: 'Monthly Report',
            subtitle: 'View this month earnings summary',
            onTap: () => _showMonthlyReportDialog(context, adminProv),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('ACCOUNT'),
          AdminSettingTile(
            icon: Icons.lock_outline_rounded,
            iconColor: Colors.grey,
            title: 'Change Password',
            subtitle: 'Update your security credentials',
            onTap: () => _showChangePasswordDialog(context),
          ),
          const SizedBox(height: 10),
          _buildStaticTile(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.grey,
            title: 'App Version',
            value: '1.0.0',
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showLogoutConfirm(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.red),
              label: const Text('Logout Account', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted.withValues(alpha: 0.7), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildStaticTile({required IconData icon, required Color iconColor, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary))),
        Text(value, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'A' : trimmed[0].toUpperCase();
  }

  void _showEditCommissionDialog(BuildContext context, AdminProvider adminProv) {
    final controller = TextEditingController(text: (adminProv.commissionRate * 100).toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Platform Fee'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '%', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final rate = double.tryParse(controller.text);
              if (rate != null) adminProv.updateCommissionRate(rate / 100);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Platform Announcement'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
              hintText: 'Type your message here...',
              border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final message = controller.text.trim();
              if (message.isEmpty) return;
              await NotificationService().sendNotificationToAllUsers(
                title: 'Platform Announcement',
                body: message,
                type: 'system',
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Announcement sent to all users')));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField('Current Password', controller: currentCtrl),
            const SizedBox(height: 12),
            _buildPasswordField('New Password', controller: newCtrl),
            const SizedBox(height: 12),
            _buildPasswordField('Confirm New Password', controller: confirmCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text || newCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords must match and be 6+ chars.')));
                return;
              }
              try {
                await context.read<AuthProvider>().changePassword(
                      currentPassword: currentCtrl.text,
                      newPassword: newCtrl.text,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password update failed: $e')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String hint, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
    );
  }

  void _showMonthlyReportDialog(BuildContext context, AdminProvider adminProv) {
    final now = DateTime.now();
    final currentMonthBookings = adminProv.bookings.where((booking) {
      final date = booking.paymentDate;
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();
    final revenue = currentMonthBookings.fold<double>(
      0,
      (sum, booking) => sum + booking.price,
    );
    final commission = adminProv.calculateCommission(revenue);
    final activeUsers =
        adminProv.users.where((user) => user.status.name == 'active').length;
    final activeHostels = adminProv.hostels
        .where((hostel) => hostel.approvalStatus == ApprovalStatus.approved)
        .length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Month: ${now.month}/${now.year}'),
            const SizedBox(height: 8),
            Text('Bookings paid: ${currentMonthBookings.length}'),
            Text('Active users: $activeUsers'),
            Text('Active hostels: $activeHostels'),
            Text('Gross revenue: Rs ${revenue.toStringAsFixed(0)}'),
            Text('Commission: Rs ${commission.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out from the admin panel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.splash, (_) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
