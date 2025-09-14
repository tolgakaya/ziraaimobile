import 'package:equatable/equatable.dart';
import '../value_objects/email.dart';
import '../value_objects/user_role.dart';

/// Core user entity representing an authenticated user in the ZiraAI system.
/// Supports both Farmer and Sponsor roles with role-specific properties.
class User extends Equatable {
  final String id;
  final Email email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isVerified;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.isVerified = false,
    this.isActive = true,
    this.metadata,
  });

  /// Returns the full name of the user
  String get fullName => '$firstName $lastName';

  /// Returns whether the user is a farmer
  bool get isFarmer => role == UserRole.farmer;

  /// Returns whether the user is a sponsor
  bool get isSponsor => role == UserRole.sponsor;

  /// Returns whether the user is an admin
  bool get isAdmin => role == UserRole.admin;

  /// Creates a copy of this user with updated values
  User copyWith({
    String? id,
    Email? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isVerified,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        role,
        phoneNumber,
        profileImageUrl,
        createdAt,
        lastLoginAt,
        isVerified,
        isActive,
        metadata,
      ];

  @override
  String toString() {
    return 'User(id: $id, email: ${email.value}, role: ${role.name}, fullName: $fullName)';
  }
}