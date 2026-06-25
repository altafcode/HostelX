import '../../core/utils/helpers.dart';

class PayoutEntity {
  final String id;
  final String ownerId;
  final String ownerName;
  final List<String> hostelIds;
  final List<String> hostelNames;
  final double grossAmount;
  final double commissionAmount;
  final double netAmount;
  final String status;
  final String method;
  final String? transferId;
  final String date;
  final int year;
  final int month;

  const PayoutEntity({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.hostelIds,
    required this.hostelNames,
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    required this.status,
    required this.method,
    this.transferId,
    required this.date,
    required this.year,
    required this.month,
  });

  DateTime get createdAt {
    if (date.trim().isEmpty) return DateTime.now();
    return AppHelpers.parseDate(date);
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'hostelIds': hostelIds,
      'hostelNames': hostelNames,
      'grossAmount': grossAmount,
      'commissionAmount': commissionAmount,
      'netAmount': netAmount,
      'status': status,
      'payoutStatus': status,
      'method': method,
      'transferId': transferId ?? '',
      'date': date,
      'year': year,
      'month': month,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static PayoutEntity fromMap(String id, Map<String, dynamic> map) {
    return PayoutEntity(
      id: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      hostelIds: List<String>.from(map['hostelIds'] ?? []),
      hostelNames: List<String>.from(map['hostelNames'] ?? []),
      grossAmount: (map['grossAmount'] ?? 0).toDouble(),
      commissionAmount: (map['commissionAmount'] ?? 0).toDouble(),
      netAmount: (map['netAmount'] ?? 0).toDouble(),
      status: map['payoutStatus'] ?? map['status'] ?? 'paid',
      method: map['method'] ?? 'stripe',
      transferId: map['transferId']?.toString(),
      date: map['date'] ?? '',
      year: (map['year'] ?? DateTime.now().year).toInt(),
      month: (map['month'] ?? DateTime.now().month).toInt(),
    );
  }
}
