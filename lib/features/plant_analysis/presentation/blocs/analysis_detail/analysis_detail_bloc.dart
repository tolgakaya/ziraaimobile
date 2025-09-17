import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/plant_analysis_result.dart';
import '../../../data/models/plant_disease.dart';
import '../../../data/models/plant_treatment.dart';
import 'analysis_detail_event.dart';
import 'analysis_detail_state.dart';

class AnalysisDetailBloc extends Bloc<AnalysisDetailEvent, AnalysisDetailState> {
  // final PlantAnalysisRepository repository; // Temporarily removed to avoid import conflicts

  AnalysisDetailBloc() : super(AnalysisDetailInitial()) {
    on<LoadAnalysisDetail>(_onLoadAnalysisDetail);
    on<RefreshAnalysisDetail>(_onRefreshAnalysisDetail);
  }

  Future<void> _onLoadAnalysisDetail(
    LoadAnalysisDetail event,
    Emitter<AnalysisDetailState> emit,
  ) async {
    emit(AnalysisDetailLoading());
    try {
      // TODO: Uncomment when API is ready
      // final result = await repository.getAnalysisResult(event.analysisId);
      
      // For now, use mock data for testing
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      final mockResult = PlantAnalysisResult(
        analysisId: event.analysisId,
        plantSpecies: 'Domates (Solanum lycopersicum)',
        status: 'Analiz Tamamlandı',
        confidence: 0.92,
        imageUrl: 'https://via.placeholder.com/400x300.png?text=Domates+Analizi',
        healthStatus: 'Orta Düzeyde Sağlıklı',
        growthStage: 'Çiçeklenme Dönemi',
        environmentalConditions: 'Nem: %65, Sıcaklık: 24°C, Işık: Yeterli',
        diseases: [
          PlantDisease(
            name: 'Erken Yanıklık (Alternaria solani)',
            severity: 'Orta',
            confidence: 0.85,
            description: 'Yapraklarda kahverengi lekeler ve halkasal desenler görülmektedir. Hastalık erken aşamada tespit edilmiştir.',
            symptoms: [
              'Yapraklarda kahverengi lekeler',
              'Halkasal desen oluşumu',
              'Yaprak kenarlarında sararma',
              'Alt yapraklardan başlayan kuruma'
            ],
            affectedParts: ['Yapraklar', 'Gövde', 'Meyve sapları'],
          ),
          PlantDisease(
            name: 'Besin Eksikliği - Azot',
            severity: 'Düşük',
            confidence: 0.72,
            description: 'Hafif azot eksikliği belirtileri görülmektedir. Alt yapraklarda sararma başlamıştır.',
            symptoms: [
              'Alt yapraklarda sararma',
              'Yavaş büyüme',
              'Soluk yeşil renk'
            ],
            affectedParts: ['Alt yapraklar'],
          ),
        ],
        treatments: [
          PlantTreatment(
            name: 'Fungisit Uygulaması',
            type: 'Kimyasal',
            description: 'Erken yanıklık hastalığına karşı koruyucu fungisit uygulaması',
            applicationMethod: 'Yaprakların alt ve üst yüzeylerine püskürtme yöntemiyle uygulayın. Sabah erken saatlerde veya akşam üzeri uygulama yapın.',
            products: ['Mancozeb', 'Chlorothalonil', 'Azoxystrobin'],
            frequency: 'Haftada bir kez',
            duration: '3-4 hafta',
            priority: 'Yüksek',
            precautions: [
              'Koruyucu ekipman kullanın',
              'Hasat öncesi bekleme süresine uyun',
              'Rüzgarlı havalarda uygulama yapmayın'
            ],
          ),
          PlantTreatment(
            name: 'Organik Çözüm - Neem Yağı',
            type: 'Organik',
            description: 'Doğal fungisit olarak neem yağı uygulaması',
            applicationMethod: '1 litre suya 5ml neem yağı ve 2ml sıvı sabun ekleyerek karıştırın. Yapraklara püskürtün.',
            products: ['Neem yağı', 'Organik sıvı sabun'],
            frequency: '5 günde bir',
            duration: '2-3 hafta',
            priority: 'Orta',
            precautions: [
              'Sıcak saatlerde uygulamayın',
              'Çiçeklenme döneminde dikkatli kullanın'
            ],
          ),
          PlantTreatment(
            name: 'Azotlu Gübre Takviyesi',
            type: 'Kültürel',
            description: 'Azot eksikliğini gidermek için gübre uygulaması',
            applicationMethod: 'Köke yakın bölgeye, bitkiden 10-15cm uzağa halka şeklinde uygulayın. Sulamayı ihmal etmeyin.',
            products: ['Üre (%46 N)', 'Amonyum sülfat', 'Kompoze gübre (20-20-20)'],
            frequency: '15 günde bir',
            duration: '1-2 ay',
            priority: 'Düşük',
            precautions: [
              'Aşırı dozdan kaçının',
              'Yapraklara temas ettirmeyin',
              'Sulamadan sonra uygulayın'
            ],
          ),
        ],
        recommendations: [
          'Hastalıklı yaprakları toplayıp imha edin',
          'Sulama sırasında yaprakları ıslatmamaya özen gösterin',
          'Bitki aralarında hava sirkülasyonunu artırın',
          'Düzenli gözlem yaparak hastalık ilerlemesini takip edin',
          'Toprak pH değerini kontrol edin (ideal: 6.0-6.8)',
          'Damlama sulama sistemine geçmeyi düşünün'
        ],
        createdDate: DateTime.now().subtract(const Duration(hours: 2)),
      );
      
      emit(AnalysisDetailLoaded(analysisResult: mockResult));
    } catch (e) {
      emit(AnalysisDetailError(message: 'Analiz yüklenirken hata oluştu: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshAnalysisDetail(
    RefreshAnalysisDetail event,
    Emitter<AnalysisDetailState> emit,
  ) async {
    // Use same mock data as LoadAnalysisDetail for consistency
    await _onLoadAnalysisDetail(
      LoadAnalysisDetail(analysisId: event.analysisId),
      emit,
    );
  }
}