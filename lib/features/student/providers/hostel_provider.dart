import 'package:flutter/material.dart';
import '../services/hostel_service.dart';
import '../../../data/services/favorites_service.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../core/constants/app_constants.dart';

class HostelProvider extends ChangeNotifier {
  final HostelService _hostelService = HostelService();
  final FavoritesService _favoritesService = FavoritesService();

  List<HostelEntity> _hostels = [];
  List<ReviewEntity> _reviews = [];
  Set<String> _favoriteIds = {};
  final List<String> _recentlyViewedIds = [];
  String _selectedCity = 'Lahore';
  String _activeFilter = 'All';
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  HostelProvider() {
    loadHostels();
  }

  // ── Getters (keep same as before) ──────────────────────────
  List<HostelEntity> get allHostels => _hostels;
  List<ReviewEntity> get allReviews => _reviews;
  String get selectedCity => _selectedCity;
  String get activeFilter => _activeFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<HostelEntity> get cityHostels =>
      _applyFilter(_hostels.where((h) => h.city == _selectedCity).toList());

  List<HostelEntity> get recommended =>
      cityHostels.where((h) => h.isRecommended).toList();
  List<HostelEntity> get mostPopular =>
      cityHostels.where((h) => h.isMostPopular).toList();
  List<HostelEntity> get budgetFriendly =>
      cityHostels.where((h) => h.isBudgetFriendly).toList();
  List<HostelEntity> get recentlyAdded =>
      cityHostels.where((h) => h.isRecentlyAdded).toList();

  List<HostelEntity> get favoriteHostels =>
      _hostels.where((h) => _favoriteIds.contains(h.id)).toList();

  List<HostelEntity> get recentlyViewed => _recentlyViewedIds
      .map((id) => hostelById(id))
      .whereType<HostelEntity>()
      .toList();

  List<ReviewEntity> reviewsFor(String hostelId) =>
      _reviews.where((r) => r.hostelId == hostelId).toList();

  HostelEntity? hostelById(String id) {
    try { return _hostels.firstWhere((h) => h.id == id); }
    catch (_) { return null; }
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  // ── UPDATED: Load from Firestore ────────────────────────────
  Future<void> loadHostels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _hostels = await _hostelService.fetchHostels();
      _reviews = await _hostelService.fetchReviews();
    } catch (e) {
      _error = 'Failed to load hostels. Check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Call this after login to load favorites from Firestore
  Future<void> loadFavorites(String userId) async {
    _currentUserId = userId;
    _favoriteIds = await _favoritesService.loadFavorites(userId);
    notifyListeners();
  }

  // ── UPDATED: Toggle favorite in Firestore ───────────────────
  Future<void> toggleFavorite(String id) async {
    final isFav = _favoriteIds.contains(id);
    // Optimistic update (instant UI feedback)
    if (isFav) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();

    // Persist to Firestore (if user is logged in)
    if (_currentUserId != null) {
      try {
        await _favoritesService.toggleFavorite(_currentUserId!, id, isFav);
      } catch (_) {
        // Revert if Firestore fails
        if (isFav) {
          _favoriteIds.add(id);
        } else {
          _favoriteIds.remove(id);
        }
        notifyListeners();
      }
    }
  }

  void addToRecentlyViewed(String id) {
    _recentlyViewedIds.remove(id);
    _recentlyViewedIds.insert(0, id);
    if (_recentlyViewedIds.length > 10) _recentlyViewedIds.removeLast();
    notifyListeners();
  }

  void setCity(String city) {
    _selectedCity = city;
    notifyListeners();
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  Future<void> addHostel(HostelEntity hostel) async {
    _hostels = [hostel, ..._hostels];
    notifyListeners();
  }

  void updateHostel(HostelEntity hostel) {
    final index = _hostels.indexWhere((h) => h.id == hostel.id);
    if (index != -1) {
      _hostels[index] = hostel;
      notifyListeners();
    }
  }

  void updateHostelApproval(String hostelId, ApprovalStatus status) {
    _hostels = _hostels.map((h) {
      return h.id == hostelId ? h.copyWith(approvalStatus: status) : h;
    }).toList();
    notifyListeners();
  }

  // ── UPDATED: Add review and persist ─────────────────────────
  Future<void> addReview(ReviewEntity review) async {
    try {
      final saved = await _hostelService.submitReview(
        hostelId: review.hostelId,
        userId: review.userId,
        userName: review.userName,
        rating: review.rating,
        comment: review.comment,
      );
      _reviews = [saved, ..._reviews];
      _updateLocalRating(saved);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to submit review.';
      notifyListeners();
      rethrow;
    }
  }

  void _updateLocalRating(ReviewEntity review) {
    _hostels = _hostels.map((h) {
      if (h.id != review.hostelId) return h;
      final newCount = h.reviewsCount + 1;
      final newRating = ((h.rating * h.reviewsCount) + review.rating) / newCount;
      return h.copyWith(
        reviewsCount: newCount,
        rating: double.parse(newRating.toStringAsFixed(1)),
      );
    }).toList();
  }

  List<HostelEntity> _applyFilter(List<HostelEntity> list) {
    return list.where((h) {
      if (h.approvalStatus != ApprovalStatus.approved) return false;
      switch (_activeFilter) {
        case 'WiFi': return h.facilities.contains('WiFi');
        case 'AC': return h.facilities.contains('AC');
        case 'Mess': return h.facilities.contains('Mess');
        case 'Laundry': return h.facilities.contains('Laundry');
        case 'Under Rs. 15k': return h.price < AppConstants.budgetThreshold;
        case 'Girls Only': return h.type == HostelType.girls;
        case 'Boys Only': return h.type == HostelType.boys;
        default: return true;
      }
    }).toList();
  }
}
