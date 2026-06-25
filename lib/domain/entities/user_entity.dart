enum UserRole { tenant, owner, admin }
enum UserStatus { active, inactive }
enum Occupation { student, jobHolder, selfEmployed, other }

class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final UserStatus status;
  final Occupation? occupation;
  final String? phone;
  final String? city;
  final String? avatar;
  final String? joinedDate;
  final Map<String, dynamic>? bankDetails;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.occupation,
    this.phone,
    this.city,
    this.avatar,
    this.joinedDate,
    this.bankDetails,
  });
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'status': status.name,
      'occupation': occupation?.name ?? 'other',
      'phone': phone ?? '',
      'city': city ?? '',
      'avatar': avatar ?? '',
      'joinedDate': joinedDate ?? '',
      'bankDetails': bankDetails,
    };
  }

  static UserEntity fromMap(String id, Map<String, dynamic> map) {
    return UserEntity(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
            (r) => r.name == map['role'],
        orElse: () => UserRole.tenant,
      ),
      status: UserStatus.values.firstWhere(
            (s) => s.name == map['status'],
        orElse: () => UserStatus.active,
      ),
      occupation: map['occupation'] != null
          ? Occupation.values.firstWhere(
            (o) => o.name == map['occupation'],
        orElse: () => Occupation.other,
      )
          : null,
      phone: map['phone'],
      city: map['city'],
      avatar: map['avatar'],
      joinedDate: map['joinedDate'],
      bankDetails: map['bankDetails'] as Map<String, dynamic>?,
    );
  }
  UserEntity copyWith({
    String? id, String? name, String? email,
    UserRole? role, UserStatus? status,
    Occupation? occupation, String? phone, String? city,
    String? avatar, String? joinedDate,
    Map<String, dynamic>? bankDetails,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      occupation: occupation ?? this.occupation,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      avatar: avatar ?? this.avatar,
      joinedDate: joinedDate ?? this.joinedDate,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }
}
