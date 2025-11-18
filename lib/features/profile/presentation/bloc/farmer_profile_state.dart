import 'package:equatable/equatable.dart';
import '../../domain/entities/farmer_profile.dart';

/// Base state for farmer profile BLoC
abstract class FarmerProfileState extends Equatable {
  const FarmerProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no data loaded yet
class FarmerProfileInitial extends FarmerProfileState {
  const FarmerProfileInitial();
}

/// Loading state - API request in progress
class FarmerProfileLoading extends FarmerProfileState {
  const FarmerProfileLoading();
}

/// Loaded state - profile data successfully retrieved
class FarmerProfileLoaded extends FarmerProfileState {
  final FarmerProfile profile;

  const FarmerProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Updating state - profile update in progress
class FarmerProfileUpdating extends FarmerProfileState {
  final FarmerProfile currentProfile;

  const FarmerProfileUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

/// Update success state - profile updated successfully
class FarmerProfileUpdateSuccess extends FarmerProfileState {
  final FarmerProfile profile;
  final String message;

  const FarmerProfileUpdateSuccess({
    required this.profile,
    this.message = 'Profil başarıyla güncellendi',
  });

  @override
  List<Object?> get props => [profile, message];
}

/// Error state - API request failed
class FarmerProfileError extends FarmerProfileState {
  final String message;
  final FarmerProfile? currentProfile; // Keep current profile if available

  const FarmerProfileError({
    required this.message,
    this.currentProfile,
  });

  @override
  List<Object?> get props => [message, currentProfile];
}
