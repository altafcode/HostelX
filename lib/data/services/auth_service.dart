import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── LOGIN ────────────────────────────────────────────────
  Future<UserEntity> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw Exception('User profile not found. Contact support.');
      }

      final user = UserEntity.fromMap(uid, doc.data()!);

      // Verify role matches what they selected on splash screen
      if (user.role != role) {
        await _auth.signOut();
        throw Exception(
          'This account is registered as a ${user.role.name}. Please select the correct role.',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'wrong-password':
          throw Exception('Incorrect password.');
        case 'too-many-requests':
          throw Exception('Too many attempts. Try again later.');
        default:
          throw Exception('Login failed: ${e.message}');
      }
    }
  }

  // ── REGISTER ─────────────────────────────────────────────
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
    UserRole role = UserRole.tenant,
    Occupation occupation = Occupation.student,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      final user = UserEntity(
        id: uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        status: UserStatus.active,
        occupation: occupation,
        phone: phone.trim(),
        city: city.trim(),
        joinedDate: _formatDate(DateTime.now()),
      );

      // Save user profile to Firestore
      await _db.collection('users').doc(uid).set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('An account already exists with this email.');
        case 'weak-password':
          throw Exception('Password is too weak. Use at least 6 characters.');
        default:
          throw Exception('Registration failed: ${e.message}');
      }
    }
  }

  // ── LOGOUT ───────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw Exception('No authenticated user found.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // ── GET CURRENT USER ─────────────────────────────────────
  /// Call this on app start (in splash) to restore session
  Future<UserEntity?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return null;

    return UserEntity.fromMap(firebaseUser.uid, doc.data()!);
  }

  // ── UPDATE PROFILE ───────────────────────────────────────
  Future<void> updateProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ── HELPERS ──────────────────────────────────────────────
  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
