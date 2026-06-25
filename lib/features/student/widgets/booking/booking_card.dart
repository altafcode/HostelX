import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/booking_entity.dart';
import '../../../../domain/entities/hostel_entity.dart';
import '../../../../routes/app_router.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../providers/booking_provider.dart';
import '../../providers/hostel_provider.dart';

class BookingCard extends StatelessWidget {
  final BookingEntity booking;
  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouter.hostelDetails,
          arguments: booking.hostelId,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: booking.hostelImage != null
                      ? Image.network(
                          booking.hostelImage!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _Placeholder(),
                        )
                      : const _Placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge.fromBookingStatus(booking.status),
                          const SizedBox(width: 8),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              '#${booking.id}',
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                  fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        booking.hostelName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Room ${booking.roomNumber}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Applied: ${booking.date}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (booking.status == BookingStatus.approved ||
                booking.status == BookingStatus.paymentPending ||
                booking.status == BookingStatus.pending ||
                booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelBooking(context),
                      child: const Text(AppStrings.cancelBooking),
                    ),
                  ),
                  if (booking.status == BookingStatus.approved ||
                      booking.status == BookingStatus.paymentPending) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openPayment(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text(AppStrings.payNow),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openPayment(BuildContext context) {
    HostelEntity? hostel;
    for (final item in context.read<HostelProvider>().allHostels) {
      if (item.id == booking.hostelId) {
        hostel = item;
        break;
      }
    }

    if (hostel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hostel details are still loading.')),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRouter.checkout,
      arguments: {
        'hostel': hostel,
        'roomType': booking.roomType,
        'roomNumber': booking.roomNumber,
        'price': booking.price,
        'booking': booking,
      },
    );
  }

  void _cancelBooking(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Cancel Booking?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'No, keep it',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BookingProvider>().cancelBooking(booking, 'tenant');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking cancelled.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.apartment_rounded,
          color: AppColors.textMuted, size: 20),
    );
  }
}
