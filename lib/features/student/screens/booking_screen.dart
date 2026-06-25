import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/app_tab_bar.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking/booking_card.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String _filter = 'All';
  static const _tabs = ['All', 'Pending', 'Approved', 'History'];

  List<BookingEntity> _filtered(List<BookingEntity> bookings) {
    switch (_filter) {
      case 'Pending':
        return bookings
            .where((b) => b.status == BookingStatus.pending)
            .toList();
      case 'Approved':
        return bookings
            .where((b) =>
                b.status == BookingStatus.approved ||
                b.status == BookingStatus.paymentPending)
            .toList();
      case 'History':
        return bookings
            .where((b) =>
                b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.rejected)
            .toList();
      default:
        return bookings
            .where((b) => b.status != BookingStatus.cancelled)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<BookingProvider>();
    final bookings = _filtered(provider.bookingsForUser(user?.id ?? ''));

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              AppStrings.myBookings,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
          ),
          AppTabBar(
            tabs: _tabs,
            selected: _filter,
            onChanged: (t) => setState(() => _filter = t),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bookings.isEmpty
                ? const Center(
                    child: Text('No bookings found.',
                        style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => BookingCard(booking: bookings[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
