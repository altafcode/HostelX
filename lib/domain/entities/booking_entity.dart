import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/helpers.dart';

enum BookingStatus {
  pending,
  approved,
  paymentPending,
  confirmed,
  rejected,
  cancelled,

  // Legacy values kept so old Firestore data can still be read safely.
  completed,
  declined,
  expired,
  overdue,
}

extension BookingStatusX on BookingStatus {
  String get firestoreValue {
    switch (this) {
      case BookingStatus.completed:
        return BookingStatus.confirmed.name;
      case BookingStatus.declined:
        return BookingStatus.rejected.name;
      case BookingStatus.expired:
      case BookingStatus.overdue:
        return BookingStatus.cancelled.name;
      case BookingStatus.paymentPending:
        return 'payment_pending';
      default:
        return name;
    }
  }

  bool get isActive {
    return this == BookingStatus.pending ||
        this == BookingStatus.approved ||
        this == BookingStatus.paymentPending ||
        this == BookingStatus.confirmed ||
        this == BookingStatus.completed ||
        this == BookingStatus.overdue;
  }

  bool get isPaid =>
      this == BookingStatus.confirmed || this == BookingStatus.completed;

  static BookingStatus parse(dynamic value) {
    final raw = value?.toString() ?? '';
    switch (raw) {
      case 'completed':
        return BookingStatus.confirmed;
      case 'declined':
        return BookingStatus.rejected;
      case 'expired':
      case 'overdue':
        return BookingStatus.cancelled;
      case 'payment_pending':
        return BookingStatus.paymentPending;
      default:
        return BookingStatus.values.firstWhere(
          (s) => s.name == raw,
          orElse: () => BookingStatus.pending,
        );
    }
  }
}

class BookingEntity {
  final String id;
  final String hostelId;
  final String hostelName;
  final String ownerId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userOccupation;
  final String roomNumber;
  final String roomType;
  final String bedNumber;
  final BookingStatus status;
  final String date;
  final int price;
  final double commission;
  final double ownerPayout;
  final DateTime? paymentDate;
  final String payoutStatus;
  final String? payoutId;
  final bool refundNeeded;
  final String? hostelImage;
  final List<bool> paymentHistory;

  const BookingEntity({
    required this.id,
    required this.hostelId,
    required this.hostelName,
    required this.ownerId,
    required this.userId,
    required this.userName,
    this.userEmail = '',
    this.userPhone = '',
    this.userOccupation = '',
    required this.roomNumber,
    this.roomType = 'Standard Room',
    this.bedNumber = '',
    required this.status,
    required this.date,
    required this.price,
    this.commission = 0,
    this.ownerPayout = 0,
    this.paymentDate,
    this.payoutStatus = 'pending',
    this.payoutId,
    this.refundNeeded = false,
    this.hostelImage,
    this.paymentHistory = const [],
  });

  int get rentAmount => price;
  DateTime get checkInDate => AppHelpers.parseDate(date);

  DateTime get contractEndDate {
    final d = AppHelpers.parseDate(date);
    return DateTime(d.year + 1, d.month, d.day);
  }

  BookingEntity copyWith({
    String? id,
    String? hostelId,
    String? hostelName,
    String? ownerId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userOccupation,
    String? roomNumber,
    String? roomType,
    String? bedNumber,
    BookingStatus? status,
    String? date,
    int? price,
    double? commission,
    double? ownerPayout,
    DateTime? paymentDate,
    String? payoutStatus,
    String? payoutId,
    bool? refundNeeded,
    String? hostelImage,
    List<bool>? paymentHistory,
  }) {
    return BookingEntity(
      id: id ?? this.id,
      hostelId: hostelId ?? this.hostelId,
      hostelName: hostelName ?? this.hostelName,
      ownerId: ownerId ?? this.ownerId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userOccupation: userOccupation ?? this.userOccupation,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      bedNumber: bedNumber ?? this.bedNumber,
      status: status ?? this.status,
      date: date ?? this.date,
      price: price ?? this.price,
      commission: commission ?? this.commission,
      ownerPayout: ownerPayout ?? this.ownerPayout,
      paymentDate: paymentDate ?? this.paymentDate,
      payoutStatus: payoutStatus ?? this.payoutStatus,
      payoutId: payoutId ?? this.payoutId,
      refundNeeded: refundNeeded ?? this.refundNeeded,
      hostelImage: hostelImage ?? this.hostelImage,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostelId': hostelId,
      'hostelName': hostelName,
      'hostelImage': hostelImage ?? '',
      'ownerId': ownerId,
      'studentId': userId,
      'studentName': userName,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userOccupation': userOccupation,
      'roomNumber': roomNumber,
      'roomType': roomType,
      'bedNumber': bedNumber,
      'status': status.firestoreValue,
      'date': date,
      'price': price,
      'amount': price,
      'commission': commission,
      'ownerPayout': ownerPayout,
      'paymentDate':
          paymentDate == null ? null : Timestamp.fromDate(paymentDate!),
      'payoutStatus': payoutStatus,
      'payoutId': payoutId,
      'refundNeeded': refundNeeded,
      'paymentHistory': paymentHistory,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static BookingEntity fromMap(String id, Map<String, dynamic> map) {
    DateTime? parsePaymentDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      return DateTime.tryParse(value.toString());
    }

    String readString(List<String> keys) {
      for (final key in keys) {
        final value = map[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return '';
    }

    int readInt(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    List<bool> readBoolList(dynamic value) {
      if (value is! List) return const [];
      return value.map((item) {
        if (item is bool) return item;
        if (item is num) return item != 0;
        final raw = item.toString().trim().toLowerCase();
        return raw == 'true' || raw == 'paid' || raw == '1';
      }).toList();
    }

    final userId = readString(['userId', 'studentId']);
    final userName = readString(['userName', 'studentName']);
    final roomType = readString(['roomType']);
    final price = readInt(['amount', 'price']);
    return BookingEntity(
      id: id,
      hostelId: readString(['hostelId']),
      hostelName: readString(['hostelName']),
      ownerId: readString(['ownerId']),
      userId: userId,
      userName: userName,
      userEmail: readString(['userEmail', 'studentEmail', 'email']),
      userPhone: readString(['userPhone', 'studentPhone', 'phone']),
      userOccupation: readString(['userOccupation', 'occupation']),
      roomNumber: readString(['roomNumber']),
      roomType: roomType.isEmpty ? 'Standard Room' : roomType,
      bedNumber: readString(['bedNumber']),
      status: BookingStatusX.parse(map['status']),
      date: readString(['date']),
      price: price,
      commission: (map['commission'] ?? 0).toDouble(),
      ownerPayout: (map['ownerPayout'] ?? 0).toDouble(),
      paymentDate: parsePaymentDate(map['paymentDate']),
      payoutStatus: readString(['payoutStatus']).isEmpty
          ? 'pending'
          : readString(['payoutStatus']),
      payoutId: map['payoutId']?.toString(),
      refundNeeded: map['refundNeeded'] ?? false,
      hostelImage: map['hostelImage'],
      paymentHistory: readBoolList(map['paymentHistory']),
    );
  }
}
