import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:injectable/injectable.dart';
import '../models/plant_analysis_request.dart';
import '../models/plant_analysis_multi_image_request.dart';
import '../models/plant_analysis_response.dart';
import '../models/plant_analysis_response_new.dart';
import '../models/plant_analysis_detail_dto.dart';
import '../models/analysis_list_response.dart';
import '../../../../core/models/api_response.dart';

part 'plant_analysis_api_service.g.dart';

@RestApi()
@injectable
abstract class PlantAnalysisApiService {
  @factoryMethod
  factory PlantAnalysisApiService(Dio dio, {String baseUrl}) = _PlantAnalysisApiService;

  /// Submit plant analysis for asynchronous processing
  /// NOTE: Authorization header is automatically added by Dio interceptor
  @POST('/plantanalyses/analyze-async')
  Future<ApiResponse<PlantAnalysisAsyncResponse>> submitAnalysisAsync(
    @Body() PlantAnalysisRequest request,
  );

  /// Submit multi-image plant analysis for asynchronous processing
  /// Supports up to 5 images: 1 main (required) + 4 optional detail images
  /// NOTE: Authorization header is automatically added by Dio interceptor
  @POST('/plantanalyses/analyze-multi-async')
  Future<ApiResponse<PlantAnalysisAsyncResponse>> submitMultiImageAnalysisAsync(
    @Body() PlantAnalysisMultiImageRequest request,
  );

  /// Get analysis result by ID (deprecated - use getAnalysisDetail)
  /// NOTE: Authorization header is automatically added by Dio interceptor
  @GET('/plantanalyses/{id}')
  Future<ApiResponse<PlantAnalysisResult>> getAnalysisResult(
    @Path('id') String analysisId,
  );

  /// Get analyses list for dashboard
  /// NOTE: Authorization header is automatically added by Dio interceptor
  @GET('/plantanalyses/list')
  Future<ApiResponse<PlantAnalysisListResponse>> getAnalysesList(
    @Query('page') int page,
    @Query('pageSize') int pageSize,
  );
}