import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../providers/admin_provider.dart';
import '../../../widgets/common/status_badge.dart';
import '../screens/admin_pending_listings_screen.dart';
import '../screens/admin_notifications_screen.dart';
import '../screens/admin_pending_listing_detail_screen.dart';
import '../screens/admin_complaints_screen.dart';
import '../widgets/admin_stat_card.dart';

class AdminOverviewTab extends StatelessWidget {
  final Function(int)? onTabChange;
  const AdminOverviewTab({super.key, this.onTabChange});

  FlLine _getHorizontalLine(double value) => const FlLine(
        color: AppColors.borderLight,
        strokeWidth: 1,
      );

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();

    final pending = adminProv.hostels
        .where((h) => h.approvalStatus == ApprovalStatus.pending)
        .toList();
    final openComplaints =
        adminProv.complaints.where((c) => c.status == 'Open').toList();
    final recentActivities = _buildRecentActivities(adminProv);

    return SafeArea(
      child: CustomScrollView(slivers: [
        // App bar
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.verified_user_rounded,
                    color: Colors.white, size: 20)),
            const SizedBox(width: 10),
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OVERVIEW',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1)),
                  Text('Welcome back, Admin',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ]),
          ]),
          actions: [
            Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.textSecondary),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminNotificationsScreen()));
                  },
                )),
          ],
        ),

        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              children: [
                GestureDetector(
                  onTap: () => onTabChange?.call(1),
                  child: AdminStatCard(
                      label: AppStrings.totalUsers,
                      value: '${adminProv.users.length}',
                      trend: '+5%',
                      color: AppColors.primary),
                ),
                GestureDetector(
                  onTap: () => onTabChange?.call(2),
                  child: AdminStatCard(
                      label: AppStrings.activeHostels,
                      value:
                          '${adminProv.hostels.where((h) => h.approvalStatus == ApprovalStatus.approved).length}',
                      trend: '+2%',
                      color: AppColors.emerald),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AdminPendingListingsScreen()));
                  },
                  child: AdminStatCard(
                      label: AppStrings.pendingVerif,
                      value: '${pending.length}',
                      color: AppColors.accent),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminComplaintsScreen()));
                  },
                  child: AdminStatCard(
                      label: 'Open Complaints',
                      value: '${openComplaints.length}',
                      trend: '-1',
                      color: AppColors.red),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Modern Revenue Trend Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REVENUE PERFORMANCE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 1.2)),
                    Text('Monthly Growth',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.emerald.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up,
                          color: AppColors.emerald, size: 14),
                      SizedBox(width: 4),
                      Text('LIVE',
                          style: TextStyle(
                              color: AppColors.emerald,
                              fontSize: 10,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 240,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Subtle Light Pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LightGridPainter(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: LineChart(
                        LineChartData(
                          // Use a virtual X-axis that always represents the last 6 months
                          // 0 = 5 months ago, 5 = current month
                          minX: 0,
                          maxX: 5,
                          minY: 0,
                          maxY: 700000,
                          clipData: const FlClipData.none(),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(6, (i) {
                                // Calculate the actual month index (0-11) for each virtual spot
                                // i=0 (5 months ago), i=5 (current month)
                                final now = DateTime.now();
                                final targetDate =
                                    DateTime(now.year, now.month - (5 - i));
                                // month property is 1-based, index is 0-based
                                final monthIndex = targetDate.month - 1;

                                final commission =
                                    adminProv.getMonthlyCommissionForYear(
                                        targetDate.year)[monthIndex];
                                final revenue =
                                    commission * (1 / adminProv.commissionRate);

                                return FlSpot(i.toDouble(), revenue);
                              }),
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (i < 0 || i > 5) {
                                    return const SizedBox.shrink();
                                  }

                                  // Match the logic in spots to get the correct month name
                                  final now = DateTime.now();
                                  final targetDate =
                                      DateTime(now.year, now.month - (5 - i));

                                  return Text(
                                    DateFormat.MMM().format(targetDate),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                                interval: 1,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0 || value > 600000) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    '${(value / 1000).toInt()}k',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 9,
                                    ),
                                  );
                                },
                                interval: 200000,
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 200000,
                            getDrawingHorizontalLine: _getHorizontalLine,
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _GlobalRoomsTenantsSection(
              hostels: adminProv.hostels,
              bookings: adminProv.bookings
                  .where((b) => b.status == BookingStatus.confirmed)
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Pending approvals
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text(AppStrings.pendingApprovals,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminPendingListingsScreen()));
                },
                child: const Text(AppStrings.seeAll,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ]),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight)),
                child: const Center(
                    child: Text('No pending approvals',
                        style: TextStyle(color: AppColors.textMuted))),
              )
            else
              ...pending.take(2).map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ApprovalCard(hostel: h),
                  )),
            const SizedBox(height: 24),

            // Recent Complaints
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recent Complaints',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminComplaintsScreen()));
                },
                child: const Text(AppStrings.seeAll,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ]),
            const SizedBox(height: 12),
            if (openComplaints.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight)),
                child: const Center(
                    child: Text('No open complaints',
                        style: TextStyle(color: AppColors.textMuted))),
              )
            else
              ...openComplaints.take(2).map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight)),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.warning_amber_rounded,
                                color: AppColors.red, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                Text('${c.byUserName} - ${c.againstName}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('Open',
                                style: TextStyle(
                                    color: AppColors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  )),
            const SizedBox(height: 24),

            // Recent activity
            const Text('Recent Activity',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight)),
              child: recentActivities.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No recent activity yet.',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  : Column(children: [
                      for (var i = 0; i < recentActivities.length; i++) ...[
                        _ActivityRow(activity: recentActivities[i]),
                        if (i != recentActivities.length - 1)
                          const Divider(
                              height: 1, color: AppColors.borderLight),
                      ],
                    ]),
            ),
          ]),
        )),
      ]),
    );
  }

  List<_AdminActivity> _buildRecentActivities(AdminProvider adminProv) {
    final activities = <_AdminActivity>[];

    for (final booking in adminProv.bookings) {
      final date = booking.paymentDate ??
          AppHelpers.parseDate(booking.date, fallback: DateTime.now());
      activities.add(_AdminActivity(
        icon: booking.status.isPaid
            ? Icons.check_circle_rounded
            : Icons.bed_rounded,
        iconColor:
            booking.status.isPaid ? AppColors.emerald : AppColors.primary,
        title: _bookingStatusLabel(booking.status),
        subtitle:
            '${booking.userName} - ${booking.hostelName} - Room ${booking.roomNumber}',
        date: date,
      ));
    }

    for (final complaint in adminProv.complaints) {
      activities.add(_AdminActivity(
        icon: Icons.report_problem_rounded,
        iconColor:
            complaint.status == 'Resolved' ? AppColors.emerald : AppColors.red,
        title: 'Complaint ${complaint.status}',
        subtitle: '${complaint.byUserName} - ${complaint.againstName}',
        date: complaint.createdAt,
      ));
    }

    for (final hostel in adminProv.hostels) {
      final createdAt = hostel.createdAt;
      if (createdAt == null) continue;
      activities.add(_AdminActivity(
        icon: Icons.apartment_rounded,
        iconColor: _hostelStatusColor(hostel.approvalStatus),
        title: _hostelStatusLabel(hostel.approvalStatus),
        subtitle: '${hostel.name} - ${hostel.ownerName}',
        date: createdAt,
      ));
    }

    for (final user in adminProv.users) {
      if (user.joinedDate?.trim().isNotEmpty != true) continue;
      final joined = AppHelpers.parseDate(user.joinedDate!);
      activities.add(_AdminActivity(
        icon: _roleIcon(user.role),
        iconColor: user.status == UserStatus.active
            ? AppColors.primary
            : AppColors.textMuted,
        title: '${_roleLabel(user.role)} Account ${user.status.name}',
        subtitle: '${user.name} - ${user.email}',
        date: joined,
      ));
    }

    for (final payout in adminProv.payouts) {
      activities.add(_AdminActivity(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: AppColors.emerald,
        title: 'Owner Payout ${payout.status}',
        subtitle:
            '${payout.ownerName} - Rs ${AppHelpers.formatPrice(payout.netAmount.round())}',
        date: payout.createdAt,
      ));
    }

    activities.sort((a, b) => b.date.compareTo(a.date));
    return activities.take(5).toList();
  }

  String _bookingStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'New Booking Request';
      case BookingStatus.approved:
      case BookingStatus.paymentPending:
        return 'Booking Approved';
      case BookingStatus.confirmed:
      case BookingStatus.completed:
        return 'Booking Confirmed';
      case BookingStatus.rejected:
      case BookingStatus.declined:
        return 'Booking Rejected';
      case BookingStatus.cancelled:
      case BookingStatus.expired:
      case BookingStatus.overdue:
        return 'Booking Cancelled';
    }
  }

  String _hostelStatusLabel(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return 'New Listing Submitted';
      case ApprovalStatus.approved:
        return 'Hostel Approved';
      case ApprovalStatus.rejected:
        return 'Hostel Rejected';
      case ApprovalStatus.suspended:
        return 'Hostel Suspended';
    }
  }

  Color _hostelStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return AppColors.accent;
      case ApprovalStatus.approved:
        return AppColors.emerald;
      case ApprovalStatus.rejected:
      case ApprovalStatus.suspended:
        return AppColors.red;
    }
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.business_center_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.tenant:
        return Icons.person_add_alt_1_rounded;
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.tenant:
        return 'Tenant';
    }
  }
}

