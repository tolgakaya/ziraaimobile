import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:injectable/injectable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../models/plant_analysis_request.dart';
import '../models/plant_analysis_response.dart';
import '../../../../core/models/api_response.dart';

part 'plant_analysis_api_service.g.dart';

@RestApi()
@injectable
abstract class PlantAnalysisApiService {
  @factoryMethod
  factory PlantAnalysisApiService(Dio dio, {String baseUrl}) = _PlantAnalysisApiService;

  /// Submit plant analysis for asynchronous processing
  @POST('/api/v1/plantanalyses/analyze-async')
  Future<ApiResponse<PlantAnalysisAsyncResponse>> submitAnalysisAsync(
    @Body() PlantAnalysisRequest request,
    @Header('Authorization') String authorization,
  );

  /// Get analysis result by ID
  @GET('/api/v1/plantanalyses/{id}')
  Future<ApiResponse<PlantAnalysisResult>> getAnalysisResult(
    @Path('id') String analysisId,
    @Header('Authorization') String authorization,
  );

  /// Get analysis status for polling
  @GET('/api/v1/plantanalyses/{id}/status')
  Future<ApiResponse<AnalysisStatus>> getAnalysisStatus(
    @Path('id') String analysisId,
    @Header('Authorization') String authorization,
  );

  /// Get user's analysis history
  @GET('/api/v1/plantanalyses/list')
  Future<ApiResponse<List<PlantAnalysisResult>>> getUserAnalyses(
    @Header('Authorization') String authorization,
    @Query('page') int page,
    @Query('limit') int limit,
  );
}

/// Analysis status enum for API response
enum AnalysisStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('timeout')
  timeout,
}