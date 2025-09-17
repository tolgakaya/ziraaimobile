import 'package:equatable/equatable.dart';
import '../../../data/models/plant_analysis_result.dart';

abstract class AnalysisDetailState extends Equatable {
  const AnalysisDetailState();

  @override
  List<Object?> get props => [];
}

class AnalysisDetailInitial extends AnalysisDetailState {}

class AnalysisDetailLoading extends AnalysisDetailState {}

class AnalysisDetailLoaded extends AnalysisDetailState {
  final PlantAnalysisResult analysisResult;

  const AnalysisDetailLoaded({required this.analysisResult});

  @override
  List<Object?> get props => [analysisResult];
}

class AnalysisDetailError extends AnalysisDetailState {
  final String message;

  const AnalysisDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}