import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/update_farmer_profile_dto.dart';
import '../models/farmer_profile_response.dart';

part 'farmer_profile_api_service.g.dart';

/// Farmer Profile API service using Retrofit
/// Endpoints: /api/v1/farmer/profile
@RestApi()
abstract class FarmerProfileApiService {
  factory FarmerProfileApiService(Dio dio, {String baseUrl}) =
      _FarmerProfileApiService;

  /// Get current user's farmer profile
  /// GET /api/v1/farmer/profile
  /// Requires JWT authentication
  /// Returns FarmerProfileResponse with FarmerProfileDto data
  @GET('/farmer/profile')
  Future<FarmerProfileResponse> getProfile();

  /// Update current user's farmer profile
  /// PUT /api/v1/farmer/profile
  /// Requires JWT authentication
  /// UserId automatically extracted from JWT token on backend
  /// Returns ProfileUpdateResponse
  ///
  /// Note: Backend returns {"success": true, "message": "Updated"}
  /// without a data field for successful updates
  @PUT('/farmer/profile')
  Future<ProfileUpdateResponse> updateProfile(
    @Body() UpdateFarmerProfileDto updateDto,
  );
}
