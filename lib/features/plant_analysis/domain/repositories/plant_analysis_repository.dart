import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/plant_analysis_response.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/analysis_list_response.dart';
import '../../data/models/plant_analysis_result.dart';

abstract class PlantAnalysisRepository {
  /// Submit single-image plant analysis
  Future<Either<Failure, PlantAnalysisData>> submitAnalysis({
    required File imageFile,
    String? notes,
    String? location,
  });

  /// Submit multi-image plant analysis
  /// Supports up to 5 images: 1 main (required) + 4 optional detail images
  Future<Either<Failure, PlantAnalysisData>> submitMultiImageAnalysis({
    required File mainImage,
    File? leafTopImage,
    File? leafBottomImage,
    File? plantOverviewImage,
    File? rootImage,
    String? notes,
    String? location,
  });

  Future<Either<Failure, AnalysisResult>> getAnalysisResult(String analysisId);

  Future<Either<Failure, AnalysisListData>> getAnalysesList({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, PlantAnalysisResult>> getAnalysisDetail(int id);
}