import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/comprehensive_analysis_response.dart';
import '../bloc/plant_analysis_bloc.dart';

class AnalysisDetailComprehensiveScreen extends StatefulWidget {
  final String analysisId;

  const AnalysisDetailComprehensiveScreen({
    Key? key,
    required this.analysisId,
  }) : super(key: key);

  @override
  State<AnalysisDetailComprehensiveScreen> createState() =>
      _AnalysisDetailComprehensiveScreenState();
}

class _AnalysisDetailComprehensiveScreenState
    extends State<AnalysisDetailComprehensiveScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PlantAnalysisBloc>().add(
          GetAnalysisDetailEvent(widget.analysisId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Bitki Analiz Detayları',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<PlantAnalysisBloc, PlantAnalysisState>(
        builder: (context, state) {
          if (state is PlantAnalysisLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            );
          }

          if (state is PlantAnalysisError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hata: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PlantAnalysisBloc>().add(
                            GetAnalysisDetailEvent(widget.analysisId),
                          );
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (state is PlantAnalysisDetailLoaded) {
            // Create comprehensive response from loaded data
            final comprehensiveData = _mapToComprehensiveResponse(state);
            return _buildAnalysisContent(comprehensiveData);
          }

          return const Center(
            child: Text('Veri yükleniyor...'),
          );
        },
      ),
    );
  }

  ComprehensiveAnalysisResponse _mapToComprehensiveResponse(
      PlantAnalysisDetailLoaded state) {
    // Map existing state data to comprehensive response
    // This is a temporary mapping until API is updated to return comprehensive data
    return ComprehensiveAnalysisResponse(
      farmerFriendlySummary: FarmerFriendlySummary(
        simpleExplanation: state.result.plantType != null
            ? '${state.result.plantType} bitkisinin genel durumu analiz edildi.'
            : 'Bitki analizi tamamlandı.',
        actionNeeded: state.result.diseases.isNotEmpty
            ? 'Hastalık tedavisi gerekiyor'
            : 'Rutin bakım önerilir',
        timeframe: 'Hemen',
        severity: state.result.diseases.isNotEmpty ? 'Orta' : 'Düşük',
        expectedOutcome: 'Bitkinin sağlığı iyileşecek',
      ),
      plantIdentification: PlantIdentificationComplete(
        plantSpecies: state.result.plantType,
        commonName: state.result.plantType,
        scientificName: 'Bilinmiyor',
        variety: 'Standart',
        identifyingFeatures: ['Yaprak dokusu', 'Renk', 'Boyut'],
        visibleParts: ['Yapraklar', 'Gövde'],
      ),
      healthAssessment: HealthAssessmentComplete(
        overallHealthScore: '${state.result.confidence.toInt()}',
        overallCondition: state.result.diseases.isEmpty ? 'İyi' : 'Dikkat Gerekiyor',
        primaryConcern: state.result.diseases.isNotEmpty
            ? state.result.diseases.first.name
            : 'Önemli sorun tespit edilmedi',
        secondaryConcerns: state.result.elementDeficiencies.isNotEmpty
            ? state.result.elementDeficiencies.map((e) => e.element).join(', ')
            : 'Yok',
        symptoms: state.result.diseases.map((d) => d.description ?? d.name).toList(),
        diseaseSymptoms: state.result.diseases.map((d) => d.name).toList(),
        growthStage: state.result.growthStage ?? 'Belirsiz',
        physicalCondition: 'Normal',
      ),
      nutrientStatus: NutrientStatusExtended(
        overallStatus: state.result.elementDeficiencies.isEmpty ? 'İyi' : 'Eksiklik Var',
        primaryDeficiency: state.result.elementDeficiencies.isNotEmpty
            ? state.result.elementDeficiencies.first.element
            : null,
        secondaryDeficiencies: state.result.elementDeficiencies.length > 1
            ? state.result.elementDeficiencies.skip(1).map((e) => e.element).toList()
            : [],
        severity: state.result.elementDeficiencies.isNotEmpty
            ? state.result.elementDeficiencies.first.severity
            : 'Normal',
        nitrogen: _getNutrientStatus(state.result.elementDeficiencies, 'nitrogen'),
        phosphorus: _getNutrientStatus(state.result.elementDeficiencies, 'phosphorus'),
        potassium: _getNutrientStatus(state.result.elementDeficiencies, 'potassium'),
        calcium: _getNutrientStatus(state.result.elementDeficiencies, 'calcium'),
        magnesium: _getNutrientStatus(state.result.elementDeficiencies, 'magnesium'),
        sulfur: _getNutrientStatus(state.result.elementDeficiencies, 'sulfur'),
        iron: _getNutrientStatus(state.result.elementDeficiencies, 'iron'),
        manganese: _getNutrientStatus(state.result.elementDeficiencies, 'manganese'),
        zinc: _getNutrientStatus(state.result.elementDeficiencies, 'zinc'),
        copper: _getNutrientStatus(state.result.elementDeficiencies, 'copper'),
        boron: _getNutrientStatus(state.result.elementDeficiencies, 'boron'),
        molybdenum: _getNutrientStatus(state.result.elementDeficiencies, 'molybdenum'),
        chlorine: _getNutrientStatus(state.result.elementDeficiencies, 'chlorine'),
        nickel: _getNutrientStatus(state.result.elementDeficiencies, 'nickel'),
        deficiencies: state.result.elementDeficiencies.map((e) => e.element).toList(),
        excesses: [],
      ),
      pestDisease: PestDiseaseComplete(
        overallStatus: state.result.diseases.isEmpty && state.result.pests.isEmpty
            ? 'Temiz'
            : 'Sorun Tespit Edildi',
        diseasesDetected: state.result.diseases
            .map((d) => DiseaseDetectedComplete(
                  type: d.name,
                  severity: d.severity,
                  confidence: d.confidence,
                  category: d.category,
                  description: d.description,
                  affectedParts: ['Yapraklar'],
                ))
            .toList(),
        pestsDetected: state.result.pests
            .map((p) => PestDetectedComplete(
                  type: p.name,
                  severity: p.severity,
                  confidence: p.confidence,
                  description: p.description,
                  affectedParts: ['Yapraklar'],
                ))
            .toList(),
        preventiveMeasures: 'Düzenli kontrol ve hijyen',
        damagePattern: 'Nokta şeklinde lezyonlar',
        affectedAreaPercentage: '10%',
        spreadRisk: 'Orta',
      ),
      environmentalStress: EnvironmentalStressComplete(
        lightConditions: 'Uygun',
        wateringStatus: 'Normal',
        soilCondition: 'İyi',
        temperature: 'Uygun',
        humidity: 'Normal',
        airCirculation: 'Yeterli',
        primaryStressor: 'Tespit edilmedi',
        stressFactors: [],
      ),
      summary: AnalysisSummaryComplete(
        primaryConcern: state.result.diseases.isNotEmpty
            ? state.result.diseases.first.name
            : 'Genel sağlık kontrolü',
        overallHealthScore: '${state.result.confidence.toInt()}',
        recommendedAction: 'Önerilen tedaviyi uygulayın',
        urgencyLevel: state.result.diseases.isNotEmpty ? 'Orta' : 'Düşük',
        prognosis: 'İyi',
        estimatedYieldImpact: '5-10% azalma riski',
      ),
      crossFactorInsights: CrossFactorInsights(
        confidence: state.result.confidence,
        affectedAspects: ['Verim', 'Kalite'],
        impactLevel: 'Orta',
        primaryInteraction: 'Beslenme-hastalık ilişkisi',
        secondaryEffects: 'Stres faktörleri',
      ),
      recommendations: RecommendationsComplete(
        immediate: state.result.treatments
            .map((t) => RecommendationItemComplete(
                  action: t.name,
                  details: t.instructions,
                  priority: 'Yüksek',
                  category: t.category,
                  timeline: t.frequency,
                  expectedOutcome: 'İyileşme beklenir',
                ))
            .toList(),
        shortTerm: [
          RecommendationItemComplete(
            action: 'Düzenli kontrol',
            details: 'Haftada bir kontrol edin',
            priority: 'Orta',
            category: 'izleme',
            timeline: 'Haftalık',
            expectedOutcome: 'Erken müdahale',
          ),
        ],
        preventive: [
          RecommendationItemComplete(
            action: 'Hijyen',
            details: 'Temiz araç gereç kullanın',
            priority: 'Orta',
            category: 'önleyici',
            timeline: 'Sürekli',
            expectedOutcome: 'Hastalık önleme',
          ),
        ],
        monitoring: [
          RecommendationItemComplete(
            action: 'Takip',
            details: 'İyileşme sürecini takip edin',
            priority: 'Düşük',
            category: 'izleme',
            timeline: 'Aylık',
            expectedOutcome: 'Sürekli sağlık',
          ),
        ],
        resourceEstimation: ResourceEstimation(
          timeDuration: '2-3 hafta',
          costEstimate: '50-100 TL',
          requiredMaterials: ['İlaç', 'Gübre'],
          laborRequirement: '2-3 saat',
        ),
      ),
      confidenceNotes: [
        ConfidenceNote(
          aspect: 'Hastalık tespiti',
          confidence: state.result.confidence,
          reason: 'Görsel analiz ile tespit edildi',
        ),
      ],
    );
  }

  String _getNutrientStatus(List<dynamic> deficiencies, String nutrient) {
    final deficiency = deficiencies.firstWhere(
      (d) => d.element?.toLowerCase().contains(nutrient.toLowerCase()) == true,
      orElse: () => null,
    );
    return deficiency != null ? 'Eksik' : 'Normal';
  }

  Widget _buildAnalysisContent(ComprehensiveAnalysisResponse data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Farmer Friendly Summary (At Top - Priority)
          if (data.farmerFriendlySummary != null)
            _buildFarmerFriendlySummary(data.farmerFriendlySummary!),
          
          const SizedBox(height: 16),
          
          // 2. Plant Identification
          if (data.plantIdentification != null)
            _buildPlantIdentification(data.plantIdentification!),
          
          const SizedBox(height: 16),
          
          // 3. Health Assessment
          if (data.healthAssessment != null)
            _buildHealthAssessment(data.healthAssessment!),
          
          const SizedBox(height: 16),
          
          // 4. Nutrient Status (All 14 nutrients + primaryDeficiency, secondaryDeficiencies)
          if (data.nutrientStatus != null)
            _buildNutrientStatus(data.nutrientStatus!),
          
          const SizedBox(height: 16),
          
          // 5. Pest & Disease (Complete with damagePattern, affectedAreaPercentage, spreadRisk)
          if (data.pestDisease != null)
            _buildPestDisease(data.pestDisease!),
          
          const SizedBox(height: 16),
          
          // 6. Environmental Stress (All 6 factors + primaryStressor)
          if (data.environmentalStress != null)
            _buildEnvironmentalStress(data.environmentalStress!),
          
          const SizedBox(height: 16),
          
          // 7. Summary (Complete with prognosis, estimatedYieldImpact)
          if (data.summary != null)
            _buildSummary(data.summary!),
          
          const SizedBox(height: 16),
          
          // 8. Cross Factor Insights (confidence, affectedAspects, impactLevel)
          if (data.crossFactorInsights != null)
            _buildCrossFactorInsights(data.crossFactorInsights!),
          
          const SizedBox(height: 16),
          
          // 9. Recommendations (immediate, shortTerm, preventive, monitoring, resourceEstimation)
          if (data.recommendations != null)
            _buildRecommendations(data.recommendations!),
          
          const SizedBox(height: 16),
          
          // 10. Confidence Notes (aspect, confidence, reason)
          if (data.confidenceNotes != null && data.confidenceNotes!.isNotEmpty)
            _buildConfidenceNotes(data.confidenceNotes!),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFarmerFriendlySummary(FarmerFriendlySummary summary) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.agriculture, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Çiftçi Dostu Özet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (summary.simpleExplanation != null)
              _buildSummaryItem('📝 Açıklama', summary.simpleExplanation!),
            if (summary.actionNeeded != null)
              _buildSummaryItem('⚡ Yapılması Gereken', summary.actionNeeded!),
            if (summary.timeframe != null)
              _buildSummaryItem('⏰ Zaman Çerçevesi', summary.timeframe!),
            if (summary.severity != null)
              _buildSummaryItem('🎯 Önem Derecesi', summary.severity!),
            if (summary.expectedOutcome != null)
              _buildSummaryItem('🌱 Beklenen Sonuç', summary.expectedOutcome!),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantIdentification(PlantIdentificationComplete identification) {
    return _buildSectionCard(
      '🌿 Bitki Tanımlama',
      [
        if (identification.plantSpecies != null)
          _buildDetailRow('Bitki Türü', identification.plantSpecies!),
        if (identification.commonName != null)
          _buildDetailRow('Yaygın İsmi', identification.commonName!),
        if (identification.scientificName != null)
          _buildDetailRow('Bilimsel İsmi', identification.scientificName!),
        if (identification.variety != null)
          _buildDetailRow('Çeşidi', identification.variety!),
        if (identification.identifyingFeatures != null && identification.identifyingFeatures!.isNotEmpty)
          _buildListRow('Tanımlayıcı Özellikler', identification.identifyingFeatures!),
        if (identification.visibleParts != null && identification.visibleParts!.isNotEmpty)
          _buildListRow('Görünen Kısımlar', identification.visibleParts!),
      ],
    );
  }

  Widget _buildHealthAssessment(HealthAssessmentComplete health) {
    return _buildSectionCard(
      '💚 Sağlık Değerlendirmesi',
      [
        if (health.overallHealthScore != null)
          _buildScoreRow('Genel Sağlık Skoru', health.overallHealthScore!),
        if (health.overallCondition != null)
          _buildDetailRow('Genel Durum', health.overallCondition!),
        if (health.primaryConcern != null)
          _buildDetailRow('Ana Endişe', health.primaryConcern!),
        if (health.secondaryConcerns != null)
          _buildDetailRow('İkincil Endişeler', health.secondaryConcerns!),
        if (health.symptoms != null && health.symptoms!.isNotEmpty)
          _buildListRow('Belirtiler', health.symptoms!),
        if (health.diseaseSymptoms != null && health.diseaseSymptoms!.isNotEmpty)
          _buildListRow('Hastalık Belirtileri', health.diseaseSymptoms!),
        if (health.growthStage != null)
          _buildDetailRow('Büyüme Evresi', health.growthStage!),
        if (health.physicalCondition != null)
          _buildDetailRow('Fiziksel Durum', health.physicalCondition!),
      ],
    );
  }

  Widget _buildNutrientStatus(NutrientStatusExtended nutrients) {
    return _buildSectionCard(
      '🧪 Besin Durumu',
      [
        if (nutrients.overallStatus != null)
          _buildDetailRow('Genel Durum', nutrients.overallStatus!),
        if (nutrients.primaryDeficiency != null)
          _buildDetailRow('Ana Eksiklik', nutrients.primaryDeficiency!),
        if (nutrients.secondaryDeficiencies != null && nutrients.secondaryDeficiencies!.isNotEmpty)
          _buildListRow('İkincil Eksiklikler', nutrients.secondaryDeficiencies!),
        if (nutrients.severity != null)
          _buildDetailRow('Şiddet', nutrients.severity!),
        
        const SizedBox(height: 12),
        const Text(
          'Besin Elementleri Durumu:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        
        // All 14 nutrients in grid
        _buildNutrientGrid(nutrients),
      ],
    );
  }

  Widget _buildNutrientGrid(NutrientStatusExtended nutrients) {
    final nutrientData = [
      {'name': 'Azot (N)', 'value': nutrients.nitrogen ?? 'Normal'},
      {'name': 'Fosfor (P)', 'value': nutrients.phosphorus ?? 'Normal'},
      {'name': 'Potasyum (K)', 'value': nutrients.potassium ?? 'Normal'},
      {'name': 'Kalsiyum (Ca)', 'value': nutrients.calcium ?? 'Normal'},
      {'name': 'Magnezyum (Mg)', 'value': nutrients.magnesium ?? 'Normal'},
      {'name': 'Kükürt (S)', 'value': nutrients.sulfur ?? 'Normal'},
      {'name': 'Demir (Fe)', 'value': nutrients.iron ?? 'Normal'},
      {'name': 'Mangan (Mn)', 'value': nutrients.manganese ?? 'Normal'},
      {'name': 'Çinko (Zn)', 'value': nutrients.zinc ?? 'Normal'},
      {'name': 'Bakır (Cu)', 'value': nutrients.copper ?? 'Normal'},
      {'name': 'Bor (B)', 'value': nutrients.boron ?? 'Normal'},
      {'name': 'Molibden (Mo)', 'value': nutrients.molybdenum ?? 'Normal'},
      {'name': 'Klor (Cl)', 'value': nutrients.chlorine ?? 'Normal'},
      {'name': 'Nikel (Ni)', 'value': nutrients.nickel ?? 'Normal'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: nutrientData.length,
      itemBuilder: (context, index) {
        final nutrient = nutrientData[index];
        final isDeficient = nutrient['value'] == 'Eksik';
        
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDeficient ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDeficient ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nutrient['name']!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                nutrient['value']!,
                style: TextStyle(
                  fontSize: 11,
                  color: isDeficient ? Colors.red.shade700 : Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPestDisease(PestDiseaseComplete pestDisease) {
    return _buildSectionCard(
      '🐛 Zararlı ve Hastalık',
      [
        if (pestDisease.overallStatus != null)
          _buildDetailRow('Genel Durum', pestDisease.overallStatus!),
        if (pestDisease.damagePattern != null)
          _buildDetailRow('Hasar Paterni', pestDisease.damagePattern!),
        if (pestDisease.affectedAreaPercentage != null)
          _buildDetailRow('Etkilenen Alan %', pestDisease.affectedAreaPercentage!),
        if (pestDisease.spreadRisk != null)
          _buildDetailRow('Yayılma Riski', pestDisease.spreadRisk!),
        if (pestDisease.preventiveMeasures != null)
          _buildDetailRow('Önleyici Tedbirler', pestDisease.preventiveMeasures!),
        
        if (pestDisease.diseasesDetected != null && pestDisease.diseasesDetected!.isNotEmpty)
          ..._buildDiseaseList(pestDisease.diseasesDetected!),
        
        if (pestDisease.pestsDetected != null && pestDisease.pestsDetected!.isNotEmpty)
          ..._buildPestList(pestDisease.pestsDetected!),
      ],
    );
  }

  List<Widget> _buildDiseaseList(List<DiseaseDetectedComplete> diseases) {
    return [
      const SizedBox(height: 12),
      const Text(
        'Tespit Edilen Hastalıklar:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      const SizedBox(height: 8),
      ...diseases.map((disease) => _buildDiseaseCard(disease)),
    ];
  }

  List<Widget> _buildPestList(List<PestDetectedComplete> pests) {
    return [
      const SizedBox(height: 12),
      const Text(
        'Tespit Edilen Zararlılar:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      const SizedBox(height: 8),
      ...pests.map((pest) => _buildPestCard(pest)),
    ];
  }

  Widget _buildDiseaseCard(DiseaseDetectedComplete disease) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  disease.type ?? 'Bilinmeyen Hastalık',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (disease.confidence != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${disease.confidence!.toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (disease.severity != null)
            Text('Şiddet: ${disease.severity}',
                style: const TextStyle(fontSize: 12)),
          if (disease.description != null)
            Text(disease.description!,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPestCard(PestDetectedComplete pest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pest.type ?? 'Bilinmeyen Zararlı',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (pest.confidence != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pest.confidence!.toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (pest.severity != null)
            Text('Şiddet: ${pest.severity}',
                style: const TextStyle(fontSize: 12)),
          if (pest.description != null)
            Text(pest.description!,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalStress(EnvironmentalStressComplete environmental) {
    return _buildSectionCard(
      '🌤️ Çevresel Stres Faktörleri',
      [
        if (environmental.primaryStressor != null)
          _buildDetailRow('Ana Stres Faktörü', environmental.primaryStressor!),
        if (environmental.lightConditions != null)
          _buildDetailRow('Işık Koşulları', environmental.lightConditions!),
        if (environmental.wateringStatus != null)
          _buildDetailRow('Sulama Durumu', environmental.wateringStatus!),
        if (environmental.soilCondition != null)
          _buildDetailRow('Toprak Durumu', environmental.soilCondition!),
        if (environmental.temperature != null)
          _buildDetailRow('Sıcaklık', environmental.temperature!),
        if (environmental.humidity != null)
          _buildDetailRow('Nem', environmental.humidity!),
        if (environmental.airCirculation != null)
          _buildDetailRow('Hava Dolaşımı', environmental.airCirculation!),
        if (environmental.stressFactors != null && environmental.stressFactors!.isNotEmpty)
          _buildListRow('Diğer Stres Faktörleri', environmental.stressFactors!),
      ],
    );
  }

  Widget _buildSummary(AnalysisSummaryComplete summary) {
    return _buildSectionCard(
      '📊 Detaylı Özet',
      [
        if (summary.primaryConcern != null)
          _buildDetailRow('Ana Endişe', summary.primaryConcern!),
        if (summary.overallHealthScore != null)
          _buildScoreRow('Genel Sağlık Skoru', summary.overallHealthScore!),
        if (summary.recommendedAction != null)
          _buildDetailRow('Önerilen Eylem', summary.recommendedAction!),
        if (summary.urgencyLevel != null)
          _buildDetailRow('Aciliyet Seviyesi', summary.urgencyLevel!),
        if (summary.prognosis != null)
          _buildDetailRow('Prognoz', summary.prognosis!),
        if (summary.estimatedYieldImpact != null)
          _buildDetailRow('Tahmini Verim Etkisi', summary.estimatedYieldImpact!),
      ],
    );
  }

  Widget _buildCrossFactorInsights(CrossFactorInsights insights) {
    return _buildSectionCard(
      '🔗 Çapraz Faktör Analizi',
      [
        if (insights.confidence != null)
          _buildScoreRow('Güven Skoru', '${insights.confidence!.toInt()}'),
        if (insights.impactLevel != null)
          _buildDetailRow('Etki Seviyesi', insights.impactLevel!),
        if (insights.primaryInteraction != null)
          _buildDetailRow('Ana Etkileşim', insights.primaryInteraction!),
        if (insights.secondaryEffects != null)
          _buildDetailRow('İkincil Etkiler', insights.secondaryEffects!),
        if (insights.affectedAspects != null && insights.affectedAspects!.isNotEmpty)
          _buildListRow('Etkilenen Yönler', insights.affectedAspects!),
      ],
    );
  }

  Widget _buildRecommendations(RecommendationsComplete recommendations) {
    return _buildSectionCard(
      '💡 Öneriler',
      [
        if (recommendations.immediate != null && recommendations.immediate!.isNotEmpty)
          ..._buildRecommendationSection('🚨 Acil Eylemler', recommendations.immediate!),
        
        if (recommendations.shortTerm != null && recommendations.shortTerm!.isNotEmpty)
          ..._buildRecommendationSection('⏱️ Kısa Vadeli', recommendations.shortTerm!),
        
        if (recommendations.preventive != null && recommendations.preventive!.isNotEmpty)
          ..._buildRecommendationSection('🛡️ Önleyici', recommendations.preventive!),
        
        if (recommendations.monitoring != null && recommendations.monitoring!.isNotEmpty)
          ..._buildRecommendationSection('👀 İzleme', recommendations.monitoring!),
        
        if (recommendations.resourceEstimation != null)
          ..._buildResourceEstimation(recommendations.resourceEstimation!),
      ],
    );
  }

  List<Widget> _buildRecommendationSection(String title, List<RecommendationItemComplete> items) {
    return [
      const SizedBox(height: 12),
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      const SizedBox(height: 8),
      ...items.map((item) => _buildRecommendationCard(item)),
    ];
  }

  Widget _buildRecommendationCard(RecommendationItemComplete item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.action != null)
            Text(
              item.action!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (item.details != null)
            Text(item.details!, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (item.priority != null)
                _buildTag('Öncelik: ${item.priority}', Colors.red),
              const SizedBox(width: 8),
              if (item.timeline != null)
                _buildTag('Zaman: ${item.timeline}', Colors.orange),
            ],
          ),
          if (item.expectedOutcome != null)
            Text(
              'Beklenen Sonuç: ${item.expectedOutcome}',
              style: const TextStyle(fontSize: 11, color: Colors.green),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildResourceEstimation(ResourceEstimation estimation) {
    return [
      const SizedBox(height: 12),
      const Text(
        '💰 Kaynak Tahmini',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (estimation.timeDuration != null)
              _buildDetailRow('Süre', estimation.timeDuration!),
            if (estimation.costEstimate != null)
              _buildDetailRow('Tahmini Maliyet', estimation.costEstimate!),
            if (estimation.laborRequirement != null)
              _buildDetailRow('İşçilik', estimation.laborRequirement!),
            if (estimation.requiredMaterials != null && estimation.requiredMaterials!.isNotEmpty)
              _buildListRow('Gerekli Malzemeler', estimation.requiredMaterials!),
          ],
        ),
      ),
    ];
  }

  Widget _buildConfidenceNotes(List<ConfidenceNote> notes) {
    return _buildSectionCard(
      '📈 Güvenilirlik Notları',
      notes.map((note) => _buildConfidenceNoteCard(note)).toList(),
    );
  }

  Widget _buildConfidenceNoteCard(ConfidenceNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.aspect ?? 'Genel',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (note.confidence != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${note.confidence!.toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (note.reason != null)
            Text(
              note.reason!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, String score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  score,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 100,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: (double.tryParse(score) ?? 0) / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items.map((item) => _buildTag(item, Colors.blue)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color.shade700,
        ),
      ),
    );
  }
}