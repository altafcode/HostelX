import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/complaint_entity.dart';

class ComplaintService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<ComplaintEntity>> fetchComplaintsByAgainstId(String againstId) async {
    final snap = await _db
        .collection('complaints')
        .where('againstId', isEqualTo: againstId)
        .get();
    return snap.docs
        .map((doc) => ComplaintEntity.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<ComplaintEntity>> fetchComplaintsByOwnerId(String ownerId) async {
    final snap = await _db
        .collection('complaints')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snap.docs
        .map((doc) => ComplaintEntity.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> submitComplaint(ComplaintEntity complaint) async {
    await _db.collection('complaints').doc(complaint.id).set(complaint.toMap());
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    await _db.collection('complaints').doc(id).update({'status': status});
  }
}
