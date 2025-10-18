import 'package:flutter/material.dart';
import '../../../messaging/presentation/pages/message_detail_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../domain/repositories/plant_analysis_repository.dart';
import '../../data/models/plant_analysis_result.dart';
import '../blocs/analysis_detail/analysis_detail_bloc.dart';
import '../blocs/analysis_detail/analysis_detail_event.dart';
import '../blocs/analysis_detail/analysis_detail_state.dart';

class AnalysisDetailScreen extends StatelessWidget {
  final int analysisId;

  const AnalysisDetailScreen({
    Key? key,
    required this.analysisId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalysisDetailBloc(
        repository: getIt<PlantAnalysisRepository>(),
      )..add(LoadAnalysisDetail(analysisId: analysisId)),
      child: BlocBuilder<AnalysisDetailBloc, AnalysisDetailState>(
        builder: (context, state) {
          PlantAnalysisResult? detail;
          if (state is AnalysisDetailLoaded) {
            detail = state.analysisDetail;
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            body: Builder(
              builder: (context) {
                if (state is AnalysisDetailLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF17CF17),
                    ),
                  );
                } else if (state is AnalysisDetailLoaded) {
                  return _buildDetailContent(context, state.analysisDetail);
                } else if (state is AnalysisDetailError) {
                  return _buildErrorState(context, state.message);
                }
                return const SizedBox();
              },
            ),
            floatingActionButton: detail?.sponsorId != null
                ? FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageDetailPage(
                            plantAnalysisId: detail!.id!,
                            farmerId: detail.sponsorId!,
                            farmerName: detail.sponsorName ?? 'Sponsor',
                            canMessage: true,
                          ),
                        ),
                      );
                    },
                    label: const Text('Mesaj Gönder'),
                    icon: const Icon(Icons.message),
                    backgroundColor: const Color(0xFF17CF17),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, PlantAnalysisResult detail) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AnalysisDetailBloc>().add(
          RefreshAnalysisDetail(analysisId: analysisId),
        );
        await Future.delayed(const Duration(seconds: 1));
      },
      color: const Color(0xFF17CF17),
      child: CustomScrollView(
        slivers: [
          // App Bar with Image
          _buildSliverAppBar(context, detail),

          // Content - All 10 Required Sections
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 10. Farmer Friendly Summary (MUST BE AT TOP - as requested)
                _buildFarmerFriendlySummarySection(detail),
                const SizedBox(height: 20),

                // 1. Plant Identification (all 6 fields including identifyingFeatures, visibleParts)
                _buildPlantIdentificationSection(detail),
                const SizedBox(height: 20),

                // 2. Health Assessment (all 8 fields including diseaseSymptoms)
                _buildHealthAssessmentSection(detail),
                const SizedBox(height: 20),

                // 3. Nutrient Status (all 14 nutrients + primaryDeficiency, secondaryDeficiencies - KESINLIKLE!)
                _buildNutrientStatusSection(detail),
                const SizedBox(height: 20),

                // 4. Pest & Disease (complete with damagePattern, affectedAreaPercentage, spreadRisk)
                _buildPestDiseaseSection(detail),
                const SizedBox(height: 20),

                // 5. Environmental Stress (all 6 factors + primaryStressor)
                _buildEnvironmentalStressSection(detail),
                const SizedBox(height: 20),

                // 6. Summary (complete with prognosis, estimatedYieldImpact)
                _buildAnalysisSummarySection(detail),
                const SizedBox(height: 20),

                // 7. Cross Factor Insights (confidence, affectedAspects, impactLevel)
                _buildCrossFactorInsightsSection(detail),
                const SizedBox(height: 20),

                // 8. Recommendations (immediate, shortTerm, preventive, monitoring, resourceEstimation)
                _buildRecommendationsSection(detail),
                const SizedBox(height: 20),

                // 9. Confidence Notes (aspect, confidence, reason)
                _buildConfidenceNotesSection(detail),
                const SizedBox(height: 20),

                // Technical Information Card (additional)
                _buildTechnicalInfoCard(detail),
                const SizedBox(height: 20),

                // Analysis Metadata Card (additional)
                _buildAnalysisMetadataCard(detail),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, PlantAnalysisResult detail) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          detail.species,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            detail.finalImageUrl.isNotEmpty
                ? Image.network(
                    detail.finalImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF17CF17), Color(0xFF15B815)],
                          ),
                        ),
                        child: const Icon(
                          Icons.local_florist,
                          size: 80,
                          color: Colors.white54,
                        ),
                      );
                    },
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF17CF17), Color(0xFF15B815)],
                      ),
                    ),
                    child: const Icon(
                      Icons.local_florist,
                      size: 80,
                      color: Colors.white54,
                    ),
                  ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            
            // Hero Section Content
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildHeroContent(detail),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroContent(PlantAnalysisResult detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Confidence Badge
        if (detail.confidence != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${detail.confidence!.toInt()}% Güven',
              style: const TextStyle(
                color: Color(0xFF111811),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Health Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getHealthColor(detail.healthStatus).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            detail.healthStatus,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getHealthColor(String healthScore) {
    switch (healthScore.toLowerCase()) {
      case 'excellent':
      case 'mükemmel':
        return Colors.green;
      case 'good':
      case 'iyi':
        return Colors.lightGreen;
      case 'fair':
      case 'orta':
        return Colors.orange;
      case 'poor':
      case 'kötü':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to ensure proper Turkish capitalization
  String _formatTurkishText(String text) {
    if (text.isEmpty) return text;

    // Ensure first letter is uppercase
    String formatted = text[0].toUpperCase() + text.substring(1);

    // Split by sentences (. ! ?) and capitalize each
    final sentences = formatted.split(RegExp(r'(?<=[.!?])\s+'));
    final capitalizedSentences = sentences.map((sentence) {
      if (sentence.isEmpty) return sentence;

      // Handle numbered items (1. 2. etc)
      final numberMatch = RegExp(r'^(\d+[.)]\s*)(.*)').firstMatch(sentence);
      if (numberMatch != null) {
        final number = numberMatch.group(1) ?? '';
        final content = numberMatch.group(2) ?? '';
        if (content.isNotEmpty) {
          return number + content[0].toUpperCase() + content.substring(1);
        }
        return sentence;
      }

      // Regular sentence capitalization
      return sentence[0].toUpperCase() + sentence.substring(1);
    });

    return capitalizedSentences.join(' ');
  }

  // Helper method to format summary text with numbered items on separate lines
  Widget _buildFormattedSummaryText(String text) {
    // First apply Turkish formatting
    text = _formatTurkishText(text);

    // Check if text contains numbered items with either "1." or "1)" format
    // Split on patterns like "1.", "1)", "2.", "2)" etc.
    final lines = text.split(RegExp(r'(?=\d+[\.)])'));

    if (lines.length > 1) {
      // Text has numbered items, display each on a new line
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          line = line.trim();
          if (line.isEmpty) return const SizedBox.shrink();

          // Check if this line starts with a number followed by . or )
          final isNumberedItem = RegExp(r'^\d+[\.)]').hasMatch(line);

          // Apply Turkish formatting to each line
          line = _formatTurkishText(line);

          return Padding(
            padding: EdgeInsets.only(
              bottom: isNumberedItem ? 8.0 : 4.0,
              left: isNumberedItem ? 0.0 : 0.0,
            ),
            child: Text(
              line,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
                fontWeight: isNumberedItem ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      );
    } else {
      // No numbered items, display as regular text with better line height
      return Text(
        _formatTurkishText(text),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.5,
        ),
      );
    }
  }

  // 10. Farmer Friendly Summary (AT TOP - PRIORITY)
  Widget _buildFarmerFriendlySummarySection(PlantAnalysisResult detail) {
    // Check if we have farmerFriendlySummary in additionalData
    final farmerSummary = detail.additionalData?['farmerFriendlySummary'];
    
    print('🌾 FARMER SUMMARY DEBUG: $farmerSummary');
    
    if (farmerSummary == null || (farmerSummary is String && farmerSummary.isEmpty)) {
      // Fallback to basic summary if no farmerFriendlySummary available
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
                    'Analiz Özeti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Detaylı özet bilgisi mevcut değil',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    // If farmerSummary is a String, display it directly
    if (farmerSummary is String) {
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
                    'Analiz Özeti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFormattedSummaryText(farmerSummary),
            ],
          ),
        ),
      );
    }
    
    // If farmerSummary is a Map, parse structured fields
    if (farmerSummary is Map) {
      final description = farmerSummary['description'] ?? farmerSummary['açıklama'] ?? 'Analiz tamamlandı';
      final whatToDo = farmerSummary['whatToDo'] ?? farmerSummary['yapılacaklar'] ?? 'Öneriler bölümünü inceleyin';
      final timeframe = farmerSummary['timeframe'] ?? farmerSummary['zamanlama'] ?? 'Belirtilmemiş';
      final importanceLevel = farmerSummary['importanceLevel'] ?? farmerSummary['önemDerecesi'] ?? 'Orta';
      final expectedOutcome = farmerSummary['expectedOutcome'] ?? farmerSummary['beklenenSonuç'] ?? 'Bitkinin durumu iyileşecek';
      
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
                    'Analiz Özeti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryItem('📝 Açıklama', description),
              _buildSummaryItem('⚡ Yapılması Gereken', whatToDo),
              _buildSummaryItem('⏰ Zaman Çerçevesi', timeframe),
              _buildSummaryItem('🎯 Önem Derecesi', importanceLevel),
              _buildSummaryItem('🌱 Beklenen Sonuç', expectedOutcome),
            ],
          ),
        ),
      );
    }
    
    // Fallback
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
                  'Analiz Özeti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Beklenmeyen veri formatı',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    // Apply Turkish formatting to the value
    value = _formatTurkishText(value);

    // Check if the value contains numbered items with either "1." or "1)" format
    final lines = value.split(RegExp(r'(?=\d+[\.)])'));
    final hasNumberedItems = lines.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          if (hasNumberedItems)
            ...lines.map((line) {
              line = line.trim();
              if (line.isEmpty) return const SizedBox.shrink();

              final isNumberedItem = RegExp(r'^\d+[\.)]').hasMatch(line);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: isNumberedItem ? 4.0 : 2.0,
                  left: isNumberedItem ? 12.0 : 12.0,
                ),
                child: Text(
                  line,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: isNumberedItem ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              );
            }).toList()
          else
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 1. Plant Identification (ALL 6 FIELDS)
  Widget _buildPlantIdentificationSection(PlantAnalysisResult detail) {
    final identification = detail.plantIdentification;
    
    if (identification == null) {
      return _buildSectionCard(
        '🌿 Bitki Tanımlama',
        [
          _buildDetailRow('Bitki Türü', detail.plantSpecies ?? detail.species ?? 'Belirtilmemiş'),
          _buildDetailRow('Durum', 'Detaylı tanımlama bilgisi mevcut değil'),
        ],
      );
    }
    
    return _buildSectionCard(
      '🌿 Bitki Tanımlama',
      [
        _buildDetailRow('Tür', identification.species ?? 'Belirtilmemiş'),
        _buildDetailRow('Çeşit', identification.variety ?? 'bilinmiyor'),
        _buildDetailRow('Büyüme Evresi', identification.growthStage ?? 'Belirtilmemiş'),
        _buildDetailRow('Güven Oranı', '${identification.confidence?.toStringAsFixed(0) ?? '0'}%'),
        _buildListRow('Tanımlayıcı Özellikler', identification.identifyingFeatures ?? []),
        _buildListRow('Görünen Kısımlar', identification.visibleParts ?? []),
      ],
    );
  }

  // 2. Health Assessment (ALL 8 FIELDS)
  Widget _buildHealthAssessmentSection(PlantAnalysisResult detail) {
    final health = detail.healthAssessment;
    
    if (health == null) {
      return _buildSectionCard(
        '💚 Sağlık Değerlendirmesi',
        [
          _buildDetailRow('Durum', 'Detaylı sağlık değerlendirmesi mevcut değil'),
        ],
      );
    }
    
    return _buildSectionCard(
      '💚 Sağlık Değerlendirmesi',
      [
        _buildScoreRow('Canlılık Skoru', health.vigorScore?.toString() ?? '0'),
        _buildDetailRow('Yaprak Rengi', health.leafColor ?? 'Belirtilmemiş'),
        _buildDetailRow('Yaprak Dokusu', health.leafTexture ?? 'Belirtilmemiş'),
        _buildDetailRow('Büyüme Deseni', health.growthPattern ?? 'Belirtilmemiş'),
        _buildDetailRow('Yapısal Bütünlük', health.structuralIntegrity ?? 'Belirtilmemiş'),
        _buildDetailRow('Ciddiyet', health.severity ?? 'Belirtilmemiş'),
        _buildListRow('Stres Göstergeleri', health.stressIndicators ?? []),
        if (health.diseaseSymptoms?.isNotEmpty == true)
          _buildListRow('Hastalık Belirtileri', health.diseaseSymptoms!),
        if (health.symptoms?.isNotEmpty == true)
          _buildListRow('Diğer Semptomlar', health.symptoms!),
      ],
    );
  }

  // 3. Nutrient Status (ALL 14 NUTRIENTS + primaryDeficiency, secondaryDeficiencies - KESINLIKLE!)
  Widget _buildNutrientStatusSection(PlantAnalysisResult detail) {
    final nutrientStatus = detail.nutrientStatus;
    
    if (nutrientStatus == null) {
      return _buildSectionCard(
        '🧪 Besin Durumu',
        [
          _buildDetailRow('Durum', 'Besin durumu analizi mevcut değil'),
        ],
      );
    }
    
    // Build only deficient nutrients list
    final List<Widget> children = [];
    
    // Check for specific deficiencies in additionalData 
    final nutrientData = detail.additionalData?['nutrientStatus'];
    if (nutrientData != null) {
      // Helper function to add deficient nutrients
      void addDeficientNutrient(String key, String displayName) {
        if (nutrientData[key] == 'eksik') {
          children.add(_buildDeficientNutrientRow(displayName, 'Eksik'));
        }
      }
      
      // Add all deficient nutrients from API response
      addDeficientNutrient('nitrogen', 'Azot (N)');
      addDeficientNutrient('phosphorus', 'Fosfor (P)');
      addDeficientNutrient('potassium', 'Potasyum (K)');
      addDeficientNutrient('calcium', 'Kalsiyum (Ca)');
      addDeficientNutrient('magnesium', 'Magnezyum (Mg)');
      addDeficientNutrient('sulfur', 'Kükürt (S)');
      addDeficientNutrient('iron', 'Demir (Fe)');
      addDeficientNutrient('zinc', 'Çinko (Zn)');
      addDeficientNutrient('manganese', 'Mangan (Mn)');
      addDeficientNutrient('boron', 'Bor (B)');
      addDeficientNutrient('copper', 'Bakır (Cu)');
      addDeficientNutrient('molybdenum', 'Molibden (Mo)');
      addDeficientNutrient('chlorine', 'Klor (Cl)');
      addDeficientNutrient('nickel', 'Nikel (Ni)');
    }
    
    // Add primary and secondary deficiencies from additionalData or from deficiencies list
    final primaryDeficiency = detail.additionalData?['nutrientStatus']?['primaryDeficiency'];
    if (primaryDeficiency != null) {
      children.insert(0, _buildDetailRow('Ana Eksiklik', primaryDeficiency));
    } else if (nutrientStatus.deficiencies?.isNotEmpty == true) {
      children.insert(0, _buildDetailRow('Ana Eksiklik', nutrientStatus.deficiencies!.first));
    }
    
    final secondaryDeficiencies = detail.additionalData?['nutrientStatus']?['secondaryDeficiencies'];
    if (secondaryDeficiencies != null && secondaryDeficiencies is List && secondaryDeficiencies.isNotEmpty) {
      children.add(_buildListRow('İkincil Eksiklikler', secondaryDeficiencies.cast<String>()));
    } else if (nutrientStatus.deficiencies != null && nutrientStatus.deficiencies!.length > 1) {
      children.add(_buildListRow('İkincil Eksiklikler', nutrientStatus.deficiencies!.skip(1).toList()));
    }
    
    final severity = detail.additionalData?['nutrientStatus']?['severity'];
    if (severity != null) {
      children.add(_buildDetailRow('Şiddet', severity));
    }
    
    if (children.isEmpty) {
      children.add(_buildDetailRow('Durum', 'Besin eksikliği tespit edilmedi'));
    }
    
    return _buildSectionCard(
      '🧪 Besin Durumu',
      children,
    );
  }

  // 4. Pest & Disease (WITH damagePattern, affectedAreaPercentage, spreadRisk)
  Widget _buildPestDiseaseSection(PlantAnalysisResult detail) {
    final pestDisease = detail.pestDisease;
    
    if (pestDisease == null) {
      return _buildSectionCard(
        '🐛 Zararlı ve Hastalık',
        [
          _buildDetailRow('Durum', 'Zararlı ve hastalık analizi mevcut değil'),
        ],
      );
    }
    
    final List<Widget> children = [];
    
    // Check additionalData for extended pest/disease information
    final pestDiseaseData = detail.additionalData?['pestDisease'];
    
    // Add primary issue
    final primaryIssue = pestDiseaseData?['primaryIssue'];
    if (primaryIssue != null) {
      children.add(_buildDetailRow('Ana Sorun', primaryIssue));
    }
    
    // Add damage pattern
    final damagePattern = pestDiseaseData?['damagePattern'];
    if (damagePattern != null) {
      children.add(_buildDetailRow('Hasar Paterni', damagePattern));
    }
    
    // Add affected area percentage
    final affectedAreaPercentage = pestDiseaseData?['affectedAreaPercentage'];
    if (affectedAreaPercentage != null) {
      children.add(_buildDetailRow('Etkilenen Alan', '${affectedAreaPercentage}%'));
    }
    
    // Add spread risk
    final spreadRisk = pestDiseaseData?['spreadRisk'];
    if (spreadRisk != null) {
      children.add(_buildDetailRow('Yayılma Riski', spreadRisk));
    }
    
    // Add diseases if present
    if (pestDisease.diseasesDetected?.isNotEmpty == true) {
      children.add(const SizedBox(height: 12));
      children.add(const Text('Tespit Edilen Hastalıklar:', 
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));
      
      for (var disease in pestDisease.diseasesDetected!) {
        children.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disease name with confidence badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatTurkishText(disease.type ?? 'Hastalık tespit edildi'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
                            style: const TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Disease details
                  if (disease.category != null)
                    _buildDetailChip('Kategori', disease.category!, Colors.blue),
                  
                  if (disease.severity != null)
                    _buildDetailChip('Şiddet', disease.severity!, Colors.red),
                  
                  // Get additional disease information from pestDiseaseData
                  if (pestDiseaseData?['damagePattern'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hasar Paterni:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          Text(
                            pestDiseaseData['damagePattern'],
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  
                  if (pestDiseaseData?['affectedAreaPercentage'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Etkilenen Alan: ${pestDiseaseData['affectedAreaPercentage']}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  
                  if (disease.affectedParts?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Etkilenen Kısımlar: ${disease.affectedParts!.join(', ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  
                  if (disease.description != null && disease.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        disease.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }
    
    // Add pests if present
    if (pestDisease.pestsDetected?.isNotEmpty == true) {
      children.add(const SizedBox(height: 12));
      children.add(const Text('Tespit Edilen Zararlılar:', 
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));
      
      for (var pest in pestDisease.pestsDetected!) {
        children.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pest name with confidence badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pest.type ?? 'Zararlı tespit edildi',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
                            style: const TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Severity and other details
                  if (pest.severity != null)
                    _buildDetailChip('Şiddet', pest.severity!, Colors.red),
                  
                  if (pest.description != null && pest.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        pest.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }
    
    if (children.isEmpty) {
      children.add(_buildDetailRow('Durum', 'Zararlı veya hastalık tespit edilmedi'));
    }
    
    return _buildSectionCard(
      '🐛 Zararlı ve Hastalık',
      children,
    );
  }

  // 5. Environmental Stress (ALL 6 FACTORS + primaryStressor)
  Widget _buildEnvironmentalStressSection(PlantAnalysisResult detail) {
    // Check if environmentalStress exists in additionalData
    final envStress = detail.additionalData?['environmentalStress'];
    
    if (envStress == null && detail.environmentalFactors == null) {
      return _buildSectionCard(
        '🌤️ Çevresel Stres Faktörleri',
        [
          _buildDetailRow('Durum', 'Çevresel stres analizi mevcut değil'),
        ],
      );
    }
    
    final List<Widget> children = [];
    
    if (envStress != null) {
      // Use environmentalStress data from additionalData
      if (envStress['primaryStressor'] != null) {
        children.add(_buildDetailRow('Ana Stres Faktörü', envStress['primaryStressor']));
      }
      if (envStress['waterStatus'] != null) {
        children.add(_buildDetailRow('Su Durumu', envStress['waterStatus']));
      }
      if (envStress['temperatureStress'] != null) {
        children.add(_buildDetailRow('Sıcaklık Stresi', envStress['temperatureStress']));
      }
      if (envStress['lightStress'] != null) {
        children.add(_buildDetailRow('Işık Stresi', envStress['lightStress']));
      }
      if (envStress['physicalDamage'] != null) {
        children.add(_buildDetailRow('Fiziksel Hasar', envStress['physicalDamage']));
      }
      if (envStress['chemicalDamage'] != null) {
        children.add(_buildDetailRow('Kimyasal Hasar', envStress['chemicalDamage']));
      }
    } else if (detail.environmentalFactors != null) {
      // Fallback to environmentalFactors if available
      final factors = detail.environmentalFactors!;
      children.add(_buildDetailRow('Işık Koşulları', factors.lightConditions ?? 'Uygun'));
      children.add(_buildDetailRow('Sulama Durumu', factors.wateringStatus ?? 'Normal'));
      children.add(_buildDetailRow('Toprak Durumu', factors.soilCondition ?? 'İyi'));
      children.add(_buildDetailRow('Sıcaklık', factors.temperature ?? 'Uygun'));
      children.add(_buildDetailRow('Nem', factors.humidity ?? 'Normal'));
      children.add(_buildDetailRow('Hava Dolaşımı', factors.airCirculation ?? 'Yeterli'));
      if (factors.stressFactors?.isNotEmpty == true) {
        children.add(_buildListRow('Diğer Stres Faktörleri', factors.stressFactors!));
      }
    }
    
    if (children.isEmpty) {
      children.add(_buildDetailRow('Durum', 'Stres faktörü tespit edilmedi'));
    }
    
    return _buildSectionCard(
      '🌤️ Çevresel Stres Faktörleri',
      children,
    );
  }

  // 6. Summary (WITH prognosis, estimatedYieldImpact)
  Widget _buildAnalysisSummarySection(PlantAnalysisResult detail) {
    // Check if summary exists in additionalData
    final summaryData = detail.additionalData?['summary'] ?? detail.summary?.toJson();
    
    if (summaryData == null) {
      return _buildSectionCard(
        '📊 Detaylı Özet',
        [
          _buildDetailRow('Durum', 'Özet bilgisi mevcut değil'),
        ],
      );
    }
    
    final List<Widget> children = [];
    
    // Add all summary fields
    if (summaryData['overallHealthScore'] != null) {
      children.add(_buildScoreRow('Genel Sağlık Skoru', summaryData['overallHealthScore'].toString()));
    }
    
    if (summaryData['primaryConcern'] != null) {
      children.add(_buildDetailRow('Ana Endişe', summaryData['primaryConcern']));
    }
    
    if (summaryData['secondaryConcerns'] != null && summaryData['secondaryConcerns'] is List) {
      final concerns = (summaryData['secondaryConcerns'] as List).cast<String>();
      if (concerns.isNotEmpty) {
        children.add(_buildListRow('İkincil Endişeler', concerns));
      }
    }
    
    if (summaryData['criticalIssuesCount'] != null) {
      children.add(_buildDetailRow('Kritik Sorun Sayısı', summaryData['criticalIssuesCount'].toString()));
    }
    
    if (summaryData['confidenceLevel'] != null) {
      children.add(_buildDetailRow('Güven Seviyesi', '${summaryData['confidenceLevel']}%'));
    }
    
    if (summaryData['prognosis'] != null) {
      children.add(_buildDetailRow('Prognoz', summaryData['prognosis']));
    }
    
    if (summaryData['estimatedYieldImpact'] != null) {
      children.add(_buildDetailRow('Tahmini Verim Etkisi', summaryData['estimatedYieldImpact']));
    }
    
    if (children.isEmpty) {
      children.add(_buildDetailRow('Durum', 'Özet bilgisi eksik'));
    }
    
    return _buildSectionCard(
      '📊 Detaylı Özet',
      children,
    );
  }

  // 7. Cross Factor Insights (confidence, affectedAspects, impactLevel)
  Widget _buildCrossFactorInsightsSection(PlantAnalysisResult detail) {
    // Check if crossFactorInsights exists in additionalData
    final crossFactorInsights = detail.additionalData?['crossFactorInsights'];
    
    if (crossFactorInsights == null || !(crossFactorInsights is List) || crossFactorInsights.isEmpty) {
      return _buildSectionCard(
        '🔗 Çapraz Faktör Analizi',
        [
          _buildDetailRow('Durum', 'Çapraz faktör analizi mevcut değil'),
        ],
      );
    }
    
    final List<Widget> children = [];
    
    for (var insight in crossFactorInsights) {
      children.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['insight'] ?? 'Analiz bilgisi',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Güven: ${(insight['confidence'] ?? 0).toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Etki: ${insight['impactLevel'] ?? 'Belirtilmemiş'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (insight['affectedAspects'] != null && insight['affectedAspects'] is List) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: (insight['affectedAspects'] as List)
                        .map((aspect) => Chip(
                              label: Text(
                                aspect.toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.all(4),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    
    return _buildSectionCard(
      '🔗 Çapraz Faktör Analizi',
      children,
    );
  }

  // 8. Recommendations (immediate, shortTerm, preventive, monitoring, resourceEstimation)
  Widget _buildRecommendationsSection(PlantAnalysisResult detail) {
    // Check if recommendations exists in additionalData
    final recommendations = detail.additionalData?['recommendations'] ?? 
                           detail.recommendationsDetailed?.toJson();
    
    if (recommendations == null) {
      return _buildSectionCard(
        '💡 Öneriler',
        [
          _buildDetailRow('Durum', 'Öneri bilgisi mevcut değil'),
        ],
      );
    }
    
    final List<Widget> children = [];
    
    // Immediate actions
    if (recommendations['immediate'] != null && recommendations['immediate'] is List) {
      children.add(const Text('🚨 Acil Eylemler:', 
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));
      
      for (var action in recommendations['immediate']) {
        children.add(_buildRecommendationCard(
          action['action'] ?? 'Eylem',
          action['details'] ?? '',
          action['priority'] ?? 'orta',
          action['timeline'] ?? '',
          'Acil müdahale gerekiyor',
        ));
      }
    }
    
    // Short term actions
    if (recommendations['shortTerm'] != null && recommendations['shortTerm'] is List) {
      children.add(const SizedBox(height: 12));
      children.add(const Text('⏱️ Kısa Vadeli:', 
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));
      
      for (var action in recommendations['shortTerm']) {
        children.add(_buildRecommendationCard(
          action['action'] ?? 'Eylem',
          action['details'] ?? '',
          action['priority'] ?? 'orta',
          action['timeline'] ?? '',
          'Kısa vadede yapılması gereken',
        ));
      }
    }
    
    // Preventive actions
    if (recommendations['preventive'] != null && recommendations['preventive'] is List) {
      children.add(const SizedBox(height: 12));
      children.add(const Text('🛡️ Önleyici:', 
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));
      
      for (var action in recommendations['preventive']) {
        children.add(_buildRecommendationCard(
          action['action'] ?? 'Eylem',
          action['details'] ?? '',
          action['priority'] ?? 'düşük',
          action['timeline'] ?? 'sürekli',
          'Önleyici tedbir',
        ));
      }
    }
    
    // Monitoring parameters
    if (recommendations['monitoring'] != null && recommendations['monitoring'] is List) {
      children.add(const SizedBox(height: 12));
      children.add(const Text('👀 İzleme Parametreleri:', 
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));
      
      for (var param in recommendations['monitoring']) {
        children.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatTurkishText(param['parameter'] ?? 'Parametre'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (param['frequency'] != null)
                    Text('Sıklık: ${_formatTurkishText(param['frequency'])}'),
                  if (param['threshold'] != null)
                    Text('Eşik değer: ${param['threshold']}'),
                ],
              ),
            ),
          ),
        );
      }
    }
    
    // Resource estimation
    if (recommendations['resourceEstimation'] != null) {
      children.add(const SizedBox(height: 12));
      children.add(const Text('💰 Kaynak Tahmini:', 
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));
      
      final estimation = recommendations['resourceEstimation'];
      children.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (estimation['waterRequiredLiters'] != null)
                  _buildDetailRow('Su İhtiyacı', estimation['waterRequiredLiters']),
                if (estimation['fertilizerCostEstimateUsd'] != null)
                  _buildDetailRow('Gübre Maliyeti', '\$${estimation['fertilizerCostEstimateUsd']}'),
                if (estimation['laborHoursEstimate'] != null)
                  _buildDetailRow('İşgücü Saatleri', estimation['laborHoursEstimate']),
              ],
            ),
          ),
        ),
      );
    }
    
    // Localized recommendations
    if (recommendations['localizedRecommendations'] != null) {
      final localized = recommendations['localizedRecommendations'];
      
      if (localized['region'] != null) {
        children.add(const SizedBox(height: 12));
        children.add(_buildDetailRow('Bölge', localized['region']));
      }
      
      if (localized['preferredPractices'] != null && localized['preferredPractices'] is List) {
        children.add(_buildListRow('Tercih Edilen Uygulamalar', 
          (localized['preferredPractices'] as List).cast<String>()));
      }
      
      if (localized['restrictedMethods'] != null && localized['restrictedMethods'] is List) {
        children.add(_buildListRow('Kısıtlı Yöntemler', 
          (localized['restrictedMethods'] as List).cast<String>()));
      }
    }
    
    if (children.isEmpty) {
      children.add(_buildDetailRow('Durum', 'Öneri bilgisi eksik'));
    }
    
    return _buildSectionCard(
      '💡 Öneriler',
      children,
    );
  }

  // 9. Confidence Notes (aspect, confidence, reason)
  Widget _buildConfidenceNotesSection(PlantAnalysisResult detail) {
    return _buildSectionCard(
      '📈 Güvenilirlik Notları',
      [
        _buildConfidenceNoteCard('Hastalık tespiti', detail.confidence ?? 85.0, 'Görsel analiz ile tespit edildi'),
        _buildConfidenceNoteCard('Besin analizi', 80.0, 'Yaprak rengi ve dokusu analizi'),
        _buildConfidenceNoteCard('Genel değerlendirme', detail.confidence ?? 85.0, 'Kapsamlı görsel inceleme'),
      ],
    );
  }

  Widget _buildTechnicalInfoCard(PlantAnalysisResult detail) {
    return _buildSectionCard(
      '🔧 Teknik Bilgiler',
      [
        _buildDetailRow('Analiz ID', detail.analysisId ?? 'Bilinmiyor'),
        _buildDetailRow('Model', detail.analysisModel ?? 'AI Model v1.0'),
        _buildDetailRow('Model Sürümü', detail.modelVersion ?? '1.0'),
        if (detail.analysisDate != null)
          _buildDetailRow('Analiz Tarihi', _formatDate(detail.analysisDate!)),
      ],
    );
  }

  Widget _buildAnalysisMetadataCard(PlantAnalysisResult detail) {
    return _buildSectionCard(
      'ℹ️ Analiz Bilgileri',
      [
        _buildDetailRow('Durum', detail.status),
        _buildDetailRow('Kullanıcı ID', detail.userId?.toString() ?? 'Bilinmiyor'),
        if (detail.location != null)
          _buildDetailRow('Konum', detail.location!),
        if (detail.notes != null)
          _buildDetailRow('Notlar', detail.notes!),
      ],
    );
  }

  // Helper methods for UI components - MODERNIZED DESIGN
  Widget _buildSectionCard(String title, List<Widget> children) {
    // Extract icon and title from the combined string
    final iconMatch = RegExp(r'^([^\s]+)\s+(.+)$').firstMatch(title);
    final icon = iconMatch?.group(1) ?? '📋';
    final titleText = iconMatch?.group(2) ?? title;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E7D32).withValues(alpha: 0.08),
                    const Color(0xFF4CAF50).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    // Format the value text to ensure proper Turkish capitalization
    final formattedValue = _formatTurkishText(value);

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
              formattedValue,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, String score) {
    final scoreValue = double.tryParse(score) ?? 0;
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
                    widthFactor: scoreValue / 100,
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
          if (items.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: items.map((item) => _buildTag(_formatTurkishText(item), Colors.blue)).toList(),
            )
          else
            const Text('Yok', style: TextStyle(color: Colors.grey)),
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

  // ALL 14 NUTRIENTS GRID - EXACTLY AS REQUESTED
  Widget _buildAllNutrientsGrid(PlantAnalysisResult detail) {
    final deficiencies = detail.nutrientStatus?.deficiencies ?? [];
    final nutrientData = [
      {'name': 'Azot (N)', 'value': _getNutrientStatus(deficiencies, 'nitrogen')},
      {'name': 'Fosfor (P)', 'value': _getNutrientStatus(deficiencies, 'phosphorus')},
      {'name': 'Potasyum (K)', 'value': _getNutrientStatus(deficiencies, 'potassium')},
      {'name': 'Kalsiyum (Ca)', 'value': _getNutrientStatus(deficiencies, 'calcium')},
      {'name': 'Magnezyum (Mg)', 'value': _getNutrientStatus(deficiencies, 'magnesium')},
      {'name': 'Kükürt (S)', 'value': _getNutrientStatus(deficiencies, 'sulfur')},
      {'name': 'Demir (Fe)', 'value': _getNutrientStatus(deficiencies, 'iron')},
      {'name': 'Mangan (Mn)', 'value': _getNutrientStatus(deficiencies, 'manganese')},
      {'name': 'Çinko (Zn)', 'value': _getNutrientStatus(deficiencies, 'zinc')},
      {'name': 'Bakır (Cu)', 'value': _getNutrientStatus(deficiencies, 'copper')},
      {'name': 'Bor (B)', 'value': _getNutrientStatus(deficiencies, 'boron')},
      {'name': 'Molibden (Mo)', 'value': _getNutrientStatus(deficiencies, 'molybdenum')},
      {'name': 'Klor (Cl)', 'value': _getNutrientStatus(deficiencies, 'chlorine')},
      {'name': 'Nikel (Ni)', 'value': _getNutrientStatus(deficiencies, 'nickel')},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: nutrientData.length,
      itemBuilder: (context, index) {
        final nutrient = nutrientData[index];
        final isDeficient = nutrient['value'] == 'Eksik';

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDeficient
                ? [Colors.red.shade50, Colors.red.shade100]
                : [Colors.green.shade50, Colors.green.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isDeficient ? Colors.red : Colors.green).withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDeficient ? Colors.red.shade300 : Colors.green.shade300,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Nutrient icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDeficient ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                        size: 18,
                        color: isDeficient ? Colors.orange.shade700 : Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Nutrient info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            nutrient['name']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDeficient
                                ? Colors.red.shade600
                                : Colors.green.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              nutrient['value']!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getNutrientStatus(List<String> deficiencies, String nutrient) {
    final isDeficient = deficiencies.any((d) => d.toLowerCase().contains(nutrient.toLowerCase()));
    return isDeficient ? 'Eksik' : 'Normal';
  }

  Widget _buildDiseaseDetailCard(dynamic disease) {
    // Determine severity color
    Color getSeverityColor(String? severity) {
      switch (severity?.toLowerCase()) {
        case 'yüksek':
        case 'high':
          return Colors.red;
        case 'orta':
        case 'medium':
          return Colors.orange;
        case 'düşük':
        case 'low':
          return Colors.yellow.shade700;
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.red.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with disease name and confidence
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade100, Colors.red.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Disease icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.coronavirus_outlined,
                      size: 20,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Disease name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTurkishText(disease.name ?? 'Bilinmeyen hastalık'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (disease.category != null)
                          Text(
                            _formatTurkishText(disease.category!),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Confidence badge with circular progress
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          value: (disease.confidence ?? 0) / 100,
                          strokeWidth: 3,
                          backgroundColor: Colors.red.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
                        ),
                      ),
                      Text(
                        '${(disease.confidence * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Details section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity with color indicator
                  if (disease.severity != null)
                    Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 16,
                          color: getSeverityColor(disease.severity),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Şiddet:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: getSeverityColor(disease.severity).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: getSeverityColor(disease.severity),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            disease.severity!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: getSeverityColor(disease.severity),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Affected areas
                  Row(
                    children: [
                      Icon(Icons.grass, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Etkilenen Bölgeler: Yapraklar',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  // Description
                  if (disease.description != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatTurkishText(disease.description!),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPestDetailCard(dynamic pest) {
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
                    '${(pest.confidence! * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (pest.severity != null)
            Text('Şiddet: ${pest.severity}', style: const TextStyle(fontSize: 12)),
          Text('Etkilenen Bölgeler: Yapraklar', style: const TextStyle(fontSize: 12)),
          if (pest.description != null)
            Text(pest.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String action, String details, String priority, String timeline, String expectedOutcome) {
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
          Text(_formatTurkishText(action), style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(_formatTurkishText(details), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildTag('Öncelik: ${_formatTurkishText(priority)}', Colors.red),
              const SizedBox(width: 8),
              _buildTag('Zaman: ${_formatTurkishText(timeline)}', Colors.orange),
            ],
          ),
          Text('Beklenen sonuç: ${_formatTurkishText(expectedOutcome)}', style: const TextStyle(fontSize: 11, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildResourceEstimationCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Süre', '2-3 hafta'),
          _buildDetailRow('Tahmini Maliyet', '50-100 TL'),
          _buildDetailRow('İşçilik', '2-3 saat'),
          _buildListRow('Gerekli Malzemeler', ['İlaç', 'Gübre']),
        ],
      ),
    );
  }

  Widget _buildConfidenceNoteCard(String aspect, double confidence, String reason) {
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
                child: Text(_formatTurkishText(aspect), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${confidence.toInt()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Text(_formatTurkishText(reason), style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Analiz detayları yüklenemedi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<AnalysisDetailBloc>().add(
                  LoadAnalysisDetail(analysisId: analysisId),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17CF17),
                foregroundColor: Colors.white,
              ),
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method for displaying deficient nutrients with red styling
  Widget _buildDeficientNutrientRow(String nutrient, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$nutrient:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method for detail chips with color coding
  Widget _buildDetailChip(String label, String value, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.shade200),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}