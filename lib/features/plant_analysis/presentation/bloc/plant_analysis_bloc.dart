import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/analysis_list_response.dart';
import '../../domain/repositories/plant_analysis_repository.dart';

part 'plant_analysis_event.dart';
part 'plant_analysis_state.dart';

@injectable
class PlantAnalysisBloc extends Bloc<PlantAnalysisEvent, PlantAnalysisState> {
  final PlantAnalysisRepository _repository;
  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 150; // 5 minutes with 2-second intervals

  PlantAnalysisBloc(this._repository) : super(PlantAnalysisInitial()) {
    on<SubmitAnalysisEvent>(_onSubmitAnalysis);
    on<CheckAnalysisStatusEvent>(_onCheckAnalysisStatus);
    on<LoadAnalysesListEvent>(_onLoadAnalysesList);
    on<StartPollingEvent>(_onStartPolling);
    on<StopPollingEvent>(_onStopPolling);
  }

  Future<void> _onSubmitAnalysis(
    SubmitAnalysisEvent event,
    Emitter<PlantAnalysisState> emit,
  ) async {
    emit(PlantAnalysisSubmitting());

    final result = await _repository.submitAnalysis(
      imageFile: event.imageFile,
      notes: event.notes,
      location: event.location,
    );

    result.fold(
      (failure) => emit(PlantAnalysisError(
        message: failure.message,
        errorCode: failure.code,
      )),
      (data) {
        emit(PlantAnalysisSubmitted(
          analysisId: data.analysisId,
          message: data.message ?? 'Analysis started successfully',
        ));
        // Automatically start polling
        add(StartPollingEvent(data.analysisId));
      },
    );
  }

  Future<void> _onCheckAnalysisStatus(
    CheckAnalysisStatusEvent event,
    Emitter<PlantAnalysisState> emit,
  ) async {
    final result = await _repository.getAnalysisResult(event.analysisId);

    result.fold(
      (failure) => emit(PlantAnalysisError(
        message: failure.message,
        errorCode: failure.code,
      )),
      (analysisResult) {
        if (analysisResult.isCompleted) {
          _stopPollingTimer();
          emit(PlantAnalysisCompleted(analysisResult));
        } else if (analysisResult.isFailed) {
          _stopPollingTimer();
          emit(const PlantAnalysisError(
            message: 'Analysis failed',
            errorCode: 'ANALYSIS_FAILED',
          ));
        } else {
          emit(PlantAnalysisProcessing(
            analysisId: analysisResult.id,
            estimatedCompletionTime: analysisResult.completedAt,
          ));
        }
      },
    );
  }

  Future<void> _onLoadAnalysesList(
    LoadAnalysesListEvent event,
    Emitter<PlantAnalysisState> emit,
  ) async {
    emit(PlantAnalysisListLoading());

    final result = await _repository.getAnalysesList(
      page: event.page,
      pageSize: event.pageSize,
    );

    result.fold(
      (failure) => emit(PlantAnalysisError(
        message: failure.message,
        errorCode: failure.code,
      )),
      (data) => emit(PlantAnalysisListLoaded(
        analyses: data.analyses,
        pagination: data.pagination ?? PaginationInfo(
          page: 1,
          totalPages: 1,
          totalItems: data.analyses.length,
          pageSize: data.analyses.length,
        ),
      )),
    );
  }

  void _onStartPolling(
    StartPollingEvent event,
    Emitter<PlantAnalysisState> emit,
  ) {
    _pollingAttempts = 0;
    _stopPollingTimer();

    // Initial check
    add(CheckAnalysisStatusEvent(event.analysisId));

    // Set up polling timer
    _pollingTimer = Timer.periodic(
      Duration(seconds: _getPollingInterval()),
      (timer) {
        _pollingAttempts++;

        if (_pollingAttempts >= _maxPollingAttempts) {
          _stopPollingTimer();
          emit(const PlantAnalysisError(
            message: 'Analysis timeout - please try again later',
            errorCode: 'TIMEOUT',
          ));
        } else {
          add(CheckAnalysisStatusEvent(event.analysisId));
        }
      },
    );
  }

  void _onStopPolling(
    StopPollingEvent event,
    Emitter<PlantAnalysisState> emit,
  ) {
    _stopPollingTimer();
  }

  int _getPollingInterval() {
    // Start with 2 seconds, increase to 5 seconds after 30 seconds
    if (_pollingAttempts < 15) {
      return 2;
    } else {
      return 5;
    }
  }

  void _stopPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _pollingAttempts = 0;
  }

  @override
  Future<void> close() {
    _stopPollingTimer();
    return super.close();
  }
}