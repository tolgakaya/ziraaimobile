part of 'plant_analysis_bloc.dart';

abstract class PlantAnalysisEvent extends Equatable {
  const PlantAnalysisEvent();

  @override
  List<Object?> get props => [];
}

class SubmitAnalysisEvent extends PlantAnalysisEvent {
  final File imageFile;
  final String? notes;
  final String? location;

  const SubmitAnalysisEvent({
    required this.imageFile,
    this.notes,
    this.location,
  });

  @override
  List<Object?> get props => [imageFile, notes, location];
}

class CheckAnalysisStatusEvent extends PlantAnalysisEvent {
  final String analysisId;

  const CheckAnalysisStatusEvent(this.analysisId);

  @override
  List<Object?> get props => [analysisId];
}

class LoadAnalysesListEvent extends PlantAnalysisEvent {
  final int page;
  final int pageSize;

  const LoadAnalysesListEvent({
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [page, pageSize];
}

class StartPollingEvent extends PlantAnalysisEvent {
  final String analysisId;

  const StartPollingEvent(this.analysisId);

  @override
  List<Object?> get props => [analysisId];
}

class StopPollingEvent extends PlantAnalysisEvent {}