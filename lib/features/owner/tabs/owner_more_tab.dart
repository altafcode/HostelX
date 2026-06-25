import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../profile/edit_profile_screen.dart';
import '../../student/providers/booking_provider.dart';
import '../../student/providers/hostel_provider.dart';
import '../../student/screens/notification_screen.dart';
import '../../../domain/entities/booking_entity.dart';
import '../providers/owner_provider.dart';
import '../screens/owner_complaints_screen.dart';
import '../screens/owner_reviews_screen.dart';
import '../screens/owner_booking_requests_screen.dart';

class OwnerMoreTab extends StatelessWidget {
  final Function(int)? onTabChange;
  const OwnerMoreTab({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<OwnerProvider>();
    final openComplaints = provider.complaints.where((c) => c.status == 'Open').length;

    // Dynamic booking requests count
    final hostels = context
        .watch<HostelProvider>()
        .allHostels
        .where((h) => h.ownerName == user?.name || h.ownerId == user?.id)
        .map((h) => h.id)
        .toList();
    final bookings =
        context.watch<BookingProvider>().bookingsForOwnerHostels(hostels);
    final pendingRequests = bookings.where((b) => b.status == BookingStatus.pending).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'More',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            
            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        user?.avatar == null || user!.avatar!.isEmpty
                            ? null
                            : NetworkImage(user.avatar!),
                    child: user?.avatar == null || user!.avatar!.isEmpty
                        ? Text(
                            AppHelpers.getInitials(user?.name ?? 'U'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                        const Text(
                          'Hostel Owner',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Management Section
            const Text('Management', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
              },
            ),
            _buildMenuTile(
              icon: Icons.list_alt_outlined,
              title: 'Booking Requests',
              badge: pendingRequests > 0 ? pendingRequests.toString() : null,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerBookingRequestsScreen()));
              },
            ),
            _buildMenuTile(
              icon: Icons.report_problem_outlined,
              title: 'Complaints',
              badge: openComplaints > 0 ? openComplaints.toString() : null,
              badgeColor: AppColors.red,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerComplaintsScreen()));
              },
            ),
            _buildMenuTile(
              icon: Icons.star_outline,
              title: 'Reviews & Ratings',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerReviewsScreen()));
              },
            ),
            const SizedBox(height: 24),

            // Listings Section
            const Text('Listings', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.apartment_outlined,
              title: 'My Listings',
              onTap: () => onTabChange?.call(1),
            ),
            const SizedBox(height: 24),

            // Finance Section
            const Text('Finance', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Earnings Summary',
              onTap: () => onTabChange?.call(3),
            ),
            _buildMenuTile(
              icon: Icons.account_balance_outlined,
              title: 'Bank Details',
              onTap: () => _showBankDetailsDialog(context),
            ),
            const SizedBox(height: 24),

            // Account Section
            const Text('Account', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () => _showChangePasswordDialog(context),
            ),
            _buildMenuTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => _showHelpDialog(context),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  try {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true)
                          .pushNamedAndRemoveUntil(
                        AppRouter.splash,
                        (_) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout, color: AppColors.red),
                label: const Text('Logout',
                    style: TextStyle(color: AppColors.red, fontSize: 16)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
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
            _buildPasswordField('Current Password',
                controller: currentCtrl),
            const SizedBox(height: 12),
            _buildPasswordField('New Password', controller: newCtrl),
            const SizedBox(height: 12),
            _buildPasswordField('Confirm New Password',
                controller: confirmCtrl),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text ||
                  newCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Passwords must match and be 6+ chars.')));
                return;
              }
              await context.read<AuthProvider>().changePassword(
                    currentPassword: currentCtrl.text,
                    newPassword: newCtrl.text,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For booking requests, payout questions, or tenant issues, use the Booking Requests, Complaints, and Bank Details sections. For urgent support, contact the HostelX admin from your project team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBankDetailsDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    final bankNameCtrl = TextEditingController(
      text: (user?.bankDetails?['bankName'] ?? '').toString(),
    );
    final accountTitleCtrl = TextEditingController(
      text: (user?.bankDetails?['accountTitle'] ?? '').toString(),
    );
    final ibanCtrl = TextEditingController(
      text: (user?.bankDetails?['iban'] ?? '').toString(),
    );
    final stripeAccountCtrl = TextEditingController(
      text: (user?.bankDetails?['stripeAccountId'] ?? '').toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bank Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your bank details to receive payments from Admin.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildTextField('Bank Name (e.g., HBL, Meezan)', controller: bankNameCtrl),
            const SizedBox(height: 12),
            _buildTextField('Account Title', controller: accountTitleCtrl),
            const SizedBox(height: 12),
            _buildTextField('IBAN (PK...)', controller: ibanCtrl),
            const SizedBox(height: 12),
            _buildTextField('Stripe Account ID (acct_...)', controller: stripeAccountCtrl),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.updateProfile({
                'bankDetails': {
                  'bankName': bankNameCtrl.text.trim(),
                  'accountTitle': accountTitleCtrl.text.trim(),
                  'iban': ibanCtrl.text.trim(),
                  'stripeAccountId': stripeAccountCtrl.text.trim(),
                }
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bank details saved successfully.')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {bool obscureText = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
    );
  }

  Widget _buildPasswordField(String hint, {TextEditingController? controller}) {
    return _buildTextField(hint, obscureText: true, controller: controller);
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? badge,
    Color badgeColor = AppColors.primary,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          if (trailing != null) trailing,
          if (badge == null && trailing == null)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }
}
