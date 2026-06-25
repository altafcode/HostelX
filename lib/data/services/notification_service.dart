import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/config/push_config.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DateTime? parseCreatedAt(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  List<Map<String, dynamic>> _mapDocs(
      QuerySnapshot<Map<String, dynamic>> snap) {
    final docs = snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    docs.sort((a, b) {
      final aDate =
          parseCreatedAt(a['createdAt']) ?? parseCreatedAt(a['createdAtIso']);
      final bDate =
          parseCreatedAt(b['createdAt']) ?? parseCreatedAt(b['createdAtIso']);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    final seen = <String>{};
    return docs.where((data) {
      final key = '${data['type']}|${data['title']}|${data['body']}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  /// Send notification to a user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type, // 'booking' | 'complaint' | 'system'
  }) async {
    if (userId.trim().isEmpty) return;

    try {
      // We now let the SERVER create the notification document in Firestore
      // and send the push notification. This avoids client-side permission issues.
      await _sendPushNotification(
        notificationId: 'new', 
        userId: userId,
        title: title,
        body: body,
        type: type,
      );
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }

  Future<void> sendNotificationToRole({
    required String role,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _sendPushNotification(
        notificationId: 'role_broadcast',
        role: role.toLowerCase(),
        title: title,
        body: body,
        type: type,
      );
    } catch (e) {
      debugPrint('Role notification failed: $e');
    }
  }

  Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _sendPushNotification(
        notificationId: 'broadcast_all',
        role: 'all',
        title: title,
        body: body,
        type: type,
      );
    } catch (e) {
      debugPrint('Broadcast notification failed: $e');
    }
  }

  Future<void> _sendPushNotification({
    required String notificationId,
    String? userId,
    String? role,
    required String title,
    required String body,
    required String type,
  }) async {
    final endpoint = PushConfig.pushEndpoint.trim();
    if (endpoint.isEmpty) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final idToken = await currentUser?.getIdToken();
      if (idToken == null) return;

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'notificationId': notificationId,
          if (userId != null) 'userId': userId,
          if (role != null) 'role': role,
          'title': title,
          'body': body,
          'type': type,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint(
        'Push notification [${userId ?? role}] response: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Push notification connection failed: $e');
    }
  }

  /// Fetch notifications for a user
  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    return _mapDocs(snap);
  }

  /// Watch notifications for live in-app updates.
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_mapDocs);
  }

  Stream<int> watchUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
