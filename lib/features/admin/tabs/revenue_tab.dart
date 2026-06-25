import 'package:flutter/material.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/booking_entity.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../domain/entities/payout_entity.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/payout_service.dart';
import '../providers/admin_provider.dart';
import '../screens/admin_monthly_revenue_detail_screen.dart';
import '../../../data/services/stripe_service.dart';
import '../../student/services/booking_service.dart';

class AdminRevenueTab extends StatefulWidget {
  const AdminRevenueTab({super.key});

  @override
  State<AdminRevenueTab> createState() => _AdminRevenueTabState();
}

class _AdminRevenueTabState extends State<AdminRevenueTab> {
  final Map<String, bool> _payoutStatus = {}; // userId -> isReleased
  final Set<String> _releasingPayouts = {};
  final PayoutService _payoutService = PayoutService();
  final BookingService _bookingService = BookingService();
  int _revenueYear = 2026;
  int _bookingYear = 2026;
  bool _showCommissionOnly = false;
  bool _showReleasedPayouts = false;

  final List<int> _years = [2025, 2026];

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    final now = DateTime.now();
    final currentMonthIndex = now.month - 1;

    // Owners with payouts
    final owners =
        adminProv.users.where((u) => u.role == UserRole.owner).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: Text('Revenue & Payouts',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Platform Revenue',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(currencyFormat.format(adminProv.totalEarnings),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white30),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('Platform Commission (Net)',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                  currencyFormat
                                      .format(adminProv.totalCommission),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('Released to Owners',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                  currencyFormat
                                      .format(adminProv.totalReleasedPayouts),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('Pending Owner Payouts',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                  currencyFormat.format(
                                      (adminProv.totalEarnings -
                                              adminProv.totalCommission -
                                              adminProv.totalReleasedPayouts)
                                          .clamp(0, double.infinity)),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Commission Rate Editor
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Platform Commission Rate',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(
                                  '${(adminProv.commissionRate * 100).toInt()}% per booking',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () =>
                              _showEditCommissionDialog(context, adminProv),
                          icon: const Icon(Icons.edit,
                              size: 16, color: AppColors.primary),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Monthly Revenue & Commission Bar Chart (Live Tracker)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                            _showReleasedPayouts
                                ? 'Payouts Released'
                                : _showCommissionOnly
                                    ? 'Commission (Net)'
                                    : 'Total Revenue (Gross)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, // Reduced slightly
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          _showReleasedPayouts = false;
                          _showCommissionOnly = !_showCommissionOnly;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _showCommissionOnly && !_showReleasedPayouts
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              _showCommissionOnly
                                  ? 'Show Revenue'
                                  : 'Comm Only', // Shortened
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _showCommissionOnly &&
                                          !_showReleasedPayouts
                                      ? AppColors.accent
                                      : AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(
                            () => _showReleasedPayouts = !_showReleasedPayouts),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _showReleasedPayouts
                                ? AppColors.emerald.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              _showReleasedPayouts ? 'Show Rev' : 'Payouts',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _showReleasedPayouts
                                      ? AppColors.emerald
                                      : AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _YearPicker(
                        selectedYear: _revenueYear,
                        years: _years,
                        onChanged: (y) => setState(() => _revenueYear = y),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 260,
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 700,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceEvenly,
                            maxY: _showCommissionOnly && !_showReleasedPayouts
                                ? 120000
                                : 900000,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => AppColors.primary,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  String month = DateFormat.MMM().format(
                                      DateTime(2026, group.x.toInt() + 1));
                                  return BarTooltipItem(
                                    '$month\n',
                                    const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: currencyFormat.format(rod.toY),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              touchCallback: (FlTouchEvent event, barResponse) {
                                if (!event.isInterestedForInteractions ||
                                    barResponse == null ||
                                    barResponse.spot == null) {
                                  return;
                                }
                                if (event is FlTapUpEvent) {
                                  final x =
                                      barResponse.spot!.touchedBarGroupIndex;
                                  if (_revenueYear == now.year &&
                                      x > currentMonthIndex) {
                                    return;
                                  }

                                  final monthName = DateFormat.MMM()
                                      .format(DateTime(2026, x + 1));
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              AdminMonthlyRevenueDetailScreen(
                                                  monthName: monthName,
                                                  year: _revenueYear)));
                                }
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < 0 ||
                                        value.toInt() >= 12) {
                                      return const SizedBox.shrink();
                                    }
                                    final month = DateFormat.MMM().format(
                                        DateTime(2026, value.toInt() + 1));
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(month,
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10)),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    final interval = _showCommissionOnly &&
                                            !_showReleasedPayouts
                                        ? 20000
                                        : 200000;
                                    if (value % interval == 0) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Text(
                                            'Rs ${(value / 1000).toInt()}k',
                                            style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold)),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
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
                              horizontalInterval:
                                  _showCommissionOnly && !_showReleasedPayouts
                                      ? 20000
                                      : 200000,
                              getDrawingHorizontalLine: (value) => const FlLine(
                                  color: AppColors.borderLight,
                                  strokeWidth: 1,
                                  dashArray: [5, 5]),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: adminProv
                                .getMonthlyCommissionForYear(_revenueYear)
                                .asMap()
                                .entries
                                .map((e) {
                              final isFuture = _revenueYear == now.year &&
                                  e.key > currentMonthIndex;
                              final isCurrent = _revenueYear == now.year &&
                                  e.key == currentMonthIndex;

                              final releasedPayouts =
                                  adminProv.getMonthlyReleasedPayoutsForYear(
                                      _revenueYear);
                              final commission = isFuture ? 0.0 : e.value;
                              final revenue =
                                  commission * (1 / adminProv.commissionRate);
                              final value = isFuture
                                  ? 0.0
                                  : _showReleasedPayouts
                                      ? releasedPayouts[e.key]
                                      : _showCommissionOnly
                                          ? commission
                                          : revenue;

                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: value,
                                    color: isCurrent
                                        ? AppColors.accent
                                        : _showReleasedPayouts
                                            ? AppColors.emerald
                                            : (_showCommissionOnly
                                                ? AppColors.accent
                                                : AppColors.primary),
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: _showCommissionOnly &&
                                              !_showReleasedPayouts
                                          ? 100000
                                          : 800000,
                                      color: AppColors.surfaceVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _AdminMonthlySnapshotStrip(
                    adminProv: adminProv,
                    year: _revenueYear,
                    currentMonthIndex: currentMonthIndex,
                    currencyFormat: currencyFormat,
                    isCurrentYear: _revenueYear == now.year,
                  ),
                  const SizedBox(height: 24),

                  _buildBookingTrendSection(adminProv, now, currentMonthIndex),
                  const SizedBox(height: 24),

                  // Earnings Detail Table (12 Months)
                  const Text('Revenue Detailed Breakdown',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        _DetailHeader(),
                        const Divider(height: 1),
                        ...List.generate(12, (i) {
                          final month =
                              DateFormat.MMM().format(DateTime(2026, i + 1));
                          final isFuture =
                              _revenueYear == now.year && i > currentMonthIndex;

                          final commission = adminProv
                              .getMonthlyCommissionForYear(_revenueYear)[i];
                          final revenue =
                              commission * (1 / adminProv.commissionRate);

                          return _DetailRow(
                            month: month,
                            revenue:
                                isFuture ? '-' : currencyFormat.format(revenue),
                            commission: isFuture
                                ? '-'
                                : currencyFormat.format(commission),
                            isLast: i == 11,
                            onTap: isFuture
                                ? null
                                : () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                AdminMonthlyRevenueDetailScreen(
                                                    monthName: month,
                                                    year: _revenueYear)));
                                  },
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Owner Payouts List
                  const Text('Owner Payouts (This Month)',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ...owners.map((o) {
                    final isReleased = (_payoutStatus[o.id] ?? false) ||
                        adminProv.hasReleasedPayoutForOwnerThisMonth(o.id);
                    final isReleasing = _releasingPayouts.contains(o.id);
                    final totalRent =
                        adminProv.calculateTotalRentForOwnerThisMonth(o.id);
                    final payoutAmount =
                        adminProv.calculateOwnerPayout(totalRent);
                    final commissionAmount =
                        adminProv.calculateCommission(totalRent);
                    final ownerHostels = adminProv.getHostelsForOwner(o.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.surfaceVariant,
                              child: Text(o.name[0],
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  Text(
                                      'Payout: ${currencyFormat.format(payoutAmount)}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: isReleased || isReleasing
                                  ? null
                                  : () async {
                                      if (payoutAmount <= 0) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'No payout is available for ${o.name} this month.')),
                                        );
                                        return;
                                      }

                                      final bankDetails = o.bankDetails;
                                      final stripeAccountId =
                                          (bankDetails?['stripeAccountId'] ??
                                                  '')
                                              .toString()
                                              .trim();

                                      if (bankDetails == null ||
                                          bankDetails['iban'] == null ||
                                          bankDetails['iban']
                                              .toString()
                                              .isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  '${o.name} has not provided valid bank details yet.')),
                                        );
                                        return;
                                      }

                                      if (stripeAccountId.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  '${o.name} has not added a Stripe connected account ID yet.')),
                                        );
                                        return;
                                      }

                                      setState(() {
                                        _releasingPayouts.add(o.id);
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Processing Stripe transfer for ${o.name}...')),
                                      );

                                      try {
                                        final stripe = StripeService();
                                        final result =
                                            await stripe.releaseOwnerPayout(
                                          amount: payoutAmount,
                                          connectedAccountId: stripeAccountId,
                                          ownerId: o.id,
                                          ownerName: o.name,
                                        );

                                        if (result.success) {
                                          final now = DateTime.now();
                                          final payout = PayoutEntity(
                                            id: '${o.id}_${now.year}_${now.month}',
                                            ownerId: o.id,
                                            ownerName: o.name,
                                            hostelIds: ownerHostels
                                                .map((h) => h.id)
                                                .toList(),
                                            hostelNames: ownerHostels
                                                .map((h) => h.name)
                                                .toList(),
                                            grossAmount: totalRent,
                                            commissionAmount: commissionAmount,
                                            netAmount: payoutAmount,
                                            status: 'paid',
                                            method: 'stripe',
                                            transferId: result.transferId,
                                            date: AppHelpers.formatDate(now),
                                            year: now.year,
                                            month: now.month,
                                          );
                                          await _payoutService
                                              .savePayout(payout);
                                          final paidBookingIds = adminProv
                                              .bookings
                                              .where((b) =>
                                                  ownerHostels.any((h) =>
                                                      h.id == b.hostelId) &&
                                                  b.status ==
                                                      BookingStatus.confirmed &&
                                                  AppHelpers.parseDate(b.date)
                                                          .year ==
                                                      now.year &&
                                                  AppHelpers.parseDate(b.date)
                                                          .month ==
                                                      now.month &&
                                                  b.payoutStatus != 'paid')
                                              .map((b) => b.id)
                                              .toList();
                                          if (paidBookingIds.isNotEmpty) {
                                            await _bookingService
                                                .markPayoutPaid(
                                              bookingIds: paidBookingIds,
                                              payoutId: payout.id,
                                            );
                                          }
                                          await NotificationService()
                                              .sendNotification(
                                            userId: o.id,
                                            title: 'Payout Received',
                                            body:
                                                'Admin released ${currencyFormat.format(payoutAmount)} for ${ownerHostels.map((h) => h.name).join(', ')} via Stripe.',
                                            type: 'payout',
                                          );
                                          setState(() {
                                            _payoutStatus[o.id] = true;
                                          });
                                          if (context.mounted) {
                                            final transfer = result
                                                        .transferId ==
                                                    null
                                                ? ''
                                                : ' Transfer: ${result.transferId}';
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Released ${currencyFormat.format(payoutAmount)} to ${o.name} via Stripe.$transfer')),
                                            );
                                          }
                                        } else if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(result.message)),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(e.toString())),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _releasingPayouts.remove(o.id);
                                          });
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isReleased
                                    ? AppColors.surfaceVariant
                                    : AppColors.emerald,
                                foregroundColor: isReleased
                                    ? AppColors.emerald
                                    : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                isReleased
                                    ? 'Released'
                                    : isReleasing
                                        ? 'Releasing...'
                                        : 'Release',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTrendSection(
    AdminProvider adminProv,
    DateTime now,
    int currentMonthIndex,
  ) {
    final bookingCounts = adminProv.getMonthlyBookingsForYear(_bookingYear);
    final maxBookings = bookingCounts.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    final chartMaxY = (maxBookings + 4).clamp(12, 80).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Booking Trends',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            _YearPicker(
              selectedYear: _bookingYear,
              years: _years,
              onChanged: (y) => setState(() => _bookingYear = y),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 700,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: chartMaxY,
                  maxX: 11.5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: bookingCounts.asMap().entries.where((e) {
                        if (_bookingYear == now.year &&
                            e.key > currentMonthIndex) {
                          return false;
                        }
                        return true;
                      }).map((e) {
                        return FlSpot(e.key.toDouble(), e.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < 12) {
                            final month = DateFormat.MMM()
                                .format(DateTime(2026, index + 1));
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(month,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          if (value % 5 == 0 && value >= 0) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text('${value.toInt()}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditCommissionDialog(
      BuildContext context, AdminProvider adminProv) {
    final controller = TextEditingController(
        text: (adminProv.commissionRate * 100).toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Commission Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new percentage (e.g., 10 for 10%)'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            onPressed: () {
              final newRate = double.tryParse(controller.text);
              if (newRate != null && newRate >= 0 && newRate <= 100) {
                adminProv.updateCommissionRate(newRate / 100);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Commission rate updated.')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _AdminMonthlySnapshotStrip extends StatelessWidget {
  final AdminProvider adminProv;
  final int year;
  final int currentMonthIndex;
  final NumberFormat currencyFormat;
  final bool isCurrentYear;

  const _AdminMonthlySnapshotStrip({
    required this.adminProv,
    required this.year,
    required this.currentMonthIndex,
    required this.currencyFormat,
    required this.isCurrentYear,
  });

  @override
  Widget build(BuildContext context) {
    final commissions = adminProv.getMonthlyCommissionForYear(year);
    final bookings = adminProv.getMonthlyBookingsForYear(year);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monthly Booking & Payment Summary',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isFuture = isCurrentYear && index > currentMonthIndex;
              final month = DateFormat.MMM().format(DateTime(2026, index + 1));
              final commission = commissions[index];
              final revenue = adminProv.commissionRate == 0
                  ? 0.0
                  : commission / adminProv.commissionRate;

              return Container(
                width: 142,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: index == currentMonthIndex && isCurrentYear
                        ? AppColors.primary.withValues(alpha: 0.45)
                        : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(month,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(isFuture ? '-' : currencyFormat.format(revenue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text('Bookings: ${isFuture ? '-' : bookings[index]}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                        'Comm: ${isFuture ? '-' : currencyFormat.format(commission)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('Month',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted))),
          Expanded(
              flex: 3,
              child: Text('Total Revenue',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted))),
          Expanded(
              flex: 3,
              child: Text('Commission',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String month;
  final String revenue;
  final String commission;
  final bool isLast;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.month,
    required this.revenue,
    required this.commission,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(month,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(
                    flex: 3,
                    child: Text(revenue,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary))),
                Expanded(
                  flex: 3,
                  child: Text(
                    commission,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: commission == '-'
                          ? AppColors.textMuted
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _YearPicker extends StatelessWidget {
  final int selectedYear;
  final List<int> years;
  final ValueChanged<int> onChanged;

  const _YearPicker({
    required this.selectedYear,
    required this.years,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: onChanged,
      itemBuilder: (context) => years
          .map((y) => PopupMenuItem(
                value: y,
                child: Text('$y', style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$selectedYear',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
