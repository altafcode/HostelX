import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/hostel_entity.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  /// Factory for BookingStatus
  factory StatusBadge.fromBookingStatus(BookingStatus status) {
    Color bg;
    Color text;
    switch (status) {
      case BookingStatus.pending:
        bg = AppColors.statusPendingBg;
        text = AppColors.statusPending;
      case BookingStatus.approved:
      case BookingStatus.paymentPending:
        bg = AppColors.statusApprovedBg;
        text = AppColors.statusApproved;
      case BookingStatus.confirmed:
      case BookingStatus.completed:
        bg = AppColors.statusCompletedBg;
        text = AppColors.statusCompleted;
      case BookingStatus.rejected:
      case BookingStatus.declined:
        bg = AppColors.statusDeclinedBg;
        text = AppColors.statusDeclined;
      case BookingStatus.cancelled:
        bg = AppColors.statusCancelledBg;
        text = AppColors.statusCancelled;
      case BookingStatus.expired:
      case BookingStatus.overdue:
        bg = AppColors.statusDeclinedBg;
        text = AppColors.statusDeclined;
    }
    return StatusBadge(
      label: status.name,
      backgroundColor: bg,
      textColor: text,
    );
  }

  /// Factory for ApprovalStatus
  factory StatusBadge.fromApprovalStatus(ApprovalStatus status) {
    Color bg;
    Color text;
    switch (status) {
      case ApprovalStatus.pending:
        bg = AppColors.statusPendingBg;
        text = AppColors.statusPending;
      case ApprovalStatus.approved:
        bg = AppColors.statusApprovedBg;
        text = AppColors.statusApproved;
      case ApprovalStatus.rejected:
        bg = AppColors.statusDeclinedBg;
        text = AppColors.statusDeclined;
      case ApprovalStatus.suspended:
        bg = const Color(0xFFFEF3C7);
        text = AppColors.accent;
    }
    return StatusBadge(
      label: status.name,
      backgroundColor: bg,
      textColor: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
