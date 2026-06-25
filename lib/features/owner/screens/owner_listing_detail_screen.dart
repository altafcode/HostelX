import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../providers/owner_provider.dart';
import '../../../widgets/common/status_badge.dart';
import 'add_listing_screen.dart';
import 'owner_all_rooms_screen.dart';
import 'owner_reviews_screen.dart';
import '../widgets/tenant_details_sheet.dart';
import '../tabs/owner_tenants_tab.dart';
import '../utils/room_inventory.dart';

class OwnerListingDetailScreen extends StatelessWidget {
  final HostelEntity hostel;

  const OwnerListingDetailScreen({super.key, required this.hostel});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    // Financials are calculated from this hostel's confirmed tenant bookings.
    final tenants =
        provider.tenants.where((t) => t.hostelName == hostel.name).toList();
    final reviews =
        provider.reviews.where((review) => review.hostelId == hostel.id).toList();
    final reviewCount =
        reviews.isNotEmpty ? reviews.length : hostel.reviewsCount;
    final averageRating = reviews.isNotEmpty
        ? reviews.fold<double>(0, (sum, review) => sum + review.rating) /
            reviews.length
        : hostel.rating;
    final grossRent =
        tenants.fold<double>(0, (sum, item) => sum + item.monthlyRent);
    final commission = grossRent * provider.commissionRate;
    final netEarnings = grossRent - commission;
    final rentDue = tenants
        .where((t) => t.paymentStatus == 'Overdue')
        .fold<double>(0, (sum, item) => sum + item.monthlyRent);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(hostel.name,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image
            Stack(
              children: [
                Image.network(
                  hostel.images.isNotEmpty ? hostel.images[0] : '',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 200,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.apartment_rounded,
                        color: AppColors.textMuted, size: 64),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hostel.type.name.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge.fromApprovalStatus(hostel.approvalStatus),
                    ],
                  ),
                ),
              ],
            ),

            if (hostel.approvalStatus == ApprovalStatus.pending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.accent.withValues(alpha: 0.1),
                child: const Text(
                  'Awaiting Admin Approval',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),

            if (hostel.approvalStatus == ApprovalStatus.rejected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.red.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.red),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Rejected by admin. Update the listing and resubmit.',
                        style: TextStyle(
                            color: AppColors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddListingScreen(hostel: hostel),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Resubmit',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hostel.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(hostel.location,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),

                  // Financial Summary
                  const Text('Financial Summary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                            'Gross Rent', currencyFormat.format(grossRent)),
                        const Divider(height: 24),
                        _buildSummaryRow(
                            'Platform Commission (${(provider.commissionRate * 100).toStringAsFixed(0)}%)',
                            '-${currencyFormat.format(commission)}',
                            color: AppColors.red),
                        const Divider(height: 24),
                        _buildSummaryRow(
                            'Net Earnings', currencyFormat.format(netEarnings),
                            color: AppColors.emerald, isBold: true),
                        const Divider(height: 24),
                        _buildSummaryRow(
                            'Rent Due', currencyFormat.format(rentDue),
                            color: AppColors.accent, isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Room Status Section
                  const Text('Room Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...summarizeRooms(hostel: hostel, tenants: tenants)
                      .map((summary) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${summary.type}  •  ${summary.fullRooms} full  •  ${summary.partialRooms} partial  •  ${summary.vacantRooms} vacant',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text('${(summary.progress * 100).toInt()}% beds',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: summary.progress,
                              backgroundColor: AppColors.borderLight,
                              color: summary.progress > 0.9
                                  ? AppColors.accent
                                  : AppColors.primary,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OwnerAllRoomsScreen(hostel: hostel),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View All Rooms'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Tenants
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Tenants',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (tenants.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OwnerTenantsTab(hostelFilter: hostel.name),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (tenants.isEmpty)
                    const Text('No current tenants.',
                        style: TextStyle(color: AppColors.textSecondary))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tenants.length > 5 ? 5 : tenants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tenant = tenants[index];
                        return InkWell(
                          onTap: () =>
                              showTenantDetailsSheet(context, tenant, provider),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage:
                                      NetworkImage(tenant.avatarUrl),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(tenant.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                          '${tenant.roomNumber} (${tenant.roomType}) • ${tenant.contractDuration} Months',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        currencyFormat
                                            .format(tenant.monthlyRent),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: tenant.paymentStatus == 'Paid'
                                            ? AppColors.emerald
                                                .withValues(alpha: 0.1)
                                            : AppColors.accent
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tenant.paymentStatus,
                                        style: TextStyle(
                                          color: tenant.paymentStatus == 'Paid'
                                              ? AppColors.emerald
                                              : AppColors.accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Contract Policy
                  const Text('Contract Policy',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildPolicyRow(
                            'Minimum Stay', '${hostel.minContractMonths} Months'),
                        const Divider(height: 24),
                        _buildPolicyRow(
                          'Annual Rent Increment',
                          '${hostel.rentIncrementPercentage.toStringAsFixed(0)}%',
                        ),
                        const Divider(height: 24),
                        _buildPolicyRow('Notice Period', '1 Month'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reviews
                  const Text('Reviews Preview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: AppColors.accent, size: 24),
                                const SizedBox(width: 8),
                                Text('${averageRating.toStringAsFixed(1)} / 5.0',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Based on $reviewCount reviews',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OwnerReviewsScreen(
                                hostelId: hostel.id,
                                hostelName: hostel.name,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
