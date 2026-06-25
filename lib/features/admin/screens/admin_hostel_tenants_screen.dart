import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../domain/entities/booking_entity.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_details_sheet.dart';

class AdminHostelTenantsScreen extends StatelessWidget {
  final HostelEntity hostel;

  const AdminHostelTenantsScreen({super.key, required this.hostel});

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final tenants = adminProv.bookings
        .where((b) => b.hostelId == hostel.id)
        .map((b) => (
              user: adminProv.users.firstWhere((u) => u.id == b.userId),
              booking: b
            ))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hostel Tenants',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(hostel.name,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: tenants.isEmpty
          ? const Center(
              child: Text('No tenants found for this hostel.',
                  style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                final item = tenants[index];
                final u = item.user;
                final b = item.booking;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => showAdminUserBottomSheet(
                      context: context,
                      user: u,
                      adminProv: adminProv,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.surfaceVariant,
                            child: Text(u.name[0],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Room ${b.roomNumber} (${b.roomType}) • ${u.email}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: b.status == BookingStatus.expired
                                  ? AppColors.red.withValues(alpha: 0.1)
                                  : AppColors.emerald.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              b.status == BookingStatus.expired ? 'Overdue' : 'Active',
                              style: TextStyle(
                                color: b.status == BookingStatus.expired
                                    ? AppColors.red
                                    : AppColors.emerald,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