class _ApprovalCard extends StatelessWidget {
  final HostelEntity hostel;
  const _ApprovalCard({required this.hostel});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AdminPendingListingDetailScreen(hostel: hostel)));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight)),
        child: Column(children: [
          Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.apartment_rounded,
                    color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(hostel.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                  Text(hostel.location,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ])),
            const StatusBadge(
                label: 'PENDING',
                backgroundColor: Color(0xFFFEF3C7),
                textColor: AppColors.accent),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _showRejectDialog(context, hostel);
                },
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text(AppStrings.rejectAction,
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<AdminProvider>().approveHostel(hostel.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${hostel.name} approved!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text(AppStrings.approve,
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ));

  void _showRejectDialog(BuildContext context, HostelEntity hostel) {
    final adminProv = context.read<AdminProvider>();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Hostel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Provide a reason for rejecting ${hostel.name}'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                adminProv.rejectHostel(hostel.id, controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${hostel.name} rejected.')),
                );
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _AdminActivity activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activity.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(activity.icon, color: activity.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(activity.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                Text(activity.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ])),
          Text(_relativeTime(activity.date),
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ]),
      );

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(date);
  }
}

class _AdminActivity {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final DateTime date;

  const _AdminActivity({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.date,
  });
}

class _GlobalRoomsTenantsSection extends StatelessWidget {
  final List<HostelEntity> hostels;
  final List<BookingEntity> bookings;

  const _GlobalRoomsTenantsSection({
    required this.hostels,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Global Rooms & Tenants',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          if (bookings.isEmpty)
            const Text('No occupied rooms yet.',
                style: TextStyle(color: AppColors.textMuted))
          else
            ...bookings.take(6).map((booking) {
              var hostelName = booking.hostelName;
              for (final hostel in hostels) {
                if (hostel.id == booking.hostelId) {
                  hostelName = hostel.name;
                  break;
                }
              }
              final paidOn = booking.paymentDate == null
                  ? booking.date
                  : DateFormat('d MMM yyyy').format(booking.paymentDate!);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$hostelName - Room ${booking.roomNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${booking.userName} - Paid on $paidOn',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(currencyFormat.format(booking.price),
                        style: const TextStyle(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _LightGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const double step = 45;
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
