import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../constants/api_constants.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // Authentication endpoints
  @POST(ApiConstants.login)
  Future<HttpResponse<Map<String, dynamic>>> login(
    @Body() Map<String, dynamic> loginRequest,
  );

  @POST(ApiConstants.register)
  Future<HttpResponse<Map<String, dynamic>>> register(
    @Body() Map<String, dynamic> registerRequest,
  );

  @POST(ApiConstants.refreshToken)
  Future<HttpResponse<Map<String, dynamic>>> refreshToken(
    @Body() Map<String, dynamic> tokenRequest,
  );

  @POST(ApiConstants.forgotPassword)
  Future<HttpResponse<Map<String, dynamic>>> forgotPassword(
    @Body() Map<String, dynamic> forgotPasswordRequest,
  );

  // Plant Analysis endpoints
  @POST(ApiConstants.analyzeSync)
  Future<HttpResponse<Map<String, dynamic>>> analyzeSync(
    @Body() Map<String, dynamic> analysisRequest,
  );

  @POST(ApiConstants.analyzeAsync)
  Future<HttpResponse<Map<String, dynamic>>> analyzeAsync(
    @Body() Map<String, dynamic> analysisRequest,
  );

  @GET('${ApiConstants.getAnalysisStatus}/{taskId}')
  Future<HttpResponse<Map<String, dynamic>>> getAnalysisStatus(
    @Path('taskId') String taskId,
  );

  @GET(ApiConstants.getAnalysisList)
  Future<HttpResponse<Map<String, dynamic>>> getAnalysisList(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET('${ApiConstants.getAnalysisById}/{id}')
  Future<HttpResponse<Map<String, dynamic>>> getAnalysisById(
    @Path('id') int id,
  );

  // Subscription endpoints
  @GET(ApiConstants.getTiers)
  Future<HttpResponse<Map<String, dynamic>>> getSubscriptionTiers();

  @GET(ApiConstants.getMySubscription)
  Future<HttpResponse<Map<String, dynamic>>> getMySubscription();

  @GET(ApiConstants.getUsageStatus)
  Future<HttpResponse<Map<String, dynamic>>> getUsageStatus();

  @POST(ApiConstants.subscribe)
  Future<HttpResponse<Map<String, dynamic>>> subscribe(
    @Body() Map<String, dynamic> subscriptionRequest,
  );

  @POST(ApiConstants.redeemCode)
  Future<HttpResponse<Map<String, dynamic>>> redeemCode(
    @Body() Map<String, dynamic> redeemRequest,
  );

  // Sponsorship endpoints
  @GET('${ApiConstants.validateCode}/{code}')
  Future<HttpResponse<Map<String, dynamic>>> validateSponsorshipCode(
    @Path('code') String code,
  );

  @POST(ApiConstants.redeemSponsorCode)
  Future<HttpResponse<Map<String, dynamic>>> redeemSponsorshipCode(
    @Body() Map<String, dynamic> redeemRequest,
  );

  @GET(ApiConstants.getMySponsor)
  Future<HttpResponse<Map<String, dynamic>>> getMySponsor();

  @GET('${ApiConstants.getSponsorProfile}/{sponsorId}')
  Future<HttpResponse<Map<String, dynamic>>> getSponsorProfile(
    @Path('sponsorId') int sponsorId,
  );

  // Localization endpoints
  @GET(ApiConstants.getLanguages)
  Future<HttpResponse<Map<String, dynamic>>> getLanguages();

  @GET(ApiConstants.getTranslations)
  Future<HttpResponse<Map<String, dynamic>>> getTranslations(
    @Query('language') String language,
  );
}