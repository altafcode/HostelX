import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/payout_entity.dart';

class PayoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<PayoutEntity>> watchPayouts() {
    return _db.collection('payouts').snapshots().map((snap) {
      final payouts = snap.docs
          .map((doc) => PayoutEntity.fromMap(doc.id, doc.data()))
          .toList();
      payouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return payouts;
    });
  }

  Stream<List<PayoutEntity>> watchOwnerPayouts(String ownerId) {
    return _db
        .collection('payouts')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
      final payouts = snap.docs
          .map((doc) => PayoutEntity.fromMap(doc.id, doc.data()))
          .toList();
      payouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return payouts;
    });
  }

  Future<void> savePayout(PayoutEntity payout) async {
    await _db.collection('payouts').doc(payout.id).set(payout.toMap());
  }
}
