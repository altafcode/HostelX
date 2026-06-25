import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../widgets/common/status_badge.dart';


class ActivityItem extends StatelessWidget {
  final BookingEntity booking;

  final VoidCallback? onTap;

  const ActivityItem({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            AppHelpers.getInitials(booking.userName),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text(booking.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
            ),
            const SizedBox(width: 6),
            StatusBadge.fromBookingStatus(booking.status),
          ]),
          Text(
            'Requested: ${booking.hostelName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary),
          ),
          Text(
            booking.date,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ])),
        if (onTap != null)
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textMuted),
      ]),
    ));
  }
}
