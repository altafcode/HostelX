import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking/booking_card.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final bookings = user == null
        ? <BookingEntity>[]
        : context
            .watch<BookingProvider>()
            .bookingsForUser(user.id)
            .where((booking) => booking.status.isPaid)
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment History',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: bookings.isEmpty
          ? const Center(
              child: Text('No paid bookings yet.',
                  style: TextStyle(color: AppColors.textMuted)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => BookingCard(booking: bookings[index]),
            ),
    );
  }
}
