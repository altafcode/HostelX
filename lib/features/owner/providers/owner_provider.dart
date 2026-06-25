import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/complaint_entity.dart';
import '../../../domain/entities/payout_entity.dart';
import '../../../core/utils/helpers.dart';
import '../../student/services/booking_service.dart';
import '../../student/services/hostel_service.dart';
import '../../../data/services/complaint_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/payout_service.dart';

class Tenant {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String occupation;
  final DateTime joinedDate;
  final String avatarUrl;
  final String hostelName;
  final String roomNumber;
  final String roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final double monthlyRent;
  final String paymentStatus; // Paid, Pending, Overdue
  final int contractDuration; // in months
  final double escalationPolicy; // percentage
  final double futureRent;
  final List<bool>
      paymentHistory; // true = paid, false = pending (for each month)

  Tenant({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.occupation,
    required this.joinedDate,
    required this.avatarUrl,
    required this.hostelName,
    required this.roomNumber,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    required this.monthlyRent,
    required this.paymentStatus,
    required this.contractDuration,
    required this.escalationPolicy,
    required this.futureRent,
    required this.paymentHistory,
  });

  static Tenant fromBooking(BookingEntity b, [UserEntity? user]) {
    final bookingDate = AppHelpers.parseDate(b.date);
    final displayName = _firstNotEmpty([user?.name, b.userName, 'Tenant']);
    final email = _firstNotEmpty([user?.email, b.userEmail]);
    final phone = _firstNotEmpty([user?.phone, b.userPhone]);
    final avatarName = Uri.encodeComponent(displayName);
    final paymentHistory =
        b.paymentHistory.isEmpty ? [b.status.isPaid] : b.paymentHistory;
    return Tenant(
      id: b.id,
      userId: b.userId,
      name: displayName,
      email: email,
      phone: phone,
      occupation: user?.occupation == null
          ? _formatOccupationName(b.userOccupation)
          : _formatOccupation(user?.occupation),
      joinedDate: bookingDate,
      avatarUrl: user?.avatar?.isNotEmpty == true
          ? user!.avatar!
          : 'https://ui-avatars.com/api/?name=$avatarName&background=random',
      hostelName: b.hostelName,
      roomNumber: b.roomNumber,
      roomType: b.roomType,
      checkIn: bookingDate,
      checkOut:
          DateTime(bookingDate.year + 1, bookingDate.month, bookingDate.day),
      monthlyRent: b.price.toDouble(),
      paymentStatus:
          b.status.isPaid && paymentHistory.last ? 'Paid' : 'Pending',
      contractDuration: 12,
      escalationPolicy: 10.0,
      futureRent: b.price * 1.1,
      paymentHistory: paymentHistory,
    );
  }

  static String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String _formatOccupation(Occupation? occupation) {
    switch (occupation) {
      case Occupation.student:
        return 'Student';
      case Occupation.jobHolder:
        return 'Job Holder';
      case Occupation.selfEmployed:
        return 'Self Employed';
      case Occupation.other:
        return 'Other';
      case null:
        return 'Not available';
    }
  }

  static String _formatOccupationName(String value) {
    switch (value) {
      case 'tenant':
        return 'Student';
      case 'jobHolder':
        return 'Job Holder';
      case 'selfEmployed':
        return 'Self Employed';
      case 'other':
        return 'Other';
      default:
        return value.trim().isEmpty ? 'Not available' : value;
    }
  }
}

class Complaint {
  final String id;
  final String title;
  final String description;
  final String by; // e.g. Tenant Name or Owner
  final String against; // e.g. Hostel or Tenant Name
  final String status; // Open, Resolved, Under Review
  final String type; // Received, Filed
  final DateTime date;
  String? ownerResponse;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.by,
    required this.against,
    required this.status,
    required this.type,
    required this.date,
    this.ownerResponse,
  });

  static Complaint fromEntity(ComplaintEntity e) {
    return Complaint(
      id: e.id,
      title: e.title,
      description: e.description,
      by: e.byUserName,
      against: e.againstName,
      status: e.status,
      type: e.type,
      date: e.createdAt,
    );
  }
}

class Payout {
  final String id;
  final DateTime date;
  final double amount;
  final String status;
  final List<String> hostelNames;
  final String? transferId;

  Payout({
    required this.id,
    required this.date,
    required this.amount,
    required this.status,
    this.hostelNames = const [],
    this.transferId,
  });

  static Payout fromEntity(PayoutEntity entity) {
    return Payout(
      id: entity.id,
      date: entity.createdAt,
      amount: entity.netAmount,
      status: entity.status == 'released' || entity.status == 'paid'
          ? 'Paid'
          : entity.status,
      hostelNames: entity.hostelNames,
      transferId: entity.transferId,
    );
  }
}

class Review {
  final String id;
  final String hostelId;
  final String name;
  final String avatarUrl;
  final double rating;
  final String text;
  final String date;
  String? ownerReply;

