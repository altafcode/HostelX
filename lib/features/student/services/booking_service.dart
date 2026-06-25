import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/notification_service.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const double defaultCommissionRate = 0.10;

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

  /// Fetch bookings — optionally filter by studentId or hostelIds (for owner)
  Future<List<BookingEntity>> fetchBookings({
    String? userId, // tenant filter
    List<String>? hostelIds, // owner filter
  }) async {
    Query query = _db.collection('bookings');

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    final snap = await query.get();
    final bookings = snap.docs
        .map((doc) =>
            BookingEntity.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    final visibleBookings =
        bookings.where((b) => b.status != BookingStatus.cancelled).toList();
    final dedupedBookings = _dedupeActiveBookings(visibleBookings);

    // Filter by hostelIds if provided (owner view)
    if (hostelIds != null && hostelIds.isNotEmpty) {
      return dedupedBookings
          .where((b) => hostelIds.contains(b.hostelId))
          .toList();
    }

    return dedupedBookings;
  }

  Stream<List<BookingEntity>> watchBookings({
    String? userId,
    List<String>? hostelIds,
  }) {
    Query query = _db.collection('bookings');

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots().map((snap) {
      final bookings = snap.docs
          .map((doc) => BookingEntity.fromMap(
              doc.id, doc.data() as Map<String, dynamic>))
          .where((booking) => booking.status != BookingStatus.cancelled)
          .toList();

      final dedupedBookings = _dedupeActiveBookings(bookings);
      if (hostelIds != null && hostelIds.isNotEmpty) {
        return dedupedBookings
            .where((booking) => hostelIds.contains(booking.hostelId))
            .toList();
      }

      return dedupedBookings;
    });
  }

  Future<BookingEntity?> findActiveBooking({
    required String userId,
    required String hostelId,
  }) async {
    final snap = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snap.docs) {
      final booking = BookingEntity.fromMap(doc.id, doc.data());
      if (booking.hostelId == hostelId && booking.status.isActive) {
        return booking;
      }
    }

    return null;
  }

  /// Create a new booking
  Future<BookingEntity> createBooking({
    required String hostelId,
    required String hostelName,
    required String ownerId,
    required String userId,
    required String userName,
    String userEmail = '',
    String userPhone = '',
    String userOccupation = '',
    required String roomNumber,
    String roomType = 'Standard Room',
    required int price,
    String bedNumber = '',
    String? hostelImage,
  }) async {
    final existingBooking = await findActiveBooking(
      userId: userId,
      hostelId: hostelId,
    );
    if (existingBooking != null) return existingBooking;

    final ref = _db.collection('bookings').doc();
    final now = DateTime.now();

    final booking = BookingEntity(
      id: ref.id,
      hostelId: hostelId,
      hostelName: hostelName,
      ownerId: ownerId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      userOccupation: userOccupation,
      roomNumber: roomNumber,
      roomType: roomType,
      bedNumber: bedNumber,
      status: BookingStatus.pending,
      date: AppHelpers.formatDate(now),
      price: price,
      payoutStatus: 'pending',
      hostelImage: hostelImage,
    );

    await ref.set(booking.toMap());
    return booking;
  }

  /// Update booking status (owner/admin workflows).
  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status.firestoreValue,
    });
  }

  Future<void> approveBooking(
    String bookingId, {
    String? roomNumber,
    String? roomType,
  }) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.paymentPending.firestoreValue,
      if (roomNumber != null && roomNumber.isNotEmpty) 'roomNumber': roomNumber,
      if (roomType != null && roomType.isNotEmpty) 'roomType': roomType,
    });
  }

  Future<void> rejectBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.rejected.firestoreValue,
    });
  }

  Future<void> markPaymentConfirmed({
    required BookingEntity booking,
    double? commissionRate,
  }) async {
    final effectiveCommissionRate =
        commissionRate ?? await getCurrentCommissionRate();
    final commission = booking.price * effectiveCommissionRate;
    final ownerPayout = booking.price - commission;
    await _db.collection('bookings').doc(booking.id).update({
      'status': BookingStatus.confirmed.firestoreValue,
      'paymentDate': FieldValue.serverTimestamp(),
      'commission': commission,
      'ownerPayout': ownerPayout,
      'payoutStatus': 'pending',
    });
  }

  Future<double> getCurrentCommissionRate() async {
    try {
      final doc = await _db.collection('app_settings').doc('platform').get();
      final value = doc.data()?['commissionRate'];
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultCommissionRate;
      }
    } catch (_) {
      return defaultCommissionRate;
    }
    return defaultCommissionRate;
  }

  Future<void> cancelBooking({
    required BookingEntity booking,
    required String cancelledBy,
  }) async {
    final refundNeeded = booking.status.isPaid || booking.paymentDate != null;
    await _db.collection('bookings').doc(booking.id).update({
      'status': BookingStatus.cancelled.firestoreValue,
      'cancelledBy': cancelledBy,
      'cancelledAt': FieldValue.serverTimestamp(),
      'refundNeeded': refundNeeded,
    });

    if (refundNeeded) {
      await NotificationService().sendNotificationToRole(
        role: 'admin',
        title: 'Refund Needed',
        body:
            '${booking.userName} cancelled a paid booking at ${booking.hostelName}. Please process a manual refund.',
        type: 'refund',
      );
    }
  }

  Future<void> markPayoutPaid({
    required List<String> bookingIds,
    required String payoutId,
  }) async {
    final batch = _db.batch();
    for (final bookingId in bookingIds) {
      batch.update(_db.collection('bookings').doc(bookingId), {
        'payoutStatus': 'paid',
        'payoutId': payoutId,
      });
    }
    await batch.commit();
  }
}
