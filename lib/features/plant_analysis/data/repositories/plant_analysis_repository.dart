import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/error/plant_analysis_exceptions.dart';
import '../../../../core/services/image_processing_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/network_client.dart';

/// Real API repository for Plant Analysis functionality
class PlantAnalysisRepository {
  final NetworkClient _networkClient;
  final SecureStorageService _storageService;

  PlantAnalysisRepository(this._networkClient, this._storageService);

  /// Submit plant analysis using real API
  Future<Result<PlantAnalysisAsyncResponse>> submitPlantAnalysis({
    required File imageFile,
    String? cropType,
    String? location,
    String? notes,
  }) async {
    try {
      // Get authentication token
      final token = await _storageService.getToken();
      if (token == null) {
        return Result.error(
          'Authentication required',
          exception: AuthenticationException('User not authenticated'),
        );
      }

      // Convert image to base64
      final base64Image = await ImageProcessingService.convertToBase64(imageFile);

      // Prepare request data - API expects 'Image' field
      final requestData = {
        'Image': base64Image,
        'CropType': cropType,
        'Location': location,
        'Notes': notes,
      };

      // Make API call
      final response = await _networkClient.post(
        ApiConfig.plantAnalyzeAsync,
        data: requestData,
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      // Parse response
      if (response.data['success'] == true) {
        final analysisResponse = PlantAnalysisAsyncResponse(
          analysisId: response.data['analysis_id'],
          estimatedTime: response.data['estimated_processing_time'],
          queuePosition: null, // API doesn't return queue position
        );
        return Result.success(analysisResponse);
      } else {
        return Result.error(
          response.data['message'] ?? 'Analysis submission failed',
          exception: AnalysisSubmissionException(
            response.data['message'] ?? 'Unknown error',
          ),
        );
      }
    } catch (e) {
      if (e is DioException) {
        // Handle 403 Forbidden specifically
        if (e.response?.statusCode == 403) {
          return Result.error(
            'Quota exceeded',
            exception: QuotaExceededException(
              'Analysis quota exceeded',
              quotaType: 'daily', // This will be determined by real API response
              errorCode: '403',
              originalError: e,
            ),
          );
        }

        return Result.error(
          'Network error: ${e.message}',
          exception: NetworkException(
            'Failed to submit analysis: ${e.message}',
            originalError: e,
          ),
        );
      }
      return Result.error(
        'Unexpected error: ${e.toString()}',
        exception: NetworkException(
          'Unexpected error during analysis submission',
          originalError: e,
        ),
      );
    }
  }

  /// Poll analysis result using real API
  Stream<AnalysisStatusUpdate> pollAnalysisResult(
    String analysisId, {
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 10),
  }) async* {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      try {
        // Get authentication token
        final token = await _storageService.getToken();
        if (token == null) {
          yield AnalysisStatusUpdate.error(
            AuthenticationException('User not authenticated'),
          );
          return;
        }

        // Make API call to check status
        final response = await _networkClient.get(
          '${ApiConfig.plantAnalysisDetail}/$analysisId',
          options: Options(
            headers: ApiConfig.authHeader(token),
          ),
        );

        if (response.data['success'] == true) {
          final data = response.data['data'];
          final status = data['status']?.toString().toLowerCase();

          if (status == 'completed') {
            // Parse completed result
            final result = _parseAnalysisResult(data);
            yield AnalysisStatusUpdate.completed(result);
            return;
          } else if (status == 'failed' || status == 'error') {
            yield AnalysisStatusUpdate.error(
              AnalysisProcessingException(
                data['errorMessage'] ?? 'Analysis failed',
              ),
            );
            return;
          } else {
            // Still processing
            yield AnalysisStatusUpdate.processing();
          }
        } else {
          yield AnalysisStatusUpdate.error(
            NetworkException(
              response.data['message'] ?? 'Failed to get analysis status',
            ),
          );
          return;
        }
      } catch (e) {
        if (e is DioException) {
          yield AnalysisStatusUpdate.error(
            NetworkException(
              'Network error: ${e.message}',
              originalError: e,
            ),
          );
          return;
        }
        yield AnalysisStatusUpdate.error(
          NetworkException(
            'Unexpected error: ${e.toString()}',
            originalError: e,
          ),
        );
        return;
      }

      // Wait before next poll
      await Future.delayed(interval);
    }

