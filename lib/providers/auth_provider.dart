import 'dart:async';

import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import '../data/services/push_notification_service.dart';
import '../domain/entities/user_entity.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserEntity? _user;
  bool _isLoading = false;
  String? _error;

  UserEntity? get user        => _user;
  bool        get isLoading   => _isLoading;
  bool        get isAuthenticated => _user != null;
  String?     get error       => _error;

  // ── Login ────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(
        email: email,
        password: password,
        role: role,
      );
      unawaited(PushNotificationService.instance.registerUser(_user!.id));
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Register ─────────────────────────────────────────────
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
    UserRole role = UserRole.tenant,
    Occupation occupation = Occupation.student,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        city: city,
        role: role,
        occupation: occupation,
      );
      unawaited(PushNotificationService.instance.registerUser(_user!.id));
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Restore session on app start ─────────────────────────
  Future<UserEntity?> restoreSession() async {
    try {
      _user = await _authService.getCurrentUser();
      if (_user != null) {
        unawaited(PushNotificationService.instance.registerUser(_user!.id));
      }
      notifyListeners();
      return _user;
    } catch (_) {
      return null;
    }
  }

  // ── Logout ───────────────────────────────────────────────
  Future<void> logout() async {
    final userId = _user?.id;
    if (userId != null) {
      await PushNotificationService.instance.unregisterUser(userId);
    }
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  // ── Update profile field ─────────────────────────────────
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    try {
      await _authService.updateProfile(uid: _user!.id, data: data);
      // Update local cache
      if (data.containsKey('name')) {
        _user = _user!.copyWith(name: data['name']);
      }
      if (data.containsKey('phone')) {
        _user = _user!.copyWith(phone: data['phone']);
      }
      if (data.containsKey('city')) {
        _user = _user!.copyWith(city: data['city']);
      }
      if (data.containsKey('avatar')) {
        _user = _user!.copyWith(avatar: data['avatar']);
      }
      if (data.containsKey('occupation')) {
        final occupation = Occupation.values.firstWhere(
          (item) => item.name == data['occupation'],
          orElse: () => _user!.occupation ?? Occupation.other,
        );
        _user = _user!.copyWith(occupation: occupation);
      }
      if (data.containsKey('bankDetails')) {
        _user = _user!.copyWith(bankDetails: data['bankDetails']);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update profile.';
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
