import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/plant_analysis_repository.dart';
import 'analysis_detail_event.dart';
import 'analysis_detail_state.dart';

class AnalysisDetailBloc extends Bloc<AnalysisDetailEvent, AnalysisDetailState> {
  final PlantAnalysisRepository repository;

  AnalysisDetailBloc({required this.repository}) : super(AnalysisDetailInitial()) {
    on<LoadAnalysisDetail>(_onLoadAnalysisDetail);
    on<RefreshAnalysisDetail>(_onRefreshAnalysisDetail);
  }

  Future<void> _onLoadAnalysisDetail(
    LoadAnalysisDetail event,
    Emitter<AnalysisDetailState> emit,
  ) async {
    emit(AnalysisDetailLoading());
    
    print('🔍 Loading analysis detail for ID: ${event.analysisId}');

    final result = await repository.getAnalysisDetail(event.analysisId);
    
    result.fold(
      (failure) {
        print('❌ Failed to load analysis detail: ${failure.message}');
        emit(AnalysisDetailError(message: failure.message));
      },
      (detail) {
        print('✅ Successfully loaded analysis detail');
        print('   - Crop Type: ${detail.cropType}');
        print('   - Status: ${detail.analysisStatus}');
        print('   - Analysis ID: ${detail.analysisId}');
        if (detail.plantIdentification != null) {
          print('   - Plant: ${detail.plantIdentification!.species}');
          print('   - Growth Stage: ${detail.plantIdentification!.growthStage}');
          print('   - Confidence: ${detail.plantIdentification!.confidence}%');
        }
        if (detail.healthAssessment != null) {
          print('   - Health Severity: ${detail.healthAssessment!.severity}');
          print('   - Vigor Score: ${detail.healthAssessment!.vigorScore}');
        }
        if (detail.diseases != null && detail.diseases!.isNotEmpty) {
          print('   - Diseases Detected: ${detail.diseases!.length}');
        }
        if (detail.treatments != null && detail.treatments!.isNotEmpty) {
          print('   - Treatments Available: ${detail.treatments!.length}');
        }

        emit(AnalysisDetailLoaded(analysisDetail: detail));
      },
    );
  }

  Future<void> _onRefreshAnalysisDetail(
    RefreshAnalysisDetail event,
    Emitter<AnalysisDetailState> emit,
  ) async {
    // Don't emit loading state on refresh to keep UI stable
    print('🔄 Refreshing analysis detail for ID: ${event.analysisId}');
    
    final result = await repository.getAnalysisDetail(event.analysisId);
    
    result.fold(
      (failure) {
        print('❌ Failed to refresh: ${failure.message}');
        emit(AnalysisDetailError(message: failure.message));
      },
      (detail) {
        print('✅ Successfully refreshed analysis detail');
        emit(AnalysisDetailLoaded(analysisDetail: detail));
      },
    );
  }
}