import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../data/services/notification_service.dart';
import '../../../widgets/common/status_badge.dart';
import '../../student/providers/booking_provider.dart';
import '../../student/providers/hostel_provider.dart';
import '../utils/room_inventory.dart';

class RequestCard extends StatelessWidget {
  final BookingEntity booking;

  const RequestCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              AppHelpers.getInitials(booking.userName),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  booking.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                Text(
                  booking.hostelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  'Applied ${booking.date}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ])),
          StatusBadge.fromBookingStatus(booking.status),
        ]),
        if (booking.status == BookingStatus.pending) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeclineDialog(context),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text(AppStrings.reject),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAcceptDialog(context),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text(AppStrings.accept),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ] else if (booking.status.isActive) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context
                    .read<BookingProvider>()
                    .cancelBooking(booking, 'owner');
                await NotificationService().sendNotification(
                  userId: booking.userId,
                  title: 'Booking Cancelled',
                  body:
                      'Your booking at ${booking.hostelName} has been cancelled by the owner.',
                  type: 'booking',
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking cancelled.')),
                );
              },
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text(AppStrings.cancelBooking),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.borderLight),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  void _showDeclineDialog(BuildContext context) {
    String? selectedReason;
    final reasons = [
      'Room not available',
      'Tenant profile incomplete',
      'Duration not accepted',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Decline Request',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r in reasons)
                  RadioListTile<String>(
                    title: Text(r, style: const TextStyle(fontSize: 14)),
                    value: r,
                    // ignore: deprecated_member_use
                    groupValue: selectedReason,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setState(() => selectedReason = val);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedReason == null
                    ? null
                    : () async {
                        final bookingProvider = context.read<BookingProvider>();
                        await bookingProvider.rejectBooking(booking);
                        await NotificationService().sendNotification(
                          userId: booking.userId,
                          title: 'Booking Rejected',
                          body:
                              'Your booking request for ${booking.hostelName} was rejected.',
                          type: 'booking',
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request declined.')));
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                child: const Text('Decline',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAcceptDialog(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);
    final dateFormat = DateFormat('d MMM yyyy');

    String? selectedRoom;
    DateTime startDate = DateTime.now();
    final hostel = context.read<HostelProvider>().hostelById(booking.hostelId);
    final allBookings = context.read<BookingProvider>().bookings;
    final availableRooms = hostel == null
        ? <String>[]
        : availableRoomsForType(
            hostel: hostel,
            roomType: booking.roomType,
            bookings: allBookings,
          ).map((room) => room.number).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          DateTime endDate =
              DateTime(startDate.year + 1, startDate.month, startDate.day);

          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Accept & Assign Room',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Room Number',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    'Showing available ${normalizeRoomType(booking.roomType)} rooms only',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedRoom,
                    hint: Text(availableRooms.isEmpty
                        ? 'No room available for this type'
                        : 'Select Room Number'),
                    items: availableRooms.map((String room) {
                      return DropdownMenuItem<String>(
                        value: room,
                        child: Text(room),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedRoom = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Contract Start Date',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setState(() => startDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateFormat.format(startDate)),
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Contract End Date (1 Year)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(dateFormat.format(endDate),
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  const Text('Monthly Rent',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(currencyFormat.format(booking.price.toDouble()),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (selectedRoom == null)
                    ? null
                    : () async {
                        final bookingProvider = context.read<BookingProvider>();
                        await bookingProvider.approveBooking(
                          booking.copyWith(
                            roomNumber: selectedRoom,
                            roomType: normalizeRoomType(booking.roomType),
                          ),
                        );
                        await NotificationService().sendNotification(
                          userId: booking.userId,
                          title: 'Booking Approved',
                          body:
                              'Your booking at ${booking.hostelName} has been approved. Please pay now.',
                          type: 'booking',
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Room $selectedRoom assigned. Student can pay now.')));
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald),
                child: const Text('Confirm',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }
}
