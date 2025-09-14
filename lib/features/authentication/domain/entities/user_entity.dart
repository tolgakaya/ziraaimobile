import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phoneNumber;
  final bool isEmailVerified;
  final String? tier;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.isEmailVerified = false,
    this.tier,
  });

  String get fullName => '$firstName $lastName';

  bool get isFarmer => role.toLowerCase() == 'farmer';
  bool get isSponsor => role.toLowerCase() == 'sponsor';
  bool get isAdmin => role.toLowerCase() == 'admin';

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        role,
        phoneNumber,
        isEmailVerified,
        tier,
      ];
}