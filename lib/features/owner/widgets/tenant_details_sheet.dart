import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/owner_provider.dart';

void showTenantDetailsSheet(
    BuildContext context, Tenant tenant, OwnerProvider provider) {
  final currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);
  final dateFormat = DateFormat('d MMM yyyy');
  final daysRemaining = tenant.checkOut.difference(DateTime.now()).inDays;

  Color contractStatusColor;
  String contractStatus;
  if (daysRemaining < 0) {
    contractStatus = 'Expired';
    contractStatusColor = AppColors.red;
  } else if (daysRemaining <= 7) {
    contractStatus = 'Expiring Soon';
    contractStatusColor = AppColors.accent;
  } else {
    contractStatus = 'Active';
    contractStatusColor = AppColors.emerald;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(tenant.avatarUrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      tenant.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: contractStatusColor.withValues(
                                          alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      contractStatus,
                                      style: TextStyle(
                                          color: contractStatusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tenant.occupation,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Email', tenant.email),
                          const Divider(height: 24),
                          _buildDetailRow('Phone', tenant.phone),
                          const Divider(height: 24),
                          _buildDetailRow('Occupation', tenant.occupation),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Active Booking Details',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Hostel', tenant.hostelName),
                          const Divider(height: 24),
                          _buildDetailRow('Room',
                              '${tenant.roomNumber} (${tenant.roomType})'),
                          const Divider(height: 24),
                          _buildDetailRow(
                              'Check-in', dateFormat.format(tenant.checkIn)),
                          const Divider(height: 24),
                          _buildDetailRow('Contract End',
                              dateFormat.format(tenant.checkOut)),
                          const Divider(height: 24),
                          _buildDetailRow(
                              'Time Remaining', '$daysRemaining days',
                              valueColor: daysRemaining < 30
                                  ? AppColors.accent
                                  : AppColors.textPrimary),
                          const Divider(height: 24),
                          _buildDetailRow('Monthly Rent',
                              currencyFormat.format(tenant.monthlyRent)),
                          const Divider(height: 24),
                          _buildDetailRow('Escalation',
                              'Current: ${currencyFormat.format(tenant.monthlyRent)} → After 12 months: ${currencyFormat.format(tenant.futureRent)} (${tenant.escalationPolicy.toInt()}% increase)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Payment History',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: List.generate(tenant.paymentHistory.length,
                            (index) {
                          final isPaid = tenant.paymentHistory[index];
                          final monthDate = DateTime(tenant.checkIn.year,
                              tenant.checkIn.month + index, tenant.checkIn.day);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('MMMM yyyy').format(monthDate),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary),
                                    ),
                                    Text(
                                        currencyFormat
                                            .format(tenant.monthlyRent),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? AppColors.emerald
                                            .withValues(alpha: 0.1)
                                        : AppColors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isPaid
                                            ? Icons.check_circle
                                            : Icons.pending_actions,
                                        color: isPaid
                                            ? AppColors.emerald
                                            : AppColors.red,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPaid ? 'Paid' : 'Pending',
                                        style: TextStyle(
                                          color: isPaid
                                              ? AppColors.emerald
                                              : AppColors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Payment reminder sent!')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Send Reminder'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: tenant.paymentStatus == 'Paid'
                                ? null
                                : () {
                                    provider.markTenantPaid(tenant.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Marked as paid!')),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Mark as Paid',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await provider.endTenantContractEarly(tenant.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Contract ended early.')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to end contract: $e')),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.red,
                        ),
                        child: const Text('End Contract Early'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
  final displayValue = value.trim().isEmpty ? 'Not available' : value;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          displayValue,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    ],
  );
}
