import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import 'dart:developer' as developer;

@lazySingleton
class SponsorService {
  final Dio _dio;
  final AuthService _authService;

  SponsorService({
    required Dio dio,
    required AuthService authService,
  })  : _dio = dio,
        _authService = authService;

  /// Create sponsor profile for phone-registered user
  /// This upgrades a Farmer to dual-role (Farmer + Sponsor)
  /// Tier will be assigned after purchasing a package
  Future<Map<String, dynamic>> createSponsorProfile({
    required String companyName,
    required String businessEmail,
    required String password,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      developer.log(
        'Creating sponsor profile: $companyName',
        name: 'SponsorService',
      );

      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}${ApiConfig.createSponsorProfile}',
        data: {
          'companyName': companyName,
          'businessEmail': businessEmail,
          'password': password,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      developer.log(
        'Sponsor profile created successfully',
        name: 'SponsorService',
      );

      return response.data;
    } on DioException catch (e) {
      developer.log(
        'Failed to create sponsor profile',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ??
                           e.response?.data['title'] ??
                           'Failed to create sponsor profile';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error creating sponsor profile',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get sponsor profile details
  Future<Map<String, dynamic>> getSponsorProfile() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}${ApiConfig.getSponsorProfile}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      developer.log(
        'Failed to get sponsor profile',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ??
                           'Failed to load sponsor profile';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    }
  }
}
