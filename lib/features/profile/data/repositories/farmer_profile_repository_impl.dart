import '../../domain/entities/farmer_profile.dart';
import '../../domain/repositories/farmer_profile_repository.dart';
import '../services/farmer_profile_api_service.dart';
import '../models/update_farmer_profile_dto.dart';
import 'package:intl/intl.dart';

/// Implementation of FarmerProfileRepository
/// Handles API communication and data transformation
class FarmerProfileRepositoryImpl implements FarmerProfileRepository {
  final FarmerProfileApiService _apiService;

  FarmerProfileRepositoryImpl(this._apiService);

  @override
  Future<FarmerProfile> getProfile() async {
    try {
      print('📞 FarmerProfileRepository: Fetching profile from API...');

      final response = await _apiService.getProfile();

      print('📥 FarmerProfileRepository: Response received');

      if (!response.success || response.data == null) {
        throw Exception(response.message ?? 'Profile data is null');
      }

      print('✅ FarmerProfileRepository: Profile data received');

      // Convert DTO to entity
      return response.data!.toEntity();
    } catch (e, stackTrace) {
      print('❌ FarmerProfileRepository: Error getting profile: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<FarmerProfile> updateProfile({
    required String fullName,
    required String email,
    required String mobilePhones,
    DateTime? birthDate,
    int? gender,
    String? address,
    String? notes,
  }) async {
    try {
      print('📞 FarmerProfileRepository: Updating profile...');

      // Format birthDate to ISO 8601 string (YYYY-MM-DD)
      String? birthDateStr;
      if (birthDate != null) {
        birthDateStr = DateFormat('yyyy-MM-dd').format(birthDate);
      }

      // Create update DTO
      final updateDto = UpdateFarmerProfileDto(
        fullName: fullName,
        email: email,
        mobilePhones: mobilePhones,
        birthDate: birthDateStr,
        gender: gender,
        address: address,
        notes: notes,
      );

      print('📤 FarmerProfileRepository: Sending update request...');
      print('📤 Update DTO: ${updateDto.toJson()}');

      final response = await _apiService.updateProfile(updateDto);

      print('📥 FarmerProfileRepository: Update response received');
      print('📥 Response success: ${response.success}');
      print('📥 Response message: ${response.message}');
      print('📥 Response data: ${response.data}');

      if (response.success) {
        print('✅ FarmerProfileRepository: Profile updated successfully');

        // After successful update, fetch the updated profile
        return await getProfile();
      } else {
        final errorMessage = response.message ?? 'Failed to update profile';
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('❌ FarmerProfileRepository: Error updating profile: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
