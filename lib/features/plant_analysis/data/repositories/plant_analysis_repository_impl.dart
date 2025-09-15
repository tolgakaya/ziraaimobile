import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/plant_analysis_repository.dart';
import '../datasources/plant_analysis_api_service.dart';
import '../models/plant_analysis_request.dart';
import '../models/plant_analysis_response.dart';
import '../models/analysis_result.dart';
import '../models/analysis_list_response.dart';

@LazySingleton(as: PlantAnalysisRepository)
class PlantAnalysisRepositoryImpl implements PlantAnalysisRepository {
  final PlantAnalysisApiService _apiService;

  PlantAnalysisRepositoryImpl(this._apiService);

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

      // Submit analysis
      final response = await _apiService.submitAnalysis(request);

      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(
          message: response.message ?? 'Analysis submission failed',
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
  Future<Either<Failure, AnalysisResult>> getAnalysisResult(String analysisId) async {
    try {
      final response = await _apiService.getAnalysisById(analysisId);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final result = AnalysisResult.fromJson(data['data']);
          return Right(result);
        } else {
          return Left(ServerFailure(
            message: data['message'] ?? 'Failed to get analysis result',
            code: data['errorCode'],
          ));
        }
      } else {
        return Left(ServerFailure(
          message: 'Request failed with status: ${response.response.statusCode}',
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
      final response = await _apiService.getAnalysesList(page, pageSize);

      if (response.success && response.data != null) {
        return Right(response.data!);
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
}