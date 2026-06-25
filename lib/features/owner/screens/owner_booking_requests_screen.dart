import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../providers/auth_provider.dart';
import '../../student/providers/booking_provider.dart';
import '../../student/providers/hostel_provider.dart';
import '../widgets/request_card.dart';

class OwnerBookingRequestsScreen extends StatefulWidget {
  const OwnerBookingRequestsScreen({super.key});

  @override
  State<OwnerBookingRequestsScreen> createState() =>
      _OwnerBookingRequestsScreenState();
}

class _OwnerBookingRequestsScreenState
    extends State<OwnerBookingRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final hostels = context
        .watch<HostelProvider>()
        .allHostels
        .where((h) => h.ownerName == user?.name || h.ownerId == user?.id)
        .map((h) => h.id)
        .toList();
    final bookings =
        context.watch<BookingProvider>().bookingsForOwnerHostels(hostels);

    // Only show pending requests. Approved or Rejected bookings disappear from this screen.
    final filtered =
        bookings.where((b) => b.status == BookingStatus.pending).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Booking Requests',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          if (hostels.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                      'You have no active hostels to receive requests for.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            )
          else
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checklist_rtl_rounded,
                              size: 64, color: AppColors.borderLight),
                          SizedBox(height: 16),
                          Text('No new requests found.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                          Text('Approved or rejected requests are moved.',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => RequestCard(booking: filtered[i]),
                    ),
            ),
        ]),
      ),
    );
  }
}
