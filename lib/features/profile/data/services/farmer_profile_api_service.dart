import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/update_farmer_profile_dto.dart';

part 'farmer_profile_api_service.g.dart';

/// Farmer Profile API service using Retrofit
/// Endpoints: /api/v1/farmer/profile
///
/// NOTE: Retrofit generator bug with Map<String, dynamic> return types
/// After running build_runner, manually fix the generated file (.g.dart):
/// Replace the complex map transformation blocks with:
///   final _result = await _dio.fetch<Map<String, dynamic>>(_options);
///   final _value = _result.data!;
///   return _value;
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
