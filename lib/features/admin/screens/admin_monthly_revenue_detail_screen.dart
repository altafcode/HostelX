import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../domain/entities/booking_entity.dart';
import '../providers/admin_provider.dart';
import 'admin_hostel_detail_screen.dart';

class AdminMonthlyRevenueDetailScreen extends StatelessWidget {
  final String monthName;
  final int year;

  const AdminMonthlyRevenueDetailScreen({
    super.key,
    required this.monthName,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    final month = DateFormat.MMM().parse(monthName).month;
    final Map<String, _HostelRevenue> breakdown = {};
    final monthlyBookings = <BookingEntity>[];

    for (var b in adminProv.bookings) {
      if (!b.status.isPaid) continue;
      final paidOrCreatedDate = b.paymentDate ??
          AppHelpers.parseDate(b.date, fallback: DateTime.now());
      if (paidOrCreatedDate.year != year || paidOrCreatedDate.month != month) {
        continue;
      }
      monthlyBookings.add(b);

      if (!breakdown.containsKey(b.hostelId)) {
        breakdown[b.hostelId] = _HostelRevenue(
          hostelId: b.hostelId,
          hostelName: b.hostelName,
          totalRevenue: 0,
          commission: 0,
        );
      }

      final revenue = b.rentAmount;
      final commission = adminProv.calculateCommission(revenue);

      breakdown[b.hostelId]!.totalRevenue += revenue;
      breakdown[b.hostelId]!.commission += commission;
    }

    final sortedBreakdown = breakdown.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    monthlyBookings.sort((a, b) {
      final aDate = a.paymentDate ??
          AppHelpers.parseDate(a.date, fallback: DateTime.now());
      final bDate = b.paymentDate ??
          AppHelpers.parseDate(b.date, fallback: DateTime.now());
      return bDate.compareTo(aDate);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$monthName $year Breakdown',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const Text('Hostel Earning Performance',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          _HeaderStats(
            totalRevenue: sortedBreakdown.fold(
                0.0, (sum, item) => sum + item.totalRevenue),
            totalCommission:
                sortedBreakdown.fold(0.0, (sum, item) => sum + item.commission),
            currencyFormat: currencyFormat,
          ),
          Expanded(
            child: sortedBreakdown.isEmpty && monthlyBookings.isEmpty
                ? const Center(
                    child: Text(
                      'No paid bookings for this month.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const _SectionTitle('Paid Bookings & Payment Details'),
                      const SizedBox(height: 12),
                      ...monthlyBookings.map(
                        (booking) => _BookingPaymentCard(
                          booking: booking,
                          currencyFormat: currencyFormat,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _SectionTitle('Hostel Earning Performance'),
                      const SizedBox(height: 12),
                      ...sortedBreakdown.asMap().entries.map((entry) {
                        final item = entry.value;
                        return _RevenueCard(
                          rank: entry.key + 1,
                          data: item,
                          currencyFormat: currencyFormat,
                          onTap: () {
                            final hostel =
                                adminProv.getHostelById(item.hostelId);
                            if (hostel != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminHostelDetailScreen(hostel: hostel),
                                ),
                              );
                            }
                          },
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _BookingPaymentCard extends StatelessWidget {
  final BookingEntity booking;
  final NumberFormat currencyFormat;

  const _BookingPaymentCard({
    required this.booking,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final paidOn = booking.paymentDate ??
        AppHelpers.parseDate(booking.date, fallback: DateTime.now());
    final avatarText =
        booking.hostelName.isEmpty ? 'H' : booking.hostelName[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            child: Text(
              avatarText,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.hostelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.userName} - Room ${booking.roomNumber} (${booking.roomType})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Paid on ${DateFormat('d MMM yyyy').format(paidOn)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(booking.rentAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Paid',
                style: TextStyle(
                  color: AppColors.emerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStats extends StatelessWidget {
  final double totalRevenue;
  final double totalCommission;
  final NumberFormat currencyFormat;

  const _HeaderStats({
    required this.totalRevenue,
    required this.totalCommission,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              label: 'Total Month Revenue',
              value: currencyFormat.format(totalRevenue),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: 'Platform Commission',
              value: currencyFormat.format(totalCommission),
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final int rank;
  final _HostelRevenue data;
  final NumberFormat currencyFormat;
  final VoidCallback? onTap;

  const _RevenueCard({
    required this.rank,
    required this.data,
    required this.currencyFormat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rank <= 3
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 13,
                    )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.hostelName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Revenue: ',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      Text(currencyFormat.format(data.totalRevenue),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Commission',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
                Text(currencyFormat.format(data.commission),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HostelRevenue {
  final String hostelId;
  final String hostelName;
  double totalRevenue;
  double commission;

  _HostelRevenue({
    required this.hostelId,
    required this.hostelName,
    required this.totalRevenue,
    required this.commission,
  });
}