  Review({
    required this.id,
    required this.hostelId,
    required this.name,
    required this.avatarUrl,
    required this.rating,
    required this.text,
    required this.date,
    this.ownerReply,
  });
}

class OwnerProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final HostelService _hostelService = HostelService();
  final BookingService _bookingService = BookingService();
  final ComplaintService _complaintService = ComplaintService();
  final PayoutService _payoutService = PayoutService();

  bool isLoading = false;
  double commissionRate = 0.10;
  List<Tenant> tenants = [];
  List<Complaint> complaints = [];
  List<Payout> payouts = [];
  List<Review> reviews = [];
  StreamSubscription? _bookingsSub;
  StreamSubscription? _payoutsSub;
  StreamSubscription? _settingsSub;

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _payoutsSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }

  List<double> getGrossRentForYear(int year) {
    final result = List.filled(12, 0.0);
    for (final t in tenants) {
      if (t.paymentStatus != 'Paid') continue;

      if (t.paymentHistory.isEmpty) {
        if (t.joinedDate.year == year) {
          result[t.joinedDate.month - 1] += t.monthlyRent;
        }
        continue;
      }

      for (var i = 0; i < t.paymentHistory.length; i += 1) {
        if (!t.paymentHistory[i]) continue;
        final paymentMonth =
            DateTime(t.joinedDate.year, t.joinedDate.month + i);
        if (paymentMonth.year == year) {
          result[paymentMonth.month - 1] += t.monthlyRent;
        }
      }
    }
    return result;
  }

  List<int> getBookingsForYear(int year) {
    final result = List.filled(12, 0);
    for (final t in tenants) {
      if (t.joinedDate.year == year) {
        result[t.joinedDate.month - 1] += 1;
      }
    }
    return result;
  }

  double get totalGrossEarnings {
    double total = 0;
    for (final t in tenants) {
      if (t.paymentStatus == 'Paid') {
        total += t.monthlyRent;
      }
    }
    return total;
  }

  double get totalNetEarnings => totalGrossEarnings * (1 - commissionRate);
  double get totalCommissionDeducted => totalGrossEarnings * commissionRate;
  double get totalReceivedPayouts =>
      payouts.fold(0.0, (total, payout) => total + payout.amount);

  double getMonthlyNetEarnings(int year, int monthIndex) {
    return getGrossRentForYear(year)[monthIndex] * (1 - commissionRate);
  }

  List<double> getReceivedPayoutsForYear(int year) {
    final result = List.filled(12, 0.0);
    for (final payout in payouts) {
      if (payout.date.year == year &&
          (payout.status == 'Paid' || payout.status == 'Received')) {
        result[payout.date.month - 1] += payout.amount;
      }
    }
    return result;
  }

  Map<String, double> getHostelBreakdownForMonth(int year, int monthIndex) {
    final breakdown = <String, double>{};
    for (final t in tenants) {
      if (t.paymentStatus != 'Paid') continue;

      final hasPaymentForMonth = t.paymentHistory.isEmpty
          ? t.joinedDate.year == year && (t.joinedDate.month - 1) == monthIndex
          : t.paymentHistory.asMap().entries.any((entry) {
              if (!entry.value) return false;
              final paymentMonth = DateTime(
                t.joinedDate.year,
                t.joinedDate.month + entry.key,
              );
              return paymentMonth.year == year &&
                  (paymentMonth.month - 1) == monthIndex;
            });

      if (hasPaymentForMonth) {
        breakdown[t.hostelName] =
            (breakdown[t.hostelName] ?? 0) + t.monthlyRent;
      }
    }
    return breakdown;
  }

  Future<void> loadOwnerData(String ownerId) async {
    isLoading = true;
    notifyListeners();

    try {
      _listenSettings();
      final hostels = await _hostelService.fetchHostelsByOwner(ownerId);
      final hostelIds = hostels.map((h) => h.id).toList();

      if (hostelIds.isNotEmpty) {
        final bookingEntities =
            await _bookingService.fetchBookings(hostelIds: hostelIds);

        // A tenant is any booking that is Approved or Paid (Confirmed)
        final activeTenantsBookings = bookingEntities.where((b) {
          return b.status == BookingStatus.approved ||
              b.status == BookingStatus.paymentPending ||
              b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.completed;
        }).toList();

        List<Tenant> loadedTenants = [];
        for (var b in activeTenantsBookings) {
          final user = await _fetchUserForBooking(b);
          loadedTenants.add(Tenant.fromBooking(b, user));
        }
        tenants = loadedTenants;
        _listenBookings(hostelIds);
      } else {
        tenants = [];
        _bookingsSub?.cancel();
      }

      final complaintEntities =
          await _complaintService.fetchComplaintsByOwnerId(ownerId);
      complaints =
          complaintEntities.map((e) => Complaint.fromEntity(e)).toList();

      _listenPayouts(ownerId);

      final allReviews = await _hostelService.fetchReviews();
      reviews = allReviews
          .where((r) => hostelIds.contains(r.hostelId))
          .map((r) => Review(
                id: r.id,
                hostelId: r.hostelId,
                name: r.userName,
                avatarUrl:
                    'https://ui-avatars.com/api/?name=${r.userName}&background=random',
                rating: r.rating,
                text: r.comment,
                date: r.date,
                ownerReply: r.ownerReply,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error loading owner data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _listenBookings(List<String> hostelIds) {
    _bookingsSub?.cancel();
    _bookingsSub = _db.collection('bookings').snapshots().listen((snap) async {
      final activeBookings = snap.docs
          .map((doc) => BookingEntity.fromMap(doc.id, doc.data()))
          .where((booking) => hostelIds.contains(booking.hostelId))
          .where((booking) {
        return booking.status == BookingStatus.approved ||
            booking.status == BookingStatus.paymentPending ||
            booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.completed;
      }).toList();

      List<Tenant> newTenants = [];
      for (var b in activeBookings) {
        final user = await _fetchUserForBooking(b);
        newTenants.add(Tenant.fromBooking(b, user));
      }
      tenants = newTenants;
      notifyListeners();
    });
  }

  Future<UserEntity?> _fetchUserForBooking(BookingEntity booking) async {
    try {
      if (booking.userId.isNotEmpty) {
        final userDoc = await _db.collection('users').doc(booking.userId).get();
        final data = userDoc.data();
        if (userDoc.exists && data != null) {
          return UserEntity.fromMap(booking.userId, data);
        }
      }

      if (booking.userEmail.isNotEmpty) {
        final byEmail = await _db
            .collection('users')
            .where('email', isEqualTo: booking.userEmail)
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          final doc = byEmail.docs.first;
          return UserEntity.fromMap(doc.id, doc.data());
        }
      }

      if (booking.userName.isNotEmpty) {
        final byName = await _db
            .collection('users')
            .where('name', isEqualTo: booking.userName)
            .limit(1)
            .get();
        if (byName.docs.isNotEmpty) {
          final doc = byName.docs.first;
          return UserEntity.fromMap(doc.id, doc.data());
        }
      }
    } catch (e) {
      debugPrint('Unable to load tenant profile ${booking.userId}: $e');
    }

    return null;
  }

  void _listenPayouts(String ownerId) {
    _payoutsSub?.cancel();
    _payoutsSub = _payoutService.watchOwnerPayouts(ownerId).listen((items) {
      payouts = items.map((item) => Payout.fromEntity(item)).toList();
      notifyListeners();
    });
  }

  void _listenSettings() {
    _settingsSub?.cancel();
    _settingsSub = _db
        .collection('app_settings')
        .doc('platform')
        .snapshots()
        .listen((doc) {
      final value = doc.data()?['commissionRate'];
      if (value is num) {
        commissionRate = value.toDouble();
        notifyListeners();
      }
    });
  }

  Future<void> addOwnerReply(String reviewId, String reply) async {
    final idx = reviews.indexWhere((r) => r.id == reviewId);
    if (idx != -1) {
      await _db.collection('reviews').doc(reviewId).update({
        'ownerReply': reply,
        'ownerReplyAt': FieldValue.serverTimestamp(),
      });
      reviews[idx].ownerReply = reply;
      notifyListeners();
    }
  }

  void respondToComplaint(String complaintId, String response) async {
    final idx = complaints.indexWhere((c) => c.id == complaintId);
    if (idx != -1) {
      await _complaintService.updateComplaintStatus(complaintId, 'Resolved');
      complaints[idx].ownerResponse = response;
      notifyListeners();
    }
  }

  void markTenantPaid(String tenantId) async {
    final idx = tenants.indexWhere((t) => t.id == tenantId);
    if (idx != -1) {
      final tenant = tenants[idx];
      await _bookingService.updateStatus(tenantId, BookingStatus.confirmed);

      await NotificationService().sendNotification(
        userId: tenant.userId,
        title: 'Booking Approved',
        body: 'Your booking at ${tenant.hostelName} has been approved.',
        type: 'booking',
      );

      // t.paymentStatus = 'Paid'; // local update would be better than reload
      notifyListeners();
    }
  }

  Future<void> endTenantContractEarly(String tenantId) async {
    final idx = tenants.indexWhere((t) => t.id == tenantId);
    if (idx == -1) return;

    final tenant = tenants[idx];
    await _db.collection('bookings').doc(tenant.id).update({
      'status': BookingStatus.cancelled.firestoreValue,
      'contractEndedEarly': true,
      'contractEndedAt': FieldValue.serverTimestamp(),
      'cancelledBy': 'owner',
      'refundNeeded': false,
    });

    tenants.removeAt(idx);
    notifyListeners();

    await NotificationService().sendNotification(
      userId: tenant.userId,
      title: 'Contract Ended',
      body:
          'Your contract at ${tenant.hostelName}, room ${tenant.roomNumber}, has been ended by the owner.',
      type: 'booking',
    );
  }

  void addTenant(Tenant tenant) {
    tenants.add(tenant);
    notifyListeners();
  }
}
