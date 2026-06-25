import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../data/services/notification_service.dart';

class StudentProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  bool _isBooking = false;
  String? _error;

  bool get isBooking => _isBooking;
  String? get error => _error;

  Future<BookingEntity?> createBooking({
    required String hostelId,
    required String hostelName,
    required UserEntity user,
    required String roomNumber,
    required String roomType,
    required int price,
    required String ownerId,
    String? hostelImage,
  }) async {
    _isBooking = true;
    _error = null;
    notifyListeners();

    try {
      final existingBooking = await _bookingService.findActiveBooking(
        userId: user.id,
        hostelId: hostelId,
      );
      if (existingBooking != null) return existingBooking;

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
        price: price,
        hostelImage: hostelImage,
      );

      await NotificationService().sendNotification(
        userId: ownerId,
        title: 'New Booking Request',
        body: '${user.name} has requested to book $roomNumber in $hostelName.',
        type: 'booking',
      );

      return booking;
    } catch (e) {
      _error = 'Booking failed. Please try again.';
      return null;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }
}
