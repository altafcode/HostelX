import 'dart:async';

import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../data/services/notification_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingEntity> _bookings = [];
  bool _isLoading = false;
  bool _isBooking = false;
  String? _error;
  StreamSubscription<List<BookingEntity>>? _bookingsSub;
  String? _watchUserId;
  List<String>? _watchHostelIds;

  BookingProvider() {
    loadBookings();
  }

  List<BookingEntity> get bookings => _bookings;
  bool get isLoading => _isLoading;
  bool get isBooking => _isBooking;
  String? get error => _error;

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  List<BookingEntity> _dedupeActiveBookings(List<BookingEntity> bookings) {
    final seenKeys = <String>{};
    final result = <BookingEntity>[];

    for (final booking in bookings) {
      final key = booking.status.isActive
          ? 'active_${booking.userId}_${booking.hostelId}'
          : '${booking.status.name}_${booking.userId}_${booking.hostelId}';
      if (seenKeys.contains(key)) continue;
      seenKeys.add(key);
      result.add(booking);
    }

    return result;
  }

  List<BookingEntity> bookingsForUser(String userId) =>
      _dedupeActiveBookings(_bookings
          .where(
              (b) => b.userId == userId && b.status != BookingStatus.cancelled)
          .toList());

  List<BookingEntity> bookingsForOwnerHostels(List<String> hostelIds) =>
      _dedupeActiveBookings(_bookings
          .where((b) =>
              hostelIds.contains(b.hostelId) &&
              b.status != BookingStatus.cancelled)
          .toList());

  Future<void> loadBookings({String? userId, List<String>? hostelIds}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _bookingService.fetchBookings(
        userId: userId,
        hostelIds: hostelIds,
      );
    } catch (e) {
      _error = 'Failed to load bookings.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void watchBookings({String? userId, List<String>? hostelIds}) {
    final normalizedHostelIds = hostelIds == null
        ? null
        : (List<String>.from(hostelIds)..sort());

    final sameUser = _watchUserId == userId;
    final sameHostels = _listEquals(_watchHostelIds, normalizedHostelIds);
    if (_bookingsSub != null && sameUser && sameHostels) return;

    _bookingsSub?.cancel();
    _watchUserId = userId;
    _watchHostelIds = normalizedHostelIds;

    _isLoading = true;
    _error = null;
    notifyListeners();

    _bookingsSub = _bookingService
        .watchBookings(userId: userId, hostelIds: normalizedHostelIds)
        .listen((bookings) {
      _bookings = bookings;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      _error = 'Failed to listen for booking updates.';
      notifyListeners();
    });
  }

  void stopWatchingBookings({bool clearBookings = false}) {
    _bookingsSub?.cancel();
    _bookingsSub = null;
    _watchUserId = null;
    _watchHostelIds = null;
    _isLoading = false;
    if (clearBookings) _bookings = [];
    notifyListeners();
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<BookingEntity?> findActiveBooking({
    required String userId,
    required String hostelId,
  }) async {
    try {
      BookingEntity? localBooking;
      for (final booking in _bookings) {
        if (booking.userId == userId &&
            booking.hostelId == hostelId &&
            booking.status.isActive) {
          localBooking = booking;
          break;
        }
      }
      if (localBooking != null) return localBooking;

      final booking = await _bookingService.findActiveBooking(
        userId: userId,
        hostelId: hostelId,
      );
      if (booking != null && !_bookings.any((b) => b.id == booking.id)) {
        _bookings = [booking, ..._bookings];
        notifyListeners();
      }
      return booking;
    } catch (e) {
      _error = 'Failed to check existing bookings.';
      notifyListeners();
      return null;
    }
  }

  Future<BookingEntity?> createBooking({
    required String hostelId,
    required String hostelName,
    required String ownerId,
    required UserEntity user,
    required String roomNumber,
    required String roomType,
    required int price,
    String bedNumber = '',
    String? hostelImage,
  }) async {
    _isBooking = true;
    _error = null;
    notifyListeners();
    try {
      final booking = await _bookingService.createBooking(
        hostelId: hostelId,
        hostelName: hostelName,
        ownerId: ownerId,
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userPhone: user.phone ?? '',
        userOccupation: user.occupation?.name ?? '',
        roomNumber: roomNumber,
        roomType: roomType,
        bedNumber: bedNumber,
        price: price,
        hostelImage: hostelImage,
      );
      if (!_bookings.any((b) => b.id == booking.id)) {
        _bookings = [booking, ..._bookings];
      }
      await NotificationService().sendNotification(
          userId: ownerId,
          title: 'New Booking Request',
          body: '${user.name} requested a booking for $hostelName.',
          type: 'booking');
      return booking;
    } catch (e) {
      _error = 'Booking failed. Please try again.';
      return null;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    try {
      await _bookingService.updateStatus(bookingId, status);
      _bookings = _bookings
          .map((b) => b.id == bookingId ? b.copyWith(status: status) : b)
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update booking status.';
      notifyListeners();
    }
  }

  Future<void> approveBooking(BookingEntity booking) async {
    try {
      await _bookingService.approveBooking(
        booking.id,
        roomNumber: booking.roomNumber,
        roomType: booking.roomType,
      );
      _bookings = _bookings
          .map((b) => b.id == booking.id
              ? b.copyWith(
                  status: BookingStatus.paymentPending,
                  roomNumber: booking.roomNumber,
                  roomType: booking.roomType,
                )
              : b)
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to approve booking.';
      notifyListeners();
    }
  }

  Future<void> rejectBooking(BookingEntity booking) async {
    try {
      await _bookingService.rejectBooking(booking.id);
      _bookings = _bookings
          .map((b) => b.id == booking.id
              ? b.copyWith(status: BookingStatus.rejected)
              : b)
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reject booking.';
      notifyListeners();
    }
  }

  Future<void> confirmPayment(BookingEntity booking) async {
    try {
      final commissionRate = await _bookingService.getCurrentCommissionRate();
      await _bookingService.markPaymentConfirmed(
        booking: booking,
        commissionRate: commissionRate,
      );
      _bookings = _bookings
          .map((b) => b.id == booking.id
              ? b.copyWith(
                  status: BookingStatus.confirmed,
                  paymentDate: DateTime.now(),
                  commission: b.price * commissionRate,
                  ownerPayout: b.price * (1 - commissionRate),
                  payoutStatus: 'pending',
                )
              : b)
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to confirm payment.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelBooking(BookingEntity booking, String cancelledBy) async {
    try {
      await _bookingService.cancelBooking(
        booking: booking,
        cancelledBy: cancelledBy,
      );
      _bookings = _bookings.where((b) => b.id != booking.id).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to cancel booking.';
      notifyListeners();
    }
  }
}
