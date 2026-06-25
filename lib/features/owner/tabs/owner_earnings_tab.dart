import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../providers/owner_provider.dart';
import '../screens/owner_revenue_detail_screen.dart';
import '../screens/owner_payment_history_screen.dart';

class OwnerRevenueTab extends StatefulWidget {
  const OwnerRevenueTab({super.key});

  @override
  State<OwnerRevenueTab> createState() => _OwnerRevenueTabState();
}

class _OwnerRevenueTabState extends State<OwnerRevenueTab> {
  int _revenueYear = 2026;
  int _bookingYear = 2026;
  bool _showReceivedPayouts = false;
  final List<int> _years = [2025, 2026];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    final now = DateTime.now();
    final currentMonthIndex = now.month - 1;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: Text('Revenue & Insights',
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
                        const Text('Total Net Earnings',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(currencyFormat.format(provider.totalNetEarnings),
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
                            Text(
                                'Platform Commission (${(provider.commissionRate * 100).toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(
                                '- ${currencyFormat.format(provider.totalCommissionDeducted)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payouts Received',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(
                                currencyFormat
                                    .format(provider.totalReceivedPayouts),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pending Release',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(
                                currencyFormat.format(
                                    (provider.totalNetEarnings -
                                            provider.totalReceivedPayouts)
                                        .clamp(0, double.infinity)),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionBtn(
                          label: 'Payment History',
                          icon: Icons.history_rounded,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const OwnerPaymentHistoryScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionBtn(
                          label: 'Bank Details',
                          icon: Icons.account_balance_rounded,
                          onTap: () => _showBankDetailsDialog(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Monthly Net Revenue Bar Chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                            _showReceivedPayouts
                                ? 'Monthly Payouts Received'
                                : 'Monthly Net Revenue',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(
                            () => _showReceivedPayouts = !_showReceivedPayouts),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _showReceivedPayouts
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              _showReceivedPayouts ? 'Show Net' : 'Payouts',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _showReceivedPayouts
                                      ? AppColors.accent
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
                    height: 260, // Increased to avoid y-axis cutoff
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
                            maxY: 200000, // Increased to provide headroom
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
                                  // Live Tracker: Only allow clicks on current or past months for current year
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
                                            OwnerRevenueDetailScreen(
                                                monthName: monthName,
                                                year: _revenueYear,
                                                monthIndex: x)),
                                  );
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
                                  reservedSize: 52,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 50000 == 0) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Text(
                                            '${(value / 1000).toInt()}k',
                                            textAlign: TextAlign.right,
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
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 50000,
                              getDrawingHorizontalLine: (value) => const FlLine(
                                  color: AppColors.borderLight,
                                  strokeWidth: 1,
                                  dashArray: [5, 5]),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: provider
                                .getGrossRentForYear(_revenueYear)
                                .asMap()
                                .entries
                                .map((e) {
                              final isFuture = _revenueYear == now.year &&
                                  e.key > currentMonthIndex;
                              final isCurrent = _revenueYear == now.year &&
                                  e.key == currentMonthIndex;
                              final payouts = provider
                                  .getReceivedPayoutsForYear(_revenueYear);
                              final netRevenue = isFuture
                                  ? 0.0
                                  : _showReceivedPayouts
                                      ? payouts[e.key]
                                      : e.value * (1 - provider.commissionRate);

                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: netRevenue,
                                    color: isCurrent
                                        ? AppColors.accent
                                        : (_showReceivedPayouts
                                            ? AppColors.emerald
                                            : AppColors.primary),
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 150000,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.05),
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

                  _OwnerMonthlySnapshotStrip(
                    provider: provider,
                    year: _revenueYear,
                    currentMonthIndex: currentMonthIndex,
                    currencyFormat: currencyFormat,
                    isCurrentYear: _revenueYear == now.year,
                  ),
                  const SizedBox(height: 24),

                  _buildBookingTrendSection(provider, now, currentMonthIndex),
                  const SizedBox(height: 24),

                  // Earnings Detailed Table Breakdown (Matching Admin Style)
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
                        const _DetailHeader(),
                        const Divider(height: 1),
                        ...List.generate(12, (i) {
                          final month =
                              DateFormat.MMM().format(DateTime(2026, i + 1));
                          final isFuture =
                              _revenueYear == now.year && i > currentMonthIndex;
                          final gross =
                              provider.getGrossRentForYear(_revenueYear)[i];
                          final net = gross * (1 - provider.commissionRate);

                          return _DetailRow(
                            month: month,
                            gross:
                                isFuture ? '-' : currencyFormat.format(gross),
                            net: isFuture ? '-' : currencyFormat.format(net),
                            isLast: i == 11,
                            onTap: isFuture
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              OwnerRevenueDetailScreen(
                                                  monthName: month,
                                                  year: _revenueYear,
                                                  monthIndex: i)),
                                    );
                                  },
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Upcoming Rent Changes
                  const Text('Upcoming Rent Changes',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: provider.tenants
                          .where((t) =>
                              t.checkOut.difference(DateTime.now()).inDays < 60)
                          .map((tenant) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tenant.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        '${tenant.roomNumber} (${tenant.roomType})',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                    Text(
                                        'Effective: ${DateFormat('MMM dd, yyyy').format(tenant.checkOut)}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${currencyFormat.format(tenant.monthlyRent)} → ${currencyFormat.format(tenant.futureRent)}',
                                    style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                      '+${tenant.escalationPolicy.toInt()}% increase',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTrendSection(
    OwnerProvider provider,
    DateTime now,
    int currentMonthIndex,
  ) {
    final bookingCounts = provider.getBookingsForYear(_bookingYear);
    final maxBookings = bookingCounts.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    final chartMaxY = (maxBookings + 2).clamp(6, 40).toDouble();

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
                      color: AppColors.accent,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accent.withValues(alpha: 0.1),
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
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) {
                          if (value % 5 == 0) {
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
            _buildTextField('Bank Name (e.g., HBL, Meezan)',
                controller: bankNameCtrl),
            const SizedBox(height: 12),
            _buildTextField('Account Title', controller: accountTitleCtrl),
            const SizedBox(height: 12),
            _buildTextField('IBAN (PK...)', controller: ibanCtrl),
            const SizedBox(height: 12),
            _buildTextField('Stripe Account ID (acct_...)',
                controller: stripeAccountCtrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
                  const SnackBar(
                      content: Text('Bank details saved successfully.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildActionBtn(
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _OwnerMonthlySnapshotStrip extends StatelessWidget {
  final OwnerProvider provider;
  final int year;
  final int currentMonthIndex;
  final NumberFormat currencyFormat;
  final bool isCurrentYear;

  const _OwnerMonthlySnapshotStrip({
    required this.provider,
    required this.year,
    required this.currentMonthIndex,
    required this.currencyFormat,
    required this.isCurrentYear,
  });

  @override
  Widget build(BuildContext context) {
    final grossByMonth = provider.getGrossRentForYear(year);
    final bookingsByMonth = provider.getBookingsForYear(year);
    final payoutsByMonth = provider.getReceivedPayoutsForYear(year);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monthly Snapshot',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isFuture = isCurrentYear && index > currentMonthIndex;
              final month = DateFormat.MMM().format(DateTime(2026, index + 1));
              final net = grossByMonth[index] * (1 - provider.commissionRate);
              return Container(
                width: 132,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: index == currentMonthIndex && isCurrentYear
                        ? AppColors.accent.withValues(alpha: 0.45)
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
                    Text(isFuture ? '-' : currencyFormat.format(net),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emerald)),
                    const SizedBox(height: 8),
                    Text('Bookings: ${isFuture ? '-' : bookingsByMonth[index]}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                        'Payout: ${isFuture ? '-' : currencyFormat.format(payoutsByMonth[index])}',
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
  const _DetailHeader();
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
              child: Text('Gross Rent',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted))),
          Expanded(
              flex: 3,
              child: Text('Net Earnings',
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
  final String gross;
  final String net;
  final bool isLast;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.month,
    required this.gross,
    required this.net,
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
                    child: Text(gross,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary))),
                Expanded(
                  flex: 3,
                  child: Text(
                    net,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color:
                          net == '-' ? AppColors.textMuted : AppColors.emerald,
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

  const _YearPicker(
      {required this.selectedYear,
      required this.years,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: onChanged,
      itemBuilder: (context) => years
          .map((y) => PopupMenuItem(
              value: y,
              child: Text('$y', style: const TextStyle(fontSize: 14))))
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
            Text('$selectedYear',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
