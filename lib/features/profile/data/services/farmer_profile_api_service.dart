import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/update_farmer_profile_dto.dart';

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
  /// Returns FarmerProfileDto wrapped in success response
  @GET('/farmer/profile')
  Future<Map<String, dynamic>> getProfile();

  /// Update current user's farmer profile
  /// PUT /api/v1/farmer/profile
  /// Requires JWT authentication
  /// UserId automatically extracted from JWT token on backend
  /// Returns success response
  @PUT('/farmer/profile')
  Future<Map<String, dynamic>> updateProfile(
    @Body() UpdateFarmerProfileDto updateDto,
  );
}
