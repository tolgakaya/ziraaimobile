import 'dart:convert';
import 'dart:io';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/plant_analysis_repository.dart';
import '../services/plant_analysis_api_service.dart';
import '../models/plant_analysis_request.dart';
import '../models/plant_analysis_response.dart';
import '../models/analysis_result.dart';
import '../models/analysis_list_response.dart';
import '../models/plant_analysis_result.dart';
import '../models/api_to_simple_converter.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/config/api_config.dart';

@LazySingleton(as: PlantAnalysisRepository)
class PlantAnalysisRepositoryImpl implements PlantAnalysisRepository {
  final PlantAnalysisApiService _apiService;
  final AuthService _authService;

  PlantAnalysisRepositoryImpl(this._apiService, this._authService);

  @override
  Future<Either<Failure, PlantAnalysisData>> submitAnalysis({
    required File imageFile,
    String? notes,
    String? location,
  }) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare request
      final request = PlantAnalysisRequest(
        image: 'data:image/jpeg;base64,$base64Image',
        notes: notes,
        location: location,
        cropType: null, // Auto-detect
      );

      // Submit analysis - using Dio directly because backend returns flat JSON (no data wrapper)
      final token = await _authService.getToken();
      final dio = Dio();
      final apiResponse = await dio.post(
        'https://ziraai-api-sit.up.railway.app/api/v1/plantanalyses/analyze-async',
        data: request.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('🚀 PlantAnalysisRepository: API Response received');
      print('   statusCode: ${apiResponse.statusCode}');
      print('   data: ${apiResponse.data}');

      final Map<String, dynamic> responseData = apiResponse.data as Map<String, dynamic>;

      // Backend returns flat JSON with snake_case fields
      final success = responseData['success'] as bool? ?? false;
      final message = responseData['message'] as String? ?? '';
      final analysisId = responseData['analysis_id'] as String? ?? '';

      print('   success: $success');
      print('   message: $message');
      print('   analysis_id: $analysisId');

      // Check if analysis was queued successfully
      if (success && analysisId.isNotEmpty) {
        print('✅ PlantAnalysisRepository: Analysis queued successfully!');
        final plantAnalysisData = PlantAnalysisData(
          analysisId: analysisId,
          status: 'queued',
          message: message,
        );
        return Right(plantAnalysisData);
      } else {
        print('❌ PlantAnalysisRepository: Analysis submission failed');
        return Left(ServerFailure(
          message: message.isNotEmpty ? message : 'Analysis submission failed',
          code: null,
        ));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      print('❌ PlantAnalysisRepository: Exception: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AnalysisResult>> getAnalysisResult(String analysisId) async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.getAnalysisResult(analysisId, 'Bearer $token');

      if (response.success && response.data != null) {
        // Convert PlantAnalysisResult to AnalysisResult
        final analysisResult = AnalysisResult(
          id: response.data!.id.toString(),
          status: response.data!.status,
          plantType: 'Plant', // Default value since not available in new model
          imageUrl: response.data!.imagePath ?? '',
          createdAt: DateTime.tryParse(response.data!.analysisDate),
        );
        return Right(analysisResult);
      } else {
        return Left(ServerFailure(
          message: response.message ?? 'Failed to get analysis result',
          code: response.errorCode,
        ));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AnalysisListData>> getAnalysesList({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await _apiService.getAnalysesList('Bearer $token', page, pageSize);

      if (response.success && response.data != null) {
        // Convert PlantAnalysisListResponse to AnalysisListData
        // Convert PlantAnalysisListItem to AnalysisSummary
        final convertedAnalyses = response.data!.analyses.map<AnalysisSummary>((item) => AnalysisSummary(
          id: item.id ?? 0, // Backend sends int id
          plantType: item.plantSpecies ?? 'Unknown',
          healthStatus: item.status ?? 'Unknown',
          date: item.createdDate ?? DateTime.now(),
          thumbnailUrl: item.thumbnailUrl ?? '',
        )).toList();

        final analysisListData = AnalysisListData(
          analyses: convertedAnalyses,
          pagination: response.data!.pagination != null ? PaginationInfo(
            page: page,
            totalPages: 1, // Default değer - API'den gelmiyorsa
            totalItems: convertedAnalyses.length,
            pageSize: pageSize,
          ) : null,
        );
        return Right(analysisListData);
      } else {
        return Left(ServerFailure(
          message: response.message ?? 'Failed to get analyses list',
        ));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(message: 'Connection timeout');

      case DioExceptionType.connectionError:
        return NetworkFailure(message: 'No internet connection');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 401) {
          return AuthenticationFailure(message: 'Authentication failed');
        } else if (statusCode == 403) {
          return AuthorizationFailure(message: 'Access denied');
        } else if (statusCode == 429) {
          return QuotaExceededFailure(message: 'Analysis quota exceeded');
        } else if (data != null && data is Map) {
          return ServerFailure(
            message: data['message'] ?? 'Server error',
            code: data['errorCode'],
          );
        } else {
          return ServerFailure(
            message: 'Server error: $statusCode',
          );
        }

      default:
        return ServerFailure(message: error.message ?? 'Unknown error');
    }
  }

  @override
  Future<Either<Failure, PlantAnalysisResult>> getAnalysisDetail(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return Left(AuthenticationFailure(message: 'No authentication token'));
      }

      // Direct HTTP call since Retrofit has issues with Map<String, dynamic>
      final dio = Dio();
      final url = '${ApiConfig.apiBaseUrl}${ApiConfig.plantAnalysisDetail}/$id/detail';
      print('🔗 CLAUDE: Making detail request to: $url');
      print('🔑 CLAUDE: Auth token length: ${token.length}');

      final response = await dio.get(
        url,
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      print('📡 CLAUDE: Detail response status: ${response.statusCode}');
      
      // Print raw response to see what we're actually getting
      print('🔍 RAW RESPONSE TYPE: ${response.data.runtimeType}');
      
      // Convert response to JSON string and print
      try {
        final jsonString = jsonEncode(response.data);
        print('📝 RAW RESPONSE LENGTH: ${jsonString.length} characters');
        
        // Print more of the response to see what's being cut off
        print('📝 FULL RAW RESPONSE:');
        // Print in chunks to avoid log truncation
        for (int i = 0; i < jsonString.length; i += 1000) {
          int end = (i + 1000 < jsonString.length) ? i + 1000 : jsonString.length;
          print('CHUNK ${i ~/ 1000 + 1}: ${jsonString.substring(i, end)}');
        }
        
        // Check if farmerFriendlySummary exists in raw response
        if (jsonString.contains('farmerFriendlySummary')) {
          print('✅ farmerFriendlySummary FOUND in raw response!');
          
          // Find its position
          int index = jsonString.indexOf('farmerFriendlySummary');
          print('📍 farmerFriendlySummary at position: $index');
          
          // Print surrounding context
          int start = index > 50 ? index - 50 : 0;
          int end = index + 200 < jsonString.length ? index + 200 : jsonString.length;
          print('📝 Context: ${jsonString.substring(start, end)}');
        } else {
          print('❌ farmerFriendlySummary NOT FOUND in raw response!');
        }
      } catch (e) {
        print('❌ Error encoding response: $e');
      }
      print('📄 CLAUDE: Detail response data type: ${response.data.runtimeType}');
      print('📄 CLAUDE: Response data keys: ${response.data.keys.toList()}');
      
      // Check if data field exists
      if (response.data['data'] != null) {
        final dataField = response.data['data'] as Map<String, dynamic>;
        print('📄 CLAUDE: data field keys: ${dataField.keys.toList()}');
        print('🔍 CLAUDE: farmerFriendlySummary in data: ${dataField['farmerFriendlySummary']}');
        
        // Check specific fields
        if (dataField.containsKey('farmerFriendlySummary')) {
          print('✅ CLAUDE: farmerFriendlySummary EXISTS in data field!');
          print('📝 CLAUDE: farmerFriendlySummary content: ${dataField['farmerFriendlySummary']}');
        } else {
          print('❌ CLAUDE: farmerFriendlySummary NOT FOUND in data field');
        }
      }

      if (response.statusCode == 200 && response.data != null) {
        // Get the actual data from response
        Map<String, dynamic> finalData;
        
        if (response.data.containsKey('data')) {
          // Extract data field
          finalData = Map<String, dynamic>.from(response.data['data']);
          print('📦 CLAUDE: Extracted data from wrapper');
          print('🔑 CLAUDE: All keys in data: ${finalData.keys.toList()}');
          
          // Verify critical fields
          print('✅ CLAUDE: Has farmerFriendlySummary: ${finalData.containsKey('farmerFriendlySummary')}');
          print('✅ CLAUDE: Has pestDisease: ${finalData.containsKey('pestDisease')}');
          print('✅ CLAUDE: Has environmentalStress: ${finalData.containsKey('environmentalStress')}');
          print('✅ CLAUDE: Has imageInfo: ${finalData.containsKey('imageInfo')}');
          print('✅ CLAUDE: Has riskAssessment: ${finalData.containsKey('riskAssessment')}');
          print('✅ CLAUDE: Has confidenceNotes: ${finalData.containsKey('confidenceNotes')}');
          
          if (finalData.containsKey('farmerFriendlySummary')) {
            print('🌾 CLAUDE: farmerFriendlySummary content: ${finalData['farmerFriendlySummary']}');
          }
        } else {
          finalData = Map<String, dynamic>.from(response.data);
        }
        
        print('🔄 CLAUDE: Converting to model with ${finalData.keys.length} keys');
        
        // Convert API response to our model using the converter
        final result = ApiToSimpleConverter.convertApiResponse(finalData);
        return Right(result);
      } else {
        return Left(ServerFailure(
          message: 'Failed to get analysis detail',
        ));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Error parsing analysis detail: ${e.toString()}'));
    }
  }
}