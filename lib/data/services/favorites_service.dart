import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Load favorite hostel IDs for a tenant
  Future<Set<String>> loadFavorites(String userId) async {
    final doc = await _db.collection('favorites').doc(userId).get();
    if (!doc.exists) return {};
    final ids = List<String>.from(doc.data()?['hostelIds'] ?? []);
    return ids.toSet();
  }

  /// Toggle a hostel in favorites
  Future<void> toggleFavorite(String userId, String hostelId, bool isCurrentlyFav) async {
    final ref = _db.collection('favorites').doc(userId);
    if (isCurrentlyFav) {
      await ref.set({
        'hostelIds': FieldValue.arrayRemove([hostelId]),
      }, SetOptions(merge: true));
    } else {
      await ref.set({
        'hostelIds': FieldValue.arrayUnion([hostelId]),
      }, SetOptions(merge: true));
    }
  }
}