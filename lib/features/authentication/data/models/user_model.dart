import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/phone_number.dart';
import '../../domain/value_objects/user_role.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isVerified;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.isVerified = false,
    this.isActive = true,
    this.metadata,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  User toDomain() {
    return User(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: Email(email),
      phoneNumber: phoneNumber,
      role: UserRole.fromString(role),
      profileImageUrl: profileImageUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      isVerified: isVerified,
      isActive: isActive,
      metadata: metadata,
    );
  }

  factory UserModel.fromDomain(User user) {
    return UserModel(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email.value,
      phoneNumber: user.phoneNumber,
      role: user.role.name,
      profileImageUrl: user.profileImageUrl,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      isVerified: user.isVerified,
      isActive: user.isActive,
      metadata: user.metadata,
    );
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isVerified,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}