    // Timeout reached
    yield AnalysisStatusUpdate.error(
      AnalysisTimeoutException('Analysis timed out after ${timeout.inMinutes} minutes'),
    );
  }

  /// Parse API response to PlantAnalysisResult
  PlantAnalysisResult _parseAnalysisResult(Map<String, dynamic> data) {
    try {
      return PlantAnalysisResult(
        id: data['id']?.toString() ?? '',
        status: data['status']?.toString() ?? 'unknown',
        confidence: (data['confidence'] ?? 0.0).toDouble(),
        diseases: _parseDiseases(data['diseases'] ?? []),
        treatments: _parseTreatments(data['treatments'] ?? []),
        organicTreatments: _parseTreatments(data['organicTreatments'] ?? []),
        chemicalTreatments: _parseTreatments(data['chemicalTreatments'] ?? []),
        createdAt: data['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        visualIndicators: _parseVisualIndicators(data['visualIndicators'] ?? []),
        metadata: _parseMetadata(data['metadata'] ?? {}),
      );
    } catch (e) {
      throw AnalysisParsingException(
        'Failed to parse analysis result: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Parse diseases from API response
  List<PlantDisease> _parseDiseases(List<dynamic> diseasesData) {
    return diseasesData.map((disease) {
      return PlantDisease(
        name: disease['name']?.toString() ?? '',
        severity: disease['severity']?.toString() ?? '',
        confidence: (disease['confidence'] ?? 0.0).toDouble(),
        description: disease['description']?.toString(),
        severityColor: disease['severityColor']?.toString() ?? '#FFA500',
      );
    }).toList();
  }

  /// Parse treatments from API response
  List<PlantTreatment> _parseTreatments(List<dynamic> treatmentsData) {
    return treatmentsData.map((treatment) {
      return PlantTreatment(
        name: treatment['name']?.toString() ?? '',
        type: treatment['type']?.toString() ?? '',
        instructions: treatment['instructions']?.toString() ?? '',
        frequency: treatment['frequency']?.toString(),
        isOrganic: treatment['isOrganic'] == true,
        treatmentIcon: treatment['treatmentIcon']?.toString() ?? '💊',
      );
    }).toList();
  }

  /// Parse visual indicators from API response
  List<VisualIndicator> _parseVisualIndicators(List<dynamic> indicatorsData) {
    return indicatorsData.map((indicator) {
      return VisualIndicator(
        type: indicator['type']?.toString() ?? '',
        location: indicator['location']?.toString() ?? '',
        confidence: (indicator['confidence'] ?? 0.0).toDouble(),
        details: indicator['details']?.toString(),
      );
    }).toList();
  }

  /// Parse metadata from API response
  AnalysisMetadata _parseMetadata(Map<String, dynamic> metadataData) {
    return AnalysisMetadata(
      cropType: metadataData['cropType']?.toString(),
      location: metadataData['location']?.toString(),
      notes: metadataData['notes']?.toString(),
      processingTime: (metadataData['processingTime'] ?? 0.0).toDouble(),
      modelVersion: metadataData['modelVersion']?.toString(),
    );
  }
}

/// Mock async response model
class PlantAnalysisAsyncResponse {
  final String analysisId;
  final String? estimatedTime;
  final int? queuePosition;

  PlantAnalysisAsyncResponse({
    required this.analysisId,
    this.estimatedTime,
    this.queuePosition,
  });
}

/// Mock plant analysis result
class PlantAnalysisResult {
  final String id;
  final String status;
  final double confidence;
  final List<PlantDisease> diseases;
  final List<PlantTreatment> treatments;
  final List<PlantTreatment> organicTreatments;
  final List<PlantTreatment> chemicalTreatments;
  final String createdAt;
  final List<VisualIndicator>? visualIndicators;
  final AnalysisMetadata? metadata;

  PlantAnalysisResult({
    required this.id,
    required this.status,
    required this.confidence,
    required this.diseases,
    required this.treatments,
    required this.organicTreatments,
    required this.chemicalTreatments,
    required this.createdAt,
    this.visualIndicators,
    this.metadata,
  });

  bool get isSuccessful => status == 'completed';
}

/// Mock plant disease
class PlantDisease {
  final String name;
  final String severity;
  final double confidence;
  final String? description;
  final String severityColor;

  PlantDisease({
    required this.name,
    required this.severity,
    required this.confidence,
    this.description,
    required this.severityColor,
  });
}

/// Mock plant treatment
class PlantTreatment {
  final String name;
  final String type;
  final String instructions;
  final String? frequency;
  final bool isOrganic;
  final String treatmentIcon;

  PlantTreatment({
    required this.name,
    required this.type,
    required this.instructions,
    this.frequency,
    required this.isOrganic,
    required this.treatmentIcon,
  });
}

/// Analysis status update for polling
class AnalysisStatusUpdate {
  final AnalysisStatus status;
  final PlantAnalysisResult? result;
  final PlantAnalysisException? exception;

  AnalysisStatusUpdate._(this.status, this.result, this.exception);

  factory AnalysisStatusUpdate.processing() =>
      AnalysisStatusUpdate._(AnalysisStatus.processing, null, null);

  factory AnalysisStatusUpdate.completed(PlantAnalysisResult result) =>
      AnalysisStatusUpdate._(AnalysisStatus.completed, result, null);

  factory AnalysisStatusUpdate.error(PlantAnalysisException error) =>
      AnalysisStatusUpdate._(AnalysisStatus.error, null, error);

  bool get isProcessing => status == AnalysisStatus.processing;
  bool get isCompleted => status == AnalysisStatus.completed;
  bool get isError => status == AnalysisStatus.error;
  bool get isTimeout => status == AnalysisStatus.timeout;
  String? get errorMessage => exception?.message;
}

enum AnalysisStatus {
  processing,
  completed,
  error,
  timeout,
}

/// Visual indicator model
class VisualIndicator {
  final String type;
  final String location;
  final double confidence;
  final String? details;

  VisualIndicator({
    required this.type,
    required this.location,
    required this.confidence,
    this.details,
  });
}

/// Analysis metadata model
class AnalysisMetadata {
  final String? cropType;
  final String? location;
  final String? notes;
  final double? processingTime;
  final String? modelVersion;

  AnalysisMetadata({
    this.cropType,
    this.location,
    this.notes,
    this.processingTime,
    this.modelVersion,
  });
}

/// Disease detection model
class DiseaseDetection {
  final String name;
  final String severity;
  final double confidence;
  final String? description;

  DiseaseDetection({
    required this.name,
    required this.severity,
    required this.confidence,
    this.description,
  });
}

/// Treatment recommendation model
class TreatmentRecommendation {
  final String name;
  final String description;
  final bool isOrganic;
  final String? frequency;

  TreatmentRecommendation({
    required this.name,
    required this.description,
    required this.isOrganic,
    this.frequency,
  });
}

/// Generic result wrapper
class Result<T> {
  final T? data;
  final String? error;
  final PlantAnalysisException? exception;
  final bool isSuccess;

  Result._(this.data, this.error, this.exception, this.isSuccess);

  factory Result.success(T data) => Result._(data, null, null, true);
  factory Result.error(String error, {PlantAnalysisException? exception}) =>
      Result._(null, error, exception, false);

  bool get isError => !isSuccess;
}