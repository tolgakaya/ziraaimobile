import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:injectable/injectable.dart';
import '../models/plant_analysis_request.dart';
import '../models/plant_analysis_response.dart';
import '../models/analysis_result.dart';
import '../models/analysis_list_response.dart';

part 'plant_analysis_api_service.g.dart';

@RestApi()
@injectable
abstract class PlantAnalysisApiService {
  @factoryMethod
  factory PlantAnalysisApiService(Dio dio, {String baseUrl}) = _PlantAnalysisApiService;

  @POST('/plantanalyses/analyze-async')
  Future<PlantAnalysisResponse> submitAnalysis(
    @Body() PlantAnalysisRequest request,
  );

  @GET('/plantanalyses/{id}')
  Future<AnalysisResult> getAnalysisById(
    @Path('id') int analysisId,
  );

  @GET('/plantanalyses/list')
  Future<AnalysisListResponse> getAnalysesList(
    @Query('page') int page,
    @Query('pageSize') int pageSize,
  );
}