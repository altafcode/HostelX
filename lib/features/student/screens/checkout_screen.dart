import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/stripe_service.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking/checkout_summary_card.dart';
import 'stripe_checkout_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final HostelEntity hostel;
  final String roomType;
  final String roomNumber;
  final int price;
  final BookingEntity? booking;

  const CheckoutScreen({
    super.key,
    required this.hostel,
    required this.roomType,
    required this.roomNumber,
    required this.price,
    this.booking,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isSuccess = false;
  String _selectedPayment = 'card';
  bool _isProcessingPayment = false;

  Future<void> _confirmBooking() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isProcessingPayment = true);

    try {
      if (widget.booking == null) {
        final bookingCreated = await _createBooking(user);
        if (!bookingCreated) return;
        if (mounted) setState(() => _isSuccess = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRouter.tenantHome, (_) => false);
        }
        return;
      }

      final booking = widget.booking!;
      if (booking.status != BookingStatus.approved &&
          booking.status != BookingStatus.paymentPending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Payment is available only after owner approval.')),
        );
        return;
      }

      final bookingProvider = context.read<BookingProvider>();
      final paymentSuccess = await _processPayment(user);
      if (paymentSuccess == true) {
        await bookingProvider.confirmPayment(booking);
        await NotificationService().sendNotification(
          userId: user.id,
          title: 'Booking Confirmed',
          body: 'Your booking at ${widget.hostel.name} has been confirmed.',
          type: 'booking',
        );
        await NotificationService().sendNotification(
          userId: widget.hostel.ownerId,
          title: 'Payment Received',
          body:
              '${user.name} paid Rs. ${AppHelpers.formatPrice(widget.price)} for ${widget.hostel.name}.',
          type: 'payment',
        );
        if (mounted) setState(() => _isSuccess = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRouter.tenantHome, (_) => false);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled or failed.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Future<bool> _processPayment(UserEntity user) async {
    if (_selectedPayment == 'card') {
      final stripe = StripeService();
      final reference = 'HOSTELX_${DateTime.now().millisecondsSinceEpoch}';
      final session = await stripe.createCheckoutSession(
        amount: widget.price,
        hostelName: widget.hostel.name,
        roomNumber: widget.roomNumber,
        userId: user.id,
        userName: user.name,
        bookingReference: reference,
      );

      if (!mounted) return false;
      final result = await Navigator.push<StripeCheckoutResult>(
        context,
        MaterialPageRoute(
          builder: (context) => StripeCheckoutWebViewScreen(
            checkoutUrl: session.checkoutUrl,
          ),
        ),
      );

      if (result?.completed != true) {
        return false;
      }

      final verifiedSession = await stripe.retrieveCheckoutSession(
        result?.sessionId ?? session.id,
      );

      if (verifiedSession.paymentStatus != 'paid') {
        throw Exception('Stripe payment was not completed.');
      }

      return true;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      final label = _selectedPayment == 'easypaisa'
          ? AppStrings.easypaisa
          : AppStrings.jazzcash;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label demo payment accepted.')),
      );
    }
    return true;
  }

  Future<bool> _createBooking(UserEntity user) async {
    final bookingProvider = context.read<BookingProvider>();
    final existingBooking = await bookingProvider.findActiveBooking(
      userId: user.id,
      hostelId: widget.hostel.id,
    );
    if (existingBooking != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'You already have an active booking request for this hostel.')),
        );
      }
      return false;
    }

    final booking = await bookingProvider.createBooking(
      hostelId: widget.hostel.id,
      hostelName: widget.hostel.name,
      ownerId: widget.hostel.ownerId,
      user: user,
      roomNumber: widget.roomNumber,
      roomType: widget.roomType,
      price: widget.price,
      hostelImage:
          widget.hostel.images.isNotEmpty ? widget.hostel.images[0] : null,
    );

    if (booking == null) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _SuccessOverlay(
        hostelName: widget.hostel.name,
        isPaymentMode: widget.booking != null,
      );
    }

    final isBooking = context.watch<BookingProvider>().isBooking;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Summary',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  CheckoutSummaryCard(
                    hostel: widget.hostel,
                    roomType: widget.roomType,
                    roomNumber: widget.roomNumber,
                    price: widget.price,
                  ),
                  const SizedBox(height: 24),
                  const Text('Tenant Details',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  const _UserCard(),
                  const SizedBox(height: 24),
                  if (widget.booking != null) ...[
                    const Text(AppStrings.selectPaymentMethod,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _PaymentSelector(
                      selected: _selectedPayment,
                      onChanged: (val) =>
                          setState(() => _selectedPayment = val),
                    ),
                  ] else
                    const _ApprovalNote(),
                ],
              ),
            ),
          ),
          _BottomBar(
            price: widget.price,
            isLoading: isBooking || _isProcessingPayment,
            onConfirm: _confirmBooking,
            selectedPayment: _selectedPayment,
            isPaymentMode: widget.booking != null,
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded,
                color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Tenant',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(user?.email ?? '',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.emerald, size: 20),
        ],
      ),
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PaymentSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final note = selected == 'card'
        ? AppStrings.cardPaymentNote
        : AppStrings.paymentPromptNote;

    return Column(
      children: [
        _buildPaymentCard(
          key: 'easypaisa',
          title: AppStrings.easypaisa,
          subtitle: AppStrings.easypaisaSubtitle,
          icon: Icons.phone_android_rounded,
          iconColor: AppColors.emerald,
        ),
        const SizedBox(height: 12),
        _buildPaymentCard(
          key: 'jazzcash',
          title: AppStrings.jazzcash,
          subtitle: AppStrings.jazzcashSubtitle,
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.accent,
        ),
        const SizedBox(height: 12),
        _buildPaymentCard(
          key: 'card',
          title: AppStrings.cardPayment,
          subtitle: AppStrings.cardPaymentSubtitle,
          icon: Icons.credit_card_rounded,
          iconColor: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  note,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = selected == key;
    return GestureDetector(
      onTap: () => onChanged(key),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ApprovalNote extends StatelessWidget {
  const _ApprovalNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.paymentLockedUntilApproved,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int price;
  final bool isLoading;
  final VoidCallback onConfirm;
  final String selectedPayment;
  final bool isPaymentMode;

  const _BottomBar({
    required this.price,
    required this.isLoading,
    required this.onConfirm,
    required this.selectedPayment,
    required this.isPaymentMode,
  });

  @override
  Widget build(BuildContext context) {
    final String label = isPaymentMode
        ? AppStrings.confirmAndPay
        : AppStrings.submitBookingRequest;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grand Total',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text('Rs. ${AppHelpers.formatPrice(price)}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: PrimaryButton(
              label: label,
              isLoading: isLoading,
              onPressed: onConfirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  final String hostelName;
  final bool isPaymentMode;
  const _SuccessOverlay({
    required this.hostelName,
    required this.isPaymentMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                    color: AppColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    size: 60, color: AppColors.emerald),
              ),
              const SizedBox(height: 32),
              Text(
                  isPaymentMode
                      ? AppStrings.bookingConfirmed
                      : AppStrings.bookingSuccess,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(
                isPaymentMode
                    ? 'Your booking for $hostelName has been confirmed.'
                    : 'Your booking request for $hostelName has been successfully sent to the owner.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 16),
              const Text('Redirecting to home...',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
