import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/complaint_entity.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/payout_entity.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/student/services/hostel_service.dart';
import '../../../features/student/services/booking_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/payout_service.dart';

typedef BookingAdminModel = BookingEntity;

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final HostelService _hostelService = HostelService();
  final BookingService _bookingService = BookingService();
  final PayoutService _payoutService = PayoutService();

  double commissionRate = 0.10;
  bool allowNewListings = true;
  bool maintenanceMode = false;
  bool isLoading = false;

  List<UserEntity> users = [];
  List<HostelEntity> hostels = [];
  List<BookingEntity> bookings = [];
  List<ComplaintEntity> complaints = [];
  List<PayoutEntity> payouts = [];

  StreamSubscription? _usersSub;
  StreamSubscription? _hostelsSub;
  StreamSubscription? _bookingsSub;
  StreamSubscription? _complaintsSub;
  StreamSubscription? _payoutsSub;
  StreamSubscription? _settingsSub;

  @override
  void dispose() {
    _usersSub?.cancel();
    _hostelsSub?.cancel();
    _bookingsSub?.cancel();
    _complaintsSub?.cancel();
    _payoutsSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }

  List<HostelEntity> get pendingHostels =>
      hostels.where((h) => h.approvalStatus == ApprovalStatus.pending).toList();

  bool _isActiveStatus(BookingStatus status) {
    return status.isActive;
  }

  List<BookingEntity> _dedupeActiveBookings(List<BookingEntity> source) {
    final seenActiveKeys = <String>{};
    final result = <BookingEntity>[];

    for (final booking in source) {
      final key = '${booking.userId}_${booking.hostelId}';
      if (_isActiveStatus(booking.status)) {
        if (seenActiveKeys.contains(key)) continue;
        seenActiveKeys.add(key);
      }
      result.add(booking);
    }

    return result;
  }

  // Revenue computations
  double get totalEarnings => bookings
      .where((b) => b.status == BookingStatus.confirmed)
      .fold(0.0, (acc, b) => acc + b.price);
  double get totalCommission => totalEarnings * commissionRate;
  double get totalReleasedPayouts =>
      payouts.fold(0.0, (acc, p) => acc + p.netAmount);

  int _parseYear(String dateStr) {
    return AppHelpers.parseDate(dateStr).year;
  }

  int _parseMonthIndex(String dateStr) {
    return AppHelpers.parseDate(dateStr).month - 1;
  }

  List<double> getMonthlyCommissionForYear(int year) {
    final result = List.filled(12, 0.0);
    for (final b in bookings) {
      if (b.status == BookingStatus.confirmed && _parseYear(b.date) == year) {
        final monthIdx = _parseMonthIndex(b.date);
        result[monthIdx] += calculateCommission(b.price);
      }
    }
    return result;
  }

  List<double> getMonthlyReleasedPayoutsForYear(int year) {
    final result = List.filled(12, 0.0);
    for (final payout in payouts) {
      if (payout.year == year &&
          (payout.status == 'paid' || payout.status == 'released')) {
        result[payout.month - 1] += payout.netAmount;
      }
    }
    return result;
  }

  List<int> getMonthlyBookingsForYear(int year) {
    final result = List.filled(12, 0);
    for (final b in bookings) {
      if (b.status != BookingStatus.cancelled && _parseYear(b.date) == year) {
        final monthIdx = _parseMonthIndex(b.date);
        result[monthIdx] += 1;
      }
    }
    return result;
  }

  /// Listen to all admin data in real-time
  void startListening() {
    _listenUsers();
    _listenHostels();
    _listenBookings();
    _listenComplaints();
    _listenPayouts();
    _listenSettings();
  }

  void _listenSettings() {
    _settingsSub?.cancel();
    _settingsSub =
        _db.collection('app_settings').doc('platform').snapshots().listen((doc) {
      final data = doc.data();
      if (data == null) return;
      commissionRate = (data['commissionRate'] ?? commissionRate).toDouble();
      allowNewListings = data['allowNewListings'] ?? allowNewListings;
      maintenanceMode = data['maintenanceMode'] ?? maintenanceMode;
      notifyListeners();
    });
  }

  void _listenUsers() {
    _usersSub?.cancel();
    _usersSub = _db.collection('users').snapshots().listen((snap) {
      users = snap.docs
          .map((doc) => UserEntity.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    });
  }

  void _listenHostels() {
    _hostelsSub?.cancel();
    _hostelsSub = _db.collection('hostels').snapshots().listen((snap) {
      hostels = snap.docs
          .map((doc) => HostelEntity.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    });
  }

  void _listenBookings() {
    _bookingsSub?.cancel();
    _bookingsSub = _db.collection('bookings').snapshots().listen((snap) {
      bookings = _dedupeActiveBookings(snap.docs
          .map((doc) => BookingEntity.fromMap(doc.id, doc.data()))
          .toList());
      notifyListeners();
    });
  }

  void _listenComplaints() {
    _complaintsSub?.cancel();
    _complaintsSub = _db.collection('complaints').snapshots().listen((snap) {
      complaints = snap.docs
          .map((doc) => ComplaintEntity.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    });
  }

  void _listenPayouts() {
    _payoutsSub?.cancel();
    _payoutsSub = _payoutService.watchPayouts().listen((items) {
      payouts = items;
      notifyListeners();
    });
  }

  /// Load all admin data (kept for manual refresh if needed)
  Future<void> loadAdminData() async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadUsers(),
        _loadHostels(),
        _loadBookings(),
        _loadComplaints(),
        _loadPayouts(),
      ]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUsers() async {
    final snap = await _db.collection('users').get();
    users = snap.docs
        .map((doc) => UserEntity.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> _loadHostels() async {
    final snap = await _db.collection('hostels').get();
    hostels = snap.docs
        .map((doc) => HostelEntity.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> _loadBookings() async {
    bookings = _dedupeActiveBookings(await _bookingService.fetchBookings());
  }

  Future<void> _loadComplaints() async {
    final snap = await _db.collection('complaints').get();
    complaints = snap.docs
        .map((doc) => ComplaintEntity.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> _loadPayouts() async {
    final snap = await _db.collection('payouts').get();
    payouts = snap.docs
        .map((doc) => PayoutEntity.fromMap(doc.id, doc.data()))
        .toList();
  }

  HostelEntity? getHostelById(String id) {
    try {
      return hostels.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  BookingEntity? getBookingForUser(String userId) {
    try {
      return bookings.firstWhere((b) => b.userId == userId);
    } catch (_) {
      return null;
    }
  }

  double calculateCommission(num amount) => amount * commissionRate;
  double calculateOwnerPayout(num amount) => amount * (1 - commissionRate);

  List<HostelEntity> getHostelsForOwner(String ownerId) {
    return hostels.where((h) => h.ownerId == ownerId).toList();
  }

  bool hasReleasedPayoutForOwnerThisMonth(String ownerId) {
    final now = DateTime.now();
    return payouts.any((p) {
      return p.ownerId == ownerId &&
          p.year == now.year &&
          p.month == now.month &&
          (p.status == 'paid' || p.status == 'released');
    });
  }

  double calculateTotalRentForOwnerThisMonth(String ownerId) {
    final now = DateTime.now();
    final ownerHostelIds = hostels.where((h) => h.ownerId == ownerId).map((h) => h.id).toList();
    
    double totalRent = 0;
    for (final b in bookings) {
      if (b.status == BookingStatus.confirmed && ownerHostelIds.contains(b.hostelId)) {
        if (_parseYear(b.date) == now.year && _parseMonthIndex(b.date) == now.month - 1) {
          totalRent += b.price;
        }
      }
    }
    return totalRent;
  }

  /// Approve, Reject, Suspend
  Future<void> approveHostel(String hostelId, [String? reason]) => updateHostelApproval(hostelId, ApprovalStatus.approved);
  Future<void> rejectHostel(String hostelId, [String? reason]) => updateHostelApproval(hostelId, ApprovalStatus.rejected);
  Future<void> suspendHostel(String hostelId, [String? reason]) => updateHostelApproval(hostelId, ApprovalStatus.suspended);

  Future<void> updateHostelApproval(String hostelId, ApprovalStatus status) async {
    await _hostelService.updateApprovalStatus(hostelId, status);
    hostels = hostels.map((h) => h.id == hostelId ? h.copyWith(approvalStatus: status) : h).toList();
    notifyListeners();
    
    final hostel = getHostelById(hostelId);
    if (hostel != null) {
      if (status == ApprovalStatus.approved) {
        await NotificationService().sendNotification(
          userId: hostel.ownerId,
          title: 'Hostel Approved',
          body: 'Your listing "${hostel.name}" has been approved and is now live.',
          type: 'system',
        );
      } else if (status == ApprovalStatus.rejected) {
        await NotificationService().sendNotification(
          userId: hostel.ownerId,
          title: 'Hostel Rejected',
          body: 'Your listing "${hostel.name}" has been rejected.',
          type: 'system',
        );
      }
    }
  }

  /// User management
  Future<void> disableUser(String userId) => updateUserStatus(userId, UserStatus.inactive);
  Future<void> enableUser(String userId) => updateUserStatus(userId, UserStatus.active);
  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
    users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  Future<void> updateUserStatus(String userId, UserStatus status) async {
    await _db.collection('users').doc(userId).update({
      'status': status.name,
    });
    users = users.map((u) {
      return u.id == userId ? u.copyWith(status: status) : u;
    }).toList();
    notifyListeners();
  }

  Future<void> updateCommissionRate(double rate) async {
    commissionRate = rate;
    await _db.collection('app_settings').doc('platform').set({
      'commissionRate': rate,
    }, SetOptions(merge: true));
    notifyListeners();
  }

  Future<void> updatePlatformSetting(String key, bool value) async {
    if (key == 'allowNewListings') allowNewListings = value;
    if (key == 'maintenanceMode') maintenanceMode = value;
    await _db.collection('app_settings').doc('platform').set({
      key: value,
    }, SetOptions(merge: true));
    notifyListeners();
  }

  /// Complaints
  Future<void> updateComplaintStatus(
    String complaintId,
    String status, {
    String? response,
  }) async {
    final trimmedResponse = response?.trim();
    await _db.collection('complaints').doc(complaintId).update({
      'status': status,
      if (trimmedResponse != null && trimmedResponse.isNotEmpty)
        'adminResponse': trimmedResponse,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'Resolved') 'resolvedAt': FieldValue.serverTimestamp(),
    });
    complaints = complaints.map((c) {
      return c.id == complaintId ? c.copyWith(status: status) : c;
    }).toList();
    notifyListeners();
  }

  Future<void> cancelBooking(BookingEntity booking) async {
    await _bookingService.cancelBooking(
      booking: booking,
      cancelledBy: 'admin',
    );
    bookings = bookings.where((b) => b.id != booking.id).toList();
    notifyListeners();
  }
}
