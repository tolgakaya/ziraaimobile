import 'package:equatable/equatable.dart';

/// Base event for farmer profile BLoC
abstract class FarmerProfileEvent extends Equatable {
  const FarmerProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load farmer profile from API
class LoadFarmerProfile extends FarmerProfileEvent {
  const LoadFarmerProfile();
}

/// Event to update farmer profile
class UpdateFarmerProfile extends FarmerProfileEvent {
  final String fullName;
  final String email;
  final String mobilePhones;
  final DateTime? birthDate;
  final int? gender;
  final String? address;
  final String? notes;

  const UpdateFarmerProfile({
    required this.fullName,
    required this.email,
    required this.mobilePhones,
    this.birthDate,
    this.gender,
    this.address,
    this.notes,
  });

  @override
  List<Object?> get props => [
        fullName,
        email,
        mobilePhones,
        birthDate,
        gender,
        address,
        notes,
      ];
}
