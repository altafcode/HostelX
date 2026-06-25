import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/common/primary_button.dart';
import '../../profile/edit_profile_screen.dart';
import '../widgets/profile_stat_card.dart';
import '../providers/booking_provider.dart';
import '../providers/hostel_provider.dart';
import '../../../domain/entities/booking_entity.dart';
import 'complaint_screen.dart';
import 'payment_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final navProv = context.read<NavigationProvider>();
    final bookingProv = context.watch<BookingProvider>();
    final hostelProv = context.watch<HostelProvider>();

    final List<BookingEntity> userBookings =
        user != null ? bookingProv.bookingsForUser(user.id) : <BookingEntity>[];
    final activeBookingsCount = userBookings.where((b) => b.status.isActive).length;
    final paidBookingsCount = userBookings.where((b) => b.status.isPaid).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _ProfileAvatar(
              userName: user?.name ?? 'U',
              imageUrl: user?.avatar,
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            if (user?.occupation != null) ...[
              const SizedBox(height: 2),
              Text(user!.occupation!.name.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 8),
            const _VerifiedBadge(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ProfileStatCard(
                    label: AppStrings.activeBooking,
                    value: activeBookingsCount.toString(),
                    onTap: () => navProv.setIndex(2), // Bookings tab
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ProfileStatCard(
                    label: AppStrings.savedHostels,
                    value: hostelProv.favoriteHostels.length.toString(),
                    onTap: () => navProv.setIndex(1), // Saved tab
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ProfileStatCard(
                    label: AppStrings.paymentHistory,
                    value: paidBookingsCount.toString(),
                    onTap: () => _openPaymentHistory(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Section: My Activity (Higher priority)
            const _SectionLabel(label: AppStrings.myActivity),
            const SizedBox(height: 8),
            _ProfileLink(
              icon: Icons.bookmark_outline_rounded,
              label: AppStrings.myBookings,
              onTap: () => navProv.setIndex(2),
            ),
            const SizedBox(height: 8),
            _ProfileLink(
              icon: Icons.notifications_outlined,
              label: AppStrings.notifications,
              onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
            ),
            const SizedBox(height: 8),
            _ProfileLink(
              icon: Icons.payment_outlined,
              label: AppStrings.paymentHistory,
              onTap: () => _openPaymentHistory(context),
            ),
            const SizedBox(height: 24),

            // Section: Account Settings
            const _SectionLabel(label: AppStrings.accountSettings),
            const SizedBox(height: 8),
            _ProfileLink(
              icon: Icons.person_outline_rounded,
              label: AppStrings.editProfile,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _ProfileLink(
              icon: Icons.lock_outline_rounded,
              label: AppStrings.changePassword,
              onTap: () => _showChangePasswordDialog(context),
            ),
            const SizedBox(height: 24),

            // Section: App Service / Support (Lowered)
            const _SectionLabel(label: AppStrings.support),
            const SizedBox(height: 8),
            _ProfileLink(
              icon: Icons.report_outlined,
              label: AppStrings.submitComplaint,
              onTap: () => _openComplaint(context, userBookings, hostelProv),
            ),
            const SizedBox(height: 8),
            _ProfileLink(
              icon: Icons.help_outline_rounded,
              label: AppStrings.helpCenter,
              onTap: () => _showInfoDialog(
                context,
                'Help Center',
                'For hostel booking, payment, or complaint support, contact HostelX support through your university/final year project coordinator or use the complaint option for hostel-specific issues.',
              ),
            ),
            const SizedBox(height: 8),
            _ProfileLink(
              icon: Icons.article_outlined,
              label: AppStrings.termsConditions,
              onTap: () => _showInfoDialog(
                context,
                'Terms & Conditions',
                'Bookings remain pending until owner approval. Payments are processed only after approval. Hostel owners are responsible for listing accuracy and tenant support.',
              ),
            ),
            
            const SizedBox(height: 24),
            PrimaryButton(
              label: AppStrings.logout,
              variant: ButtonVariant.danger,
              fullWidth: true,
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRouter.splash, (_) => false);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(AppStrings.appVersion,
                style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  void _openPaymentHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
    );
  }

  void _openComplaint(
    BuildContext context,
    List<BookingEntity> bookings,
    HostelProvider hostelProvider,
  ) {
    final active = bookings.where((b) => b.status.isActive).toList();
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need an active booking to complain.')),
      );
      return;
    }

    final hostel = hostelProvider.hostelById(active.first.hostelId);
    if (hostel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hostel details are not available.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComplaintScreen(hostel: hostel)),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
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
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text || newCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Passwords must match and be 6+ chars.')),
                );
                return;
              }
              await context.read<AuthProvider>().changePassword(
                    currentPassword: currentCtrl.text,
                    newPassword: newCtrl.text,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated.')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String userName;
  final String? imageUrl;
  const _ProfileAvatar({required this.userName, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  AppHelpers.getInitials(userName),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.emerald,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20)),
      child: const Text(
        AppStrings.verifiedTenant,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.primary),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted.withValues(alpha: 0.7),
            letterSpacing: 1.2),
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary, size: 20),
        title: Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary),
        ),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}
