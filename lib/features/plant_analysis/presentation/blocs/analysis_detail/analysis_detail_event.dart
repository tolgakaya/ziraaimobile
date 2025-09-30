import 'package:equatable/equatable.dart';

abstract class AnalysisDetailEvent extends Equatable {
  const AnalysisDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalysisDetail extends AnalysisDetailEvent {
  final int analysisId;  // Changed to int for numeric ID

  const LoadAnalysisDetail({required this.analysisId});

  @override
  List<Object?> get props => [analysisId];
}

class RefreshAnalysisDetail extends AnalysisDetailEvent {
  final int analysisId;  // Changed to int for numeric ID

  const RefreshAnalysisDetail({required this.analysisId});

  @override
  List<Object?> get props => [analysisId];
}