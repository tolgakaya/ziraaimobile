import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:injectable/injectable.dart';
import '../models/plant_analysis_request.dart';
import '../models/plant_analysis_response.dart';
import '../models/plant_analysis_response_new.dart';
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

  /// Get analyses list for dashboard
  @GET('/api/v1/plantanalyses/list')
  Future<ApiResponse<PlantAnalysisListResponse>> getAnalysesList(
    @Header('Authorization') String authorization,
    @Query('page') int page,
    @Query('pageSize') int pageSize,
  );
}