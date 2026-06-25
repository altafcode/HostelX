enum HostelType { boys, girls }

enum HostelAvailability { open, full }

enum ApprovalStatus { pending, approved, rejected, suspended }

class RoomTypeConfigEntity {
  final String type;
  final int count;
  final int price;

  const RoomTypeConfigEntity({
    required this.type,
    required this.count,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'count': count,
      'price': price,
    };
  }

  static RoomTypeConfigEntity fromMap(Map<String, dynamic> map) {
    int readInt(String key) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return RoomTypeConfigEntity(
      type: map['type']?.toString() ?? 'Standard Room',
      count: readInt('count'),
      price: readInt('price'),
    );
  }
}

class HostelEntity {
  final String id;
  final String name;
  final String location;
  final String city;
  final double lat;
  final double lng;
  final int price;
  final double rating;
  final int reviewsCount;
  final List<String> images;
  final List<String> facilities;
  final HostelType type;
  final HostelAvailability availability;
  final String description;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String ownerWhatsapp;
  final Map<String, String> documentUrls;
  final ApprovalStatus approvalStatus;
  final bool isRecommended;
  final bool isMostPopular;
  final bool isRecentlyAdded;
  final bool isBudgetFriendly;
  final int minContractMonths;
  final int securityDeposit;
  final int totalRooms;
  final double rentIncrementPercentage;
  final List<RoomTypeConfigEntity> roomConfigurations;
  final DateTime? createdAt;

  const HostelEntity({
    required this.id,
    required this.name,
    required this.location,
    required this.city,
    required this.lat,
    required this.lng,
    required this.price,
    required this.rating,
    required this.reviewsCount,
    required this.images,
    required this.facilities,
    required this.type,
    required this.availability,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhone = '',
    this.ownerWhatsapp = '',
    this.documentUrls = const {},
    required this.approvalStatus,
    this.isRecommended = false,
    this.isMostPopular = false,
    this.isRecentlyAdded = false,
    this.isBudgetFriendly = false,
    this.minContractMonths = 6,
    this.securityDeposit = 0,
    this.totalRooms = 0,
    this.rentIncrementPercentage = 0.0,
    this.roomConfigurations = const [],
    this.createdAt,
  });

  HostelEntity copyWith({
    String? id,
    String? name,
    String? location,
    String? city,
    double? lat,
    double? lng,
    int? price,
    double? rating,
    int? reviewsCount,
    List<String>? images,
    List<String>? facilities,
    HostelType? type,
    HostelAvailability? availability,
    String? description,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? ownerWhatsapp,
    Map<String, String>? documentUrls,
    ApprovalStatus? approvalStatus,
    bool? isRecommended,
    bool? isMostPopular,
    bool? isRecentlyAdded,
    bool? isBudgetFriendly,
    int? minContractMonths,
    int? securityDeposit,
    int? totalRooms,
    double? rentIncrementPercentage,
    List<RoomTypeConfigEntity>? roomConfigurations,
    DateTime? createdAt,
  }) {
    return HostelEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      images: images ?? this.images,
      facilities: facilities ?? this.facilities,
      type: type ?? this.type,
      availability: availability ?? this.availability,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerWhatsapp: ownerWhatsapp ?? this.ownerWhatsapp,
      documentUrls: documentUrls ?? this.documentUrls,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isRecommended: isRecommended ?? this.isRecommended,
      isMostPopular: isMostPopular ?? this.isMostPopular,
      isRecentlyAdded: isRecentlyAdded ?? this.isRecentlyAdded,
      isBudgetFriendly: isBudgetFriendly ?? this.isBudgetFriendly,
      minContractMonths: minContractMonths ?? this.minContractMonths,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      totalRooms: totalRooms ?? this.totalRooms,
      rentIncrementPercentage:
          rentIncrementPercentage ?? this.rentIncrementPercentage,
      roomConfigurations: roomConfigurations ?? this.roomConfigurations,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'city': city,
      'lat': lat,
      'lng': lng,
      'price': price,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'images': images,
      'facilities': facilities,
      'type': type.name,
      'availability': availability.name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerWhatsapp': ownerWhatsapp,
      'documentUrls': documentUrls,
      'approvalStatus': approvalStatus.name,
      'isRecommended': isRecommended,
      'isMostPopular': isMostPopular,
      'isRecentlyAdded': isRecentlyAdded,
      'isBudgetFriendly': isBudgetFriendly,
      'minContractMonths': minContractMonths,
      'securityDeposit': securityDeposit,
      'totalRooms': totalRooms,
      'rentIncrementPercentage': rentIncrementPercentage,
      'roomConfigurations':
          roomConfigurations.map((config) => config.toMap()).toList(),
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static HostelEntity fromMap(String id, Map<String, dynamic> map) {
    List<RoomTypeConfigEntity> readRoomConfigurations(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((item) =>
              RoomTypeConfigEntity.fromMap(Map<String, dynamic>.from(item)))
          .where((config) => config.count > 0)
          .toList();
    }

    Map<String, String> readStringMap(dynamic value) {
      if (value is! Map) return const {};
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }

    DateTime? readDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return HostelEntity(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      city: map['city'] ?? '',
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      price: (map['price'] ?? 0).toInt(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewsCount: (map['reviewsCount'] ?? 0).toInt(),
      images: List<String>.from(map['images'] ?? []),
      facilities: List<String>.from(map['facilities'] ?? []),
      type: HostelType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => HostelType.boys,
      ),
      availability: HostelAvailability.values.firstWhere(
        (a) => a.name == map['availability'],
        orElse: () => HostelAvailability.open,
      ),
      description: map['description'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhone: map['ownerPhone']?.toString() ?? '',
      ownerWhatsapp: map['ownerWhatsapp']?.toString() ?? '',
      documentUrls: readStringMap(map['documentUrls']),
      approvalStatus: ApprovalStatus.values.firstWhere(
        (s) => s.name == map['approvalStatus'],
        orElse: () => ApprovalStatus.pending,
      ),
      isRecommended: map['isRecommended'] ?? false,
      isMostPopular: map['isMostPopular'] ?? false,
      isRecentlyAdded: map['isRecentlyAdded'] ?? false,
      isBudgetFriendly: map['isBudgetFriendly'] ?? false,
      minContractMonths: (map['minContractMonths'] ?? 6).toInt(),
      securityDeposit: (map['securityDeposit'] ?? 0).toInt(),
      totalRooms: (map['totalRooms'] ?? 0).toInt(),
      rentIncrementPercentage:
          (map['rentIncrementPercentage'] ?? 0.0).toDouble(),
      roomConfigurations: readRoomConfigurations(map['roomConfigurations']),
      createdAt: readDate(map['createdAt']),
    );
  }
}

class ReviewEntity {
  final String id;
  final String hostelId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final String date;
  final String? ownerReply;

  const ReviewEntity({
    required this.id,
    required this.hostelId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    this.ownerReply,
  });
}
