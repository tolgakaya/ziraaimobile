part of 'plant_analysis_bloc.dart';

abstract class PlantAnalysisState extends Equatable {
  const PlantAnalysisState();

  @override
  List<Object?> get props => [];
}

class PlantAnalysisInitial extends PlantAnalysisState {}

class PlantAnalysisSubmitting extends PlantAnalysisState {}

class PlantAnalysisSubmitted extends PlantAnalysisState {
  final String analysisId;
  final String message;

  const PlantAnalysisSubmitted({
    required this.analysisId,
    required this.message,
  });

  @override
  List<Object?> get props => [analysisId, message];
}

class PlantAnalysisProcessing extends PlantAnalysisState {
  final String analysisId;
  final DateTime? estimatedCompletionTime;

  const PlantAnalysisProcessing({
    required this.analysisId,
    this.estimatedCompletionTime,
  });

  @override
  List<Object?> get props => [analysisId, estimatedCompletionTime];
}

class PlantAnalysisCompleted extends PlantAnalysisState {
  final AnalysisResult result;

  const PlantAnalysisCompleted(this.result);

  @override
  List<Object?> get props => [result];
}

class PlantAnalysisError extends PlantAnalysisState {
  final String message;
  final String? errorCode;

  const PlantAnalysisError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class PlantAnalysisListLoading extends PlantAnalysisState {}

class PlantAnalysisListLoaded extends PlantAnalysisState {
  final List<AnalysisSummary> analyses;
  final PaginationInfo pagination;

  const PlantAnalysisListLoaded({
    required this.analyses,
    required this.pagination,
  });

  @override
  List<Object?> get props => [analyses, pagination];
}