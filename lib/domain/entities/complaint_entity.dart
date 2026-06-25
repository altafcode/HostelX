import 'package:cloud_firestore/cloud_firestore.dart';

enum ComplaintStatus { open, resolved, underReview }

class ComplaintEntity {
  final String id;
  final String type;
  final String title;
  final String byUserId;
  final String byUserName;
  final String againstId; // Could be hostelId or ownerId
  final String againstName;
  final String ownerId;
  final String status; // 'Open', 'Resolved', 'Under Review'
  final String description;
  final DateTime createdAt;

  const ComplaintEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.byUserId,
    required this.byUserName,
    required this.againstId,
    required this.againstName,
    required this.ownerId,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  ComplaintEntity copyWith({
    String? id,
    String? type,
    String? title,
    String? byUserId,
    String? byUserName,
    String? againstId,
    String? againstName,
    String? ownerId,
    String? status,
    String? description,
    DateTime? createdAt,
  }) {
    return ComplaintEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      byUserId: byUserId ?? this.byUserId,
      byUserName: byUserName ?? this.byUserName,
      againstId: againstId ?? this.againstId,
      againstName: againstName ?? this.againstName,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'byUserId': byUserId,
      'byUserName': byUserName,
      'againstId': againstId,
      'againstName': againstName,
      'ownerId': ownerId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static ComplaintEntity fromMap(String id, Map<String, dynamic> map) {
    DateTime readDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return ComplaintEntity(
      id: id,
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      byUserId: map['byUserId'] ?? '',
      byUserName: map['byUserName'] ?? '',
      againstId: map['againstId'] ?? '',
      againstName: map['againstName'] ?? '',
      ownerId: map['ownerId'] ?? '',
      status: map['status'] ?? 'Open',
      createdAt: readDate(map['createdAt']),
    );
  }

}
