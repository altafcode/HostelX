import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/hostel_entity.dart';

class HostelService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all approved hostels
  Future<List<HostelEntity>> fetchHostels() async {
    final snap = await _db.collection('hostels').get();
    return snap.docs
        .map((doc) => HostelEntity.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Fetch reviews for all hostels
  Future<List<ReviewEntity>> fetchReviews() async {
    final snap = await _db
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return ReviewEntity(
        id: doc.id,
        hostelId: d['hostelId'] ?? '',
        userId: d['userId'] ?? '',
        userName: d['userName'] ?? '',
        rating: (d['rating'] ?? 0.0).toDouble(),
        comment: d['comment'] ?? '',
        date: _readReviewDate(d),
        ownerReply: d['ownerReply'],
      );
    }).toList();
  }

  String _readReviewDate(Map<String, dynamic> data) {
    final date = data['date'];
    if (date is String && date.trim().isNotEmpty) return date;

    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      final value = createdAt.toDate();
      return '${_monthName(value.month)} ${value.day}, ${value.year}';
    }
    if (createdAt is String && createdAt.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        return '${_monthName(parsed.month)} ${parsed.day}, ${parsed.year}';
      }
      return createdAt;
    }

    return '';
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return names[month - 1];
  }

  /// Fetch hostels by city
  Future<List<HostelEntity>> fetchHostelsByCity(String city) async {
    final snap =
        await _db.collection('hostels').where('city', isEqualTo: city).get();
    return snap.docs
        .map((doc) => HostelEntity.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Fetch single hostel by ID
  Future<HostelEntity?> fetchHostelById(String id) async {
    final doc = await _db.collection('hostels').doc(id).get();
    if (!doc.exists) return null;
    return HostelEntity.fromMap(doc.id, doc.data()!);
  }

  /// Submit a review
  Future<ReviewEntity> submitReview({
    required String hostelId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    final ref = _db.collection('reviews').doc();
    final now = DateTime.now();

    final data = {
      'hostelId': hostelId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': now.toIso8601String(),
    };

    await ref.set(data);

    // Update hostel's average rating in Firestore
    final hostelDoc = await _db.collection('hostels').doc(hostelId).get();
    if (hostelDoc.exists) {
      final hostelData = hostelDoc.data()!;
      final oldRating = (hostelData['rating'] ?? 0.0).toDouble();
      final oldCount = (hostelData['reviewsCount'] ?? 0).toInt();
      final newCount = oldCount + 1;
      final newRating = ((oldRating * oldCount) + rating) / newCount;

      await _db.collection('hostels').doc(hostelId).update({
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'reviewsCount': newCount,
      });
    }

    return ReviewEntity(
      id: ref.id,
      hostelId: hostelId,
      userId: userId,
      userName: userName,
      rating: rating,
      comment: comment,
      date: now.toIso8601String(),
    );
  }

  /// Fetch hostels by owner ID
  Future<List<HostelEntity>> fetchHostelsByOwner(String ownerId) async {
    final snap = await _db
        .collection('hostels')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snap.docs
        .map((doc) => HostelEntity.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Save hostel (owner adds new listing)
  Future<String> saveHostel(HostelEntity hostel) async {
    final ref = _db.collection('hostels').doc();
    await ref.set(hostel.toMap());
    return ref.id;
  }

  /// Update existing hostel
  Future<void> updateHostel(String hostelId, Map<String, dynamic> data) async {
    await _db.collection('hostels').doc(hostelId).update(data);
  }

  /// Update approval status (admin)
  Future<void> updateApprovalStatus(
      String hostelId, ApprovalStatus status) async {
    await _db.collection('hostels').doc(hostelId).update({
      'approvalStatus': status.name,
    });
  }
}
