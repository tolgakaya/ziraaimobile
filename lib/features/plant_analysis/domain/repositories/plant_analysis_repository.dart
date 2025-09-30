import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/plant_analysis_response.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/analysis_list_response.dart';
import '../../data/models/plant_analysis_result.dart';

abstract class PlantAnalysisRepository {
  Future<Either<Failure, PlantAnalysisData>> submitAnalysis({
    required File imageFile,
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