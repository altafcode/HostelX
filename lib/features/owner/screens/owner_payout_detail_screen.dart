import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/owner_provider.dart';

class OwnerPayoutDetailScreen extends StatelessWidget {
  final Payout payout;

  const OwnerPayoutDetailScreen({super.key, required this.payout});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);
    final paidTenants =
        provider.tenants.where((tenant) => tenant.paymentStatus == 'Paid').toList();
    final unpaidTenants =
        provider.tenants.where((tenant) => tenant.paymentStatus != 'Paid').toList();
    final totalCollected =
        paidTenants.fold<double>(0, (sum, tenant) => sum + tenant.monthlyRent);
    final commission = totalCollected * 0.1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(DateFormat('MMM yyyy').format(payout.date),
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _SummaryRow(
                    label: 'Total Collected',
                    value: currencyFormat.format(totalCollected)),
                const Divider(),
                _SummaryRow(
                    label: 'Commission Deducted',
                    value: currencyFormat.format(commission)),
                const Divider(),
                _SummaryRow(
                    label: 'Your Payout',
                    value: currencyFormat.format(payout.amount),
                    highlight: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Paid Tenants',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          if (paidTenants.isEmpty)
            const Text('No paid tenants found.',
                style: TextStyle(color: AppColors.textMuted))
          else
            ...paidTenants.map((tenant) => _TenantPaymentRow(
                  name: tenant.name,
                  amount: currencyFormat.format(tenant.monthlyRent),
                  detail: DateFormat('d MMM yyyy').format(tenant.joinedDate),
                  paid: true,
                )),
          const SizedBox(height: 24),
          const Text('Unpaid Tenants',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          if (unpaidTenants.isEmpty)
            const Text('No unpaid tenants found.',
                style: TextStyle(color: AppColors.textMuted))
          else
            ...unpaidTenants.map((tenant) => _TenantPaymentRow(
                  name: tenant.name,
                  amount: currencyFormat.format(tenant.monthlyRent),
                  detail: 'Due amount',
                  paid: false,
                )),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        Text(value,
            style: TextStyle(
                color: highlight ? AppColors.emerald : AppColors.textPrimary,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _TenantPaymentRow extends StatelessWidget {
  final String name;
  final String amount;
  final String detail;
  final bool paid;

  const _TenantPaymentRow({
    required this.name,
    required this.amount,
    required this.detail,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            paid ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: paid ? AppColors.emerald : AppColors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(detail,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(amount,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
