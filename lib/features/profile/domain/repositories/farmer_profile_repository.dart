import '../entities/farmer_profile.dart';

/// Repository interface for farmer profile operations
/// Follows Clean Architecture principles - domain layer defines contract
abstract class FarmerProfileRepository {
  /// Get current user's farmer profile
  /// Returns FarmerProfile on success
  /// Throws exception on error
  Future<FarmerProfile> getProfile();

  /// Update current user's farmer profile
  /// Parameters match backend UpdateFarmerProfileDto
  /// Returns updated FarmerProfile on success
  /// Throws exception on validation error or network error
  Future<FarmerProfile> updateProfile({
    required String fullName,
    required String email,
    required String mobilePhones,
    DateTime? birthDate,
    int? gender,
    String? address,
    String? notes,
  });
}
