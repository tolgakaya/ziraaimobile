import 'dart:io';
import 'dart:async';
import '../../../../core/error/plant_analysis_exceptions.dart';

/// Mock repository for testing Plant Analysis functionality
class PlantAnalysisRepository {

  /// Submit plant analysis (mock implementation)
  Future<Result<PlantAnalysisAsyncResponse>> submitPlantAnalysis({
    required File imageFile,
    String? cropType,
    String? location,
    String? notes,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock success response
    final response = PlantAnalysisAsyncResponse(
      analysisId: 'mock-analysis-${DateTime.now().millisecondsSinceEpoch}',
      estimatedTime: '30 saniye',
      queuePosition: 1,
    );

    return Result.success(response);
  }

  /// Poll analysis result (mock implementation)
  Stream<AnalysisStatusUpdate> pollAnalysisResult(
    String analysisId, {
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 10),
  }) async* {
    // Simulate processing states
    yield AnalysisStatusUpdate.processing();
    await Future.delayed(const Duration(seconds: 3));

    yield AnalysisStatusUpdate.processing();
    await Future.delayed(const Duration(seconds: 3));

    // Mock completed result
    final mockResult = PlantAnalysisResult(
      id: analysisId,
      status: 'completed',
      confidence: 95.5,
      diseases: [
        PlantDisease(
          name: 'Yaprak Leke Hastalığı',
          severity: 'Orta',
          confidence: 89.2,
          description: 'Yapraklarda kahverengi lekeler görülmektedir.',
          severityColor: '#FFA500',
        ),
      ],
      treatments: [],
      organicTreatments: [
        PlantTreatment(
          name: 'Neem Yağı Uygulaması',
          type: 'Organik',
          instructions: 'Haftada 2 kez yapraklara püskürtün.',
          frequency: 'Haftada 2 kez',
          isOrganic: true,
          treatmentIcon: '🌿',
        ),
      ],
      chemicalTreatments: [],
      createdAt: DateTime.now().toIso8601String(),
      visualIndicators: [
        VisualIndicator(
          type: 'Leke',
          location: 'Yaprak üst yüzeyi',
          confidence: 85.0,
          details: 'Kahverengi lekeler tespit edildi',
        ),
      ],
      metadata: AnalysisMetadata(
        cropType: 'Domates',
        location: 'Test Alanı',
        processingTime: 8.3,
        modelVersion: 'v2.1.0',
      ),
    );

    yield AnalysisStatusUpdate.completed(mockResult);
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