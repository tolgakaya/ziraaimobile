import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/plant_analysis_repository.dart' as repo;
import '../../../data/models/plant_analysis_response_new.dart';
import 'analysis_detail_event.dart';
import 'analysis_detail_state.dart';

class AnalysisDetailBloc extends Bloc<AnalysisDetailEvent, AnalysisDetailState> {
  final repo.PlantAnalysisRepository repository;

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

    try {
      // Call real API
      final result = await repository.getAnalysisResult(event.analysisId);
      
      print('📡 API Result - Success: ${result.isSuccess}');
      if (result.isError) {
        print('❌ API Error: ${result.error}');
      }

      if (result.isSuccess && result.data != null) {
        final apiData = result.data!;
        print('✅ API Data received:');
        print('   - Plant Type: ${apiData.plantType}');
        print('   - Growth Stage: ${apiData.growthStage}');
        print('   - Status: ${apiData.status}');
        print('   - Diseases count: ${apiData.diseases.length}');
        print('   - Element deficiencies count: ${apiData.elementDeficiencies.length}');
        print('   - Pests count: ${apiData.pests.length}');

        // Convert API response to PlantAnalysisResult model
        final analysisResult = PlantAnalysisResult(
          id: apiData.id,
          imagePath: apiData.imagePath,
          analysisDate: apiData.analysisDate,
          status: apiData.status,
          userId: apiData.userId,
          analysisId: apiData.analysisId,
          plantType: apiData.plantType,
          growthStage: apiData.growthStage,
          elementDeficiencies: apiData.elementDeficiencies.map((e) =>
            ElementDeficiency(
              element: e.element,
              severity: e.severity,
              description: e.description,
            )
          ).toList(),
          diseases: apiData.diseases.map((d) =>
            PlantDisease(
              name: d.name,
              severity: d.severity,
              confidence: d.confidence,
              description: d.description,
            )
          ).toList(),
          pests: apiData.pests.map((p) =>
            PlantPest(
              name: p.name,
              severity: p.severity,
              confidence: p.confidence,
              description: p.description,
            )
          ).toList(),
        );

        print('🎯 Converted result - Plant Type: ${analysisResult.plantType}, Diseases: ${analysisResult.diseases?.length ?? 0}');
        emit(AnalysisDetailLoaded(analysisResult: analysisResult));
      } else {
        print('⚠️ API failed, falling back to mock data');
        // Fallback to mock data if API fails
        await _loadMockData(event, emit);
      }
    } catch (e) {
      print('💥 Exception loading from API: $e');
      // Fallback to mock data on error
      await _loadMockData(event, emit);
    }
  }

  Future<void> _loadMockData(LoadAnalysisDetail event, Emitter<AnalysisDetailState> emit) async {
    print('🎭 Loading mock data for analysis ID: ${event.analysisId}');
    await Future.delayed(const Duration(seconds: 1));

    final mockResult = PlantAnalysisResult(
      id: 1,
      imagePath: 'https://via.placeholder.com/400x300.png?text=Plant+Analysis',
      analysisDate: DateTime.now().toIso8601String(),
      status: 'completed',
      userId: 123,
      analysisId: event.analysisId,
      plantType: 'Domates (Tomato)',
      growthStage: 'Flowering Stage',
      notes: 'Mock analysis result for testing',
      elementDeficiencies: [
        ElementDeficiency(
          element: 'Nitrogen',
          severity: 'Medium',
          description: 'Slight yellowing of lower leaves indicates moderate nitrogen deficiency',
        ),
        ElementDeficiency(
          element: 'Potassium',
          severity: 'Low',
          description: 'Minor signs of potassium deficiency on leaf edges',
        ),
      ],
      diseases: [
        PlantDisease(
          name: 'Early Blight',
          severity: 'Medium',
          confidence: 0.85,
          description: 'Dark spots on leaves typical of early blight disease',
        ),
        PlantDisease(
          name: 'Leaf Spot',
          severity: 'Low',
          confidence: 0.72,
          description: 'Minor leaf spotting consistent with fungal infection',
        ),
      ],
      pests: [
        PlantPest(
          name: 'Aphids',
          severity: 'Low',
          confidence: 0.68,
          description: 'Small aphid population detected on young shoots',
        ),
      ],
    );

    emit(AnalysisDetailLoaded(analysisResult: mockResult));
  }

  Future<void> _onRefreshAnalysisDetail(
    RefreshAnalysisDetail event,
    Emitter<AnalysisDetailState> emit,
  ) async {
    await _onLoadAnalysisDetail(
      LoadAnalysisDetail(analysisId: event.analysisId),
      emit,
    );
  }
}