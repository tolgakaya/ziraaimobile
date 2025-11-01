import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/config/api_config.dart';
import '../../data/models/sponsored_analysis_detail.dart';
import '../../../plant_analysis/data/models/plant_analysis_detail_dto.dart';
import '../../../messaging/presentation/pages/sponsor_chat_conversation_page.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../authentication/data/datasources/auth_local_datasource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../messaging/presentation/bloc/messaging_bloc.dart';

/// Sponsored Analysis Detail Screen
/// EXACT COPY of farmer's analysis_detail_screen.dart design (images 1.png & 2.png)
/// User instruction: "farmer'ın aynısını alabilirsin"
class SponsoredAnalysisDetailScreen extends StatefulWidget {
  final int analysisId;

  const SponsoredAnalysisDetailScreen({
    super.key,
    required this.analysisId,
  });

  @override
  State<SponsoredAnalysisDetailScreen> createState() =>
      _SponsoredAnalysisDetailScreenState();
}

class _SponsoredAnalysisDetailScreenState
    extends State<SponsoredAnalysisDetailScreen> {
  late Future<SponsoredAnalysisDetailResponse> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadAnalysisDetail();
  }

  Future<SponsoredAnalysisDetailResponse> _loadAnalysisDetail() async {
    try {
      final networkClient = GetIt.instance<NetworkClient>();
      final secureStorage = GetIt.instance<SecureStorageService>();
      final token = await secureStorage.getToken();

      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('📊 Loading sponsored analysis detail: ${widget.analysisId}');

      final response = await networkClient.get(
        '${ApiConfig.sponsoredAnalysisDetail}/${widget.analysisId}',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      print('✅ Sponsored analysis detail loaded');
      print('🔍 RAW API RESPONSE tier data: ${response.data['data']['tierMetadata']}');

      if (response.data['success'] == true && response.data['data'] != null) {
        final detail = SponsoredAnalysisDetailResponse.fromJson(
          response.data['data'],
        );
        print('🔍 PARSED TIER: tierName=${detail.tierMetadata.tierName}, canMessage=${detail.tierMetadata.canMessage}');
        return detail;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load analysis');
      }
    } catch (e) {
      print('❌ Error loading sponsored analysis detail: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: FutureBuilder<SponsoredAnalysisDetailResponse>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Veri bulunamadı'));
          }

          return _buildContent(snapshot.data!);
        },
      ),
      floatingActionButton: FutureBuilder<SponsoredAnalysisDetailResponse>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final data = snapshot.data!;
          final tier = data.tierMetadata;

          // ✅ Hide FAB if messaging not allowed for this tier
          if (!tier.canMessage) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () async {
              // Get sponsor ID directly from analysis data (no GetIt needed!)
              final sponsorUserId = data.analysis.sponsorUserId;

              if (sponsorUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sponsor bilgisi bulunamadı')),
                );
                return;
              }

              // ✅ Navigate to chat and refresh when returning
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => GetIt.I<MessagingBloc>(),
                    child: SponsorChatConversationPage(
                      plantAnalysisId: data.analysis.id,
                      sponsorUserId: sponsorUserId,  // ✅ From analysis data
                      farmerId: data.analysis.userId ?? 0,  // ✅ Farmer is other user
                      sponsorshipTier: data.tierMetadata.tierName,
                      farmerName: data.analysis.farmerId,  // ✅ Pass farmer ID as name
                      analysisImageUrl: data.analysis.imageUrl,
                      analysisSummary: data.analysis.farmerFriendlySummary,
                    ),
                  ),
                ),
              );
              
              // ✅ Refresh detail after returning from chat (updates unread count)
              if (mounted) {
                setState(() {
                  // Trigger rebuild to refresh detail
                });
              }
            },
            label: const Text('Çiftçiye Mesaj Gönder'),
            icon: const Icon(Icons.send),
            backgroundColor: const Color(0xFF17CF17),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Bir hata oluştu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _detailFuture = _loadAnalysisDetail();
                });
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SponsoredAnalysisDetailResponse data) {
    final analysis = data.analysis;
    final tier = data.tierMetadata;

    // Extract plant species name for title (matching farmer's screen)
    String plantName = 'Analiz Detayı';
    if (analysis.plantIdentification != null &&
        analysis.plantIdentification!.species != null) {
      plantName = _formatTurkishText(analysis.plantIdentification!.species!);
    }

    // Get confidence for badge
    int confidence = (analysis.summary?.confidenceLevel?.toInt()) ?? 85;
    
    // Get severity for badge
    String severity = analysis.healthAssessment?.severity ?? 'orta';

    return CustomScrollView(
      slivers: [
        // Hero Section - EXACT copy from farmer's screen (image 1)
        _buildSliverAppBar(analysis, plantName, confidence, severity),

        // Content - EXACT order from farmer's screen (images 1 & 2)
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. Farmer Friendly Summary (Green gradient card - image 1)
              if (analysis.farmerFriendlySummary != null) ...[
                _buildFarmerFriendlySummarySection(analysis.farmerFriendlySummary!),
                const SizedBox(height: 16),
              ],

              // 2. Bitki Tanımlama (White card - image 2)
              if (analysis.plantIdentification != null) ...[
                _buildPlantIdentificationSection(analysis.plantIdentification!),
                const SizedBox(height: 16),
              ],

              // 3. Sağlık Değerlendirmesi (White card with progress bar - image 2)
              if (analysis.healthAssessment != null) ...[
                _buildHealthAssessmentSection(analysis.healthAssessment!),
                const SizedBox(height: 16),
              ],

              // 4. Besin Durumu (Nutrient Status) - White card (image 4)
              if (analysis.nutrientStatus != null) ...[
                _buildNutrientStatusSection(analysis.nutrientStatus!),
                const SizedBox(height: 16),
              ],

              // 5. Zararlı ve Hastalık (Pest & Disease) - White card (images 5-6)
              if (analysis.pestDisease != null) ...[
                _buildPestDiseaseSection(analysis.pestDisease!),
                const SizedBox(height: 16),
              ],

              // 6. Çevresel Stres Faktörleri (Environmental Stress) - White card (image 7)
              if (analysis.environmentalStress != null) ...[
                _buildEnvironmentalStressSection(analysis.environmentalStress!),
                const SizedBox(height: 16),
              ],

              // 7. Detaylı Özet (Summary) - White card (image 8)
              if (analysis.summary != null) ...[
                _buildAnalysisSummarySection(analysis.summary!),
                const SizedBox(height: 16),
              ],

              // 8. Çapraz Faktör Analizi (Cross Factor Insights) - White card (image 9)
              if (analysis.crossFactorInsights != null && analysis.crossFactorInsights!.isNotEmpty) ...[
                _buildCrossFactorInsightsSection(analysis.crossFactorInsights!),
                const SizedBox(height: 16),
              ],

              // 9. Öneriler (Recommendations) - White card (images 10-11)
              if (analysis.recommendations != null) ...[
                _buildRecommendationsSection(analysis.recommendations!),
                const SizedBox(height: 16),
              ],

              // Tier Badge at bottom (not shown in images 1-2, will add after approval)
              _buildTierBadge(tier),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  // Hero Section - EXACT copy from farmer's screen
  Widget _buildSliverAppBar(
    SponsoredAnalysisData analysis,
    String plantName,
    int confidence,
    String severity,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.black87, size: 20),
          ),
          onPressed: () {
            // Camera action
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Plant image
            if (analysis.imageUrl != null)
              Image.network(
                analysis.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.local_florist, size: 80, color: Colors.white),
                  );
                },
              )
            else
              Container(
                color: Colors.grey[300],
                child: const Icon(Icons.local_florist, size: 80, color: Colors.white),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Bottom content: badges and plant name
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badges row
                  Row(
                    children: [
                      // Confidence badge (white)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$confidence% Güven',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Severity badge (orange for "orta")
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(severity),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatTurkishText(severity),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Plant name
                  Text(
                    plantName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Color.fromARGB(128, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Farmer Friendly Summary - Green gradient card (image 1)
  Widget _buildFarmerFriendlySummarySection(String farmerSummary) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '🚜',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 12),
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
            _formatTurkishText(farmerSummary),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Bitki Tanımlama - White card (image 2)
  Widget _buildPlantIdentificationSection(PlantIdentificationDto plantId) {
    return _buildSectionCard(
      '🌿 Bitki Tanımlama',
      [
        if (plantId.species != null)
          _buildDetailRow('Tür', _formatTurkishText(plantId.species!)),
        if (plantId.variety != null && plantId.variety != 'Bilinmiyor')
          _buildDetailRow('Çeşit', _formatTurkishText(plantId.variety!)),
        if (plantId.growthStage != null)
          _buildDetailRow('Büyüme Evresi', _formatTurkishText(plantId.growthStage!)),
        if (plantId.confidence != null)
          _buildDetailRow('Güven Oranı', '${plantId.confidence!.toInt()}%'),
        
        // Tags (blue chips)
        if (plantId.identifyingFeatures.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Tanımlayıcı Özellikler:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plantId.identifyingFeatures.map((char) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _formatTurkishText(char),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // 4. Besin Durumu - White card (EXACT from image 4)
  Widget _buildNutrientStatusSection(NutrientStatusDto nutrient) {
    final List<Widget> children = [];
    
    // Ana Eksiklik (Primary Deficiency)
    if (nutrient.primaryDeficiency != null && nutrient.primaryDeficiency!.isNotEmpty) {
      children.add(_buildDetailRow('Ana Eksiklik', _formatTurkishText(nutrient.primaryDeficiency!)));
    }
    
    // Eksik olanları bul ve göster (sadece "eksik" olanlar, pembe badge ile)
    final Map<String, String> nutrients = {
      'nitrogen': 'Azot (N)',
      'phosphorus': 'Fosfor (P)',
      'potassium': 'Potasyum (K)',
      'calcium': 'Kalsiyum (Ca)',
      'magnesium': 'Magnezyum (Mg)',
      'sulfur': 'Kükürt (S)',
      'iron': 'Demir (Fe)',
      'zinc': 'Çinko (Zn)',
      'manganese': 'Mangan (Mn)',
      'boron': 'Bor (B)',
      'copper': 'Bakır (Cu)',
      'molybdenum': 'Molibden (Mo)',
      'chlorine': 'Klor (Cl)',
      'nickel': 'Nikel (Ni)',
    };
    
    // Helper to get nutrient status
    String getNutrientStatus(String key) {
      switch (key) {
        case 'nitrogen': return nutrient.nitrogen;
        case 'phosphorus': return nutrient.phosphorus;
        case 'potassium': return nutrient.potassium;
        case 'calcium': return nutrient.calcium;
        case 'magnesium': return nutrient.magnesium;
        case 'sulfur': return nutrient.sulfur;
        case 'iron': return nutrient.iron;
        case 'zinc': return nutrient.zinc;
        case 'manganese': return nutrient.manganese;
        case 'boron': return nutrient.boron;
        case 'copper': return nutrient.copper;
        case 'molybdenum': return nutrient.molybdenum;
        case 'chlorine': return nutrient.chlorine;
        case 'nickel': return nutrient.nickel;
        default: return 'normal';
      }
    }
    
    // Sadece "eksik" olanları göster
    nutrients.forEach((key, displayName) {
      final status = getNutrientStatus(key);
      if (status.toLowerCase() == 'eksik') {
        children.add(_buildDeficientNutrientRow(displayName, 'Eksik'));
      }
    });
    
    // İkincil Eksiklikler (Secondary Deficiencies) - mavi chip'ler
    if (nutrient.secondaryDeficiencies != null && nutrient.secondaryDeficiencies!.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(
        const Text(
          'İkincil Eksiklikler:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      );
      children.add(const SizedBox(height: 8));
      children.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: nutrient.secondaryDeficiencies!.map((deficiency) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                _formatTurkishText(deficiency),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
    
    // Şiddet (Severity)
    children.add(_buildDetailRow('Şiddet', _formatTurkishText(nutrient.severity)));
    
    return _buildSectionCard(
      '🧪 Besin Durumu',
      children,
    );
  }

  // Helper: Deficient nutrient row with pink badge (image 4 style)
  Widget _buildDeficientNutrientRow(String nutrient, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Zararlı ve Hastalık - White card (EXACT from images 5-6)
  Widget _buildPestDiseaseSection(PestDiseaseDto pestDisease) {
    final List<Widget> children = [];

    // Ana Sorun (Primary Issue)
    if (pestDisease.primaryIssue != null && pestDisease.primaryIssue!.isNotEmpty) {
      children.add(_buildDetailRow('Ana Sorun', _formatTurkishText(pestDisease.primaryIssue!)));
    }

    // Hasar Paterni (Damage Pattern)
    if (pestDisease.damagePattern != null && pestDisease.damagePattern!.isNotEmpty) {
      children.add(_buildDetailRow('Hasar Paterni', _formatTurkishText(pestDisease.damagePattern!)));
    }

    // Etkilenen Alan (Affected Area Percentage)
    if (pestDisease.affectedAreaPercentage != null) {
      children.add(_buildDetailRow('Etkilenen Alan', '${pestDisease.affectedAreaPercentage}%'));
    }

    // Yayılma Riski (Spread Risk)
    if (pestDisease.spreadRisk != null && pestDisease.spreadRisk!.isNotEmpty) {
      children.add(_buildDetailRow('Yayılma Riski', _formatTurkishText(pestDisease.spreadRisk!)));
    }

    // Tespit Edilen Hastalıklar (Diseases Detected)
    if (pestDisease.diseasesDetected.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(const Text(
        'Tespit Edilen Hastalıklar:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ));
      children.add(const SizedBox(height: 8));

      for (var disease in pestDisease.diseasesDetected) {
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

                  // Category chip (blue)
                  if (disease.category != null)
                    _buildDetailChip('Kategori', disease.category!, Colors.blue),

                  // Severity chip (red/orange)
                  if (disease.severity != null)
                    _buildDetailChip('Şiddet', disease.severity!, _getSeverityChipColor(disease.severity!)),

                  // Hasar Paterni (from disease card)
                  if (pestDisease.damagePattern != null && pestDisease.damagePattern!.isNotEmpty)
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
                            _formatTurkishText(pestDisease.damagePattern!),
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),

                  // Etkilenen Alan (from disease card)
                  if (pestDisease.affectedAreaPercentage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Etkilenen Alan: ${pestDisease.affectedAreaPercentage}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),

                  // Affected parts
                  if (disease.affectedParts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Etkilenen Kısımlar: ${disease.affectedParts.join(', ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Tespit Edilen Zararlılar (Pests Detected) - turuncu kartlar
    if (pestDisease.pestsDetected.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(const Text(
        'Tespit Edilen Zararlılar:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ));
      children.add(const SizedBox(height: 8));

      for (var pest in pestDisease.pestsDetected) {
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
                          _formatTurkishText(pest.type ?? 'Zararlı tespit edildi'),
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

                  // Severity
                  if (pest.severity != null)
                    _buildDetailChip('Şiddet', pest.severity!, _getSeverityChipColor(pest.severity!)),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Hiçbir şey yoksa
    if (children.isEmpty) {
      children.add(_buildDetailRow('Durum', 'Zararlı veya hastalık tespit edilmedi'));
    }

    return _buildSectionCard(
      '🐛 Zararlı ve Hastalık',
      children,
    );
  }

  // 6. Çevresel Stres Faktörleri - White card (EXACT from image 7)
  Widget _buildEnvironmentalStressSection(EnvironmentalStressDto envStress) {
    final List<Widget> children = [];

    // Ana Stres Faktörü (Primary Stressor)
    if (envStress.primaryStressor != null && envStress.primaryStressor!.isNotEmpty) {
      children.add(_buildDetailRow('Ana Stres Faktörü', _formatTurkishText(envStress.primaryStressor!)));
    }

    // Su Durumu (Water Status)
    if (envStress.waterStatus != null && envStress.waterStatus!.isNotEmpty) {
      children.add(_buildDetailRow('Su Durumu', _formatTurkishText(envStress.waterStatus!)));
    }

    // Sıcaklık Stresi (Temperature Stress)
    if (envStress.temperatureStress != null && envStress.temperatureStress!.isNotEmpty) {
      children.add(_buildDetailRow('Sıcaklık Stresi', _formatTurkishText(envStress.temperatureStress!)));
    }

    // Işık Stresi (Light Stress)
    if (envStress.lightStress != null && envStress.lightStress!.isNotEmpty) {
      children.add(_buildDetailRow('Işık Stresi', _formatTurkishText(envStress.lightStress!)));
    }

    // Fiziksel Hasar (Physical Damage)
    if (envStress.physicalDamage != null && envStress.physicalDamage!.isNotEmpty) {
      children.add(_buildDetailRow('Fiziksel Hasar', _formatTurkishText(envStress.physicalDamage!)));
    }

    // Kimyasal Hasar (Chemical Damage)
    if (envStress.chemicalDamage != null && envStress.chemicalDamage!.isNotEmpty) {
      children.add(_buildDetailRow('Kimyasal Hasar', _formatTurkishText(envStress.chemicalDamage!)));
    }

    // Hiçbir şey yoksa
    if (children.isEmpty) {
      children.add(_buildDetailRow('Durum', 'Stres faktörü tespit edilmedi'));
    }

    return _buildSectionCard(
      '🌤️ Çevresel Stres Faktörleri',
      children,
    );
  }

  // 7. Detaylı Özet - White card (EXACT from image 8)
  Widget _buildAnalysisSummarySection(SummaryDto summary) {
    final List<Widget> children = [];

    // Genel Sağlık Skoru (Overall Health Score) - with progress bar
    if (summary.overallHealthScore != null) {
      children.add(_buildScoreRow(
        'Genel Sağlık Skoru',
        summary.overallHealthScore.toString(),
        summary.overallHealthScore!.toInt(),
      ));
    }

    // Ana Endişe (Primary Concern)
    if (summary.primaryConcern != null && summary.primaryConcern!.isNotEmpty) {
      children.add(_buildDetailRow('Ana Endişe', _formatTurkishText(summary.primaryConcern!)));
    }

    // İkincil Endişeler (Secondary Concerns) - blue chips
    if (summary.secondaryConcerns != null && summary.secondaryConcerns!.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(
        const Text(
          'İkincil Endişeler:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      );
      children.add(const SizedBox(height: 8));
      children.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: summary.secondaryConcerns!.map((concern) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                _formatTurkishText(concern),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    // Kritik Sorun Sayısı (Critical Issues Count)
    if (summary.criticalIssuesCount != null) {
      children.add(_buildDetailRow('Kritik Sorun Sayısı', summary.criticalIssuesCount.toString()));
    }

    // Güven Seviyesi (Confidence Level) - as percentage
    if (summary.confidenceLevel != null) {
      children.add(_buildDetailRow('Güven Seviyesi', '${summary.confidenceLevel!.toInt()}%'));
    }

    // Prognoz (Prognosis)
    if (summary.prognosis != null && summary.prognosis!.isNotEmpty) {
      children.add(_buildDetailRow('Prognoz', _formatTurkishText(summary.prognosis!)));
    }

    // Tahmini Verim Etkisi (Estimated Yield Impact)
    if (summary.estimatedYieldImpact != null && summary.estimatedYieldImpact!.isNotEmpty) {
      children.add(_buildDetailRow('Tahmini Verim Etkisi', _formatTurkishText(summary.estimatedYieldImpact!)));
    }

    // Hiçbir şey yoksa
    if (children.isEmpty) {
      children.add(_buildDetailRow('Durum', 'Özet bilgisi eksik'));
    }

    return _buildSectionCard(
      '📊 Detaylı Özet',
      children,
    );
  }

  // 3. Sağlık Değerlendirmesi - White card (EXACT from image 3)
  Widget _buildHealthAssessmentSection(HealthAssessmentDto health) {
    return _buildSectionCard(
      '💚 Sağlık Değerlendirmesi',
      [
        // Canlılık Skoru (sadece sayı, no progress bar)
        _buildDetailRow('Canlılık Skoru', health.vigorScore.toString()),
        
        // Yaprak Rengi
        _buildDetailRow('Yaprak Rengi', _formatTurkishText(health.leafColor)),
        
        // Yaprak Dokusu
        _buildDetailRow('Yaprak Dokusu', _formatTurkishText(health.leafTexture)),
        
        // Büyüme Deseni
        _buildDetailRow('Büyüme Deseni', _formatTurkishText(health.growthPattern)),
        
        // Yapısal Bütünlük
        _buildDetailRow('Yapısal Bütünlük', _formatTurkishText(health.structuralIntegrity)),
        
        // Ciddiyet
        _buildDetailRow('Ciddiyet', _formatTurkishText(health.severity)),
        
        // Stres Göstergeleri (blue chips)
        if (health.stressIndicators.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Stres Göstergeleri:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: health.stressIndicators.map((indicator) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _formatTurkishText(indicator),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        
        // Hastalık Belirtileri (blue chips)
        if (health.diseaseSymptoms.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Hastalık Belirtileri:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: health.diseaseSymptoms.map((symptom) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _formatTurkishText(symptom),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // Helper: Section card (white card with icon header)
  Widget _buildSectionCard(String title, List<Widget> children) {
    // Extract icon and title
    final iconMatch = RegExp(r'^([^\s]+)\s+(.+)$').firstMatch(title);
    final icon = iconMatch?.group(1) ?? '📋';
    final titleText = iconMatch?.group(2) ?? title;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Detail row (label: value)
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Score row with progress bar
  Widget _buildScoreRow(String label, String value, int score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: score / 10,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      ],
    );
  }

  // Tier Badge (will be at bottom - after user approval)
  Widget _buildTierBadge(AnalysisTierMetadata tier) {
    MaterialColor tierColor;
    IconData tierIcon;

    switch (tier.tierName) {
      case 'XL':
        tierColor = Colors.purple;
        tierIcon = Icons.workspace_premium;
        break;
      case 'L':
        tierColor = Colors.blue;
        tierIcon = Icons.business_center;
        break;
      case 'M':
        tierColor = Colors.orange;
        tierIcon = Icons.business;
        break;
      case 'S':
      default:
        tierColor = Colors.green;
        tierIcon = Icons.storefront;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierColor.shade700, tierColor.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: tierColor.shade700.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(tierIcon, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tier.tierName} Tier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${tier.accessPercentage}% Erişim',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tier.sponsorInfo.companyName,
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

  // Helper: Format Turkish text with proper capitalization
  String _formatTurkishText(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Helper: Get severity color (for badges)
  Color _getSeverityColor(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('yüksek') || s.contains('high') || s.contains('kritik')) {
      return Colors.red.shade600;
    } else if (s.contains('orta') || s.contains('medium') || s.contains('moderate')) {
      return Colors.orange.shade600;
    } else if (s.contains('düşük') || s.contains('low') || s.contains('hafif')) {
      return Colors.yellow.shade700;
    }
    return Colors.grey.shade600;
  }

  // Helper: Get severity color for chips (MaterialColor)
  MaterialColor _getSeverityChipColor(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('yüksek') || s.contains('high') || s.contains('kritik')) {
      return Colors.red;
    } else if (s.contains('orta') || s.contains('medium') || s.contains('moderate')) {
      return Colors.orange;
    } else if (s.contains('düşük') || s.contains('low') || s.contains('hafif')) {
      return Colors.yellow;
    }
    return Colors.grey;
  }

  // Helper: Detail chip with color coding (for disease/pest cards)
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
              _formatTurkishText(value),
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

  // 8. Çapraz Faktör Analizi - White card (EXACT from image 9)
  Widget _buildCrossFactorInsightsSection(List<CrossFactorInsightDto> insights) {
    final List<Widget> children = [];

    for (var insight in insights) {
      children.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.insight,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Güven: ${insight.confidence.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Etki: ${_formatTurkishText(insight.impactLevel)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (insight.affectedAspects.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: insight.affectedAspects
                        .map((aspect) => Chip(
                              label: Text(
                                aspect,
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

  // 9. Öneriler - White card (EXACT from images 10-11)
  Widget _buildRecommendationsSection(RecommendationsDto recommendations) {
    final List<Widget> children = [];

    // Immediate actions
    if (recommendations.immediate.isNotEmpty) {
      children.add(const Text('🚨 Acil Eylemler:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));

      for (var action in recommendations.immediate) {
        children.add(_buildRecommendationCard(
          action.action,
          action.details,
          action.priority,
          action.timeline,
          'Acil müdahale gerekiyor',
        ));
      }
    }

    // Short term actions
    if (recommendations.shortTerm.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(const Text('⏱️ Kısa Vadeli:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));

      for (var action in recommendations.shortTerm) {
        children.add(_buildRecommendationCard(
          action.action,
          action.details,
          action.priority,
          action.timeline,
          'Kısa vadede yapılması gereken',
        ));
      }
    }

    // Preventive actions
    if (recommendations.preventive.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(const Text('🛡️ Önleyici:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));

      for (var action in recommendations.preventive) {
        children.add(_buildRecommendationCard(
          action.action,
          action.details,
          action.priority,
          action.timeline,
          'Önleyici tedbir',
        ));
      }
    }

    // Monitoring parameters
    if (recommendations.monitoring.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(const Text('👀 İzleme Parametreleri:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));

      for (var param in recommendations.monitoring) {
        children.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatTurkishText(param.parameter),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Sıklık: ${_formatTurkishText(param.frequency)}'),
                  Text('Eşik değer: ${param.threshold}'),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Resource estimation
    if (recommendations.resourceEstimation != null) {
      children.add(const SizedBox(height: 12));
      children.add(const Text('💰 Kaynak Tahmini:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)));
      children.add(const SizedBox(height: 8));

      final estimation = recommendations.resourceEstimation!;
      children.add(
        Card(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Su İhtiyacı', estimation.waterRequiredLiters),
                _buildDetailRow('Gübre Maliyeti', '\$${estimation.fertilizerCostEstimateUsd}'),
                _buildDetailRow('İşgücü Saatleri', estimation.laborHoursEstimate),
              ],
            ),
          ),
        ),
      );
    }

    // Localized recommendations
    if (recommendations.localizedRecommendations != null) {
      final localized = recommendations.localizedRecommendations!;

      children.add(const SizedBox(height: 12));
      children.add(_buildDetailRow('Bölge', localized.region));

      if (localized.preferredPractices.isNotEmpty) {
        children.add(_buildListRow('Tercih Edilen Uygulamalar',
          localized.preferredPractices));
      }

      if (localized.restrictedMethods.isNotEmpty) {
        children.add(_buildListRow('Kısıtlı Yöntemler',
          localized.restrictedMethods));
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

  // Helper: Recommendation card (for immediate, shortTerm, preventive actions)
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
          if (details.isNotEmpty)
            Text(_formatTurkishText(details), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Öncelik: ${_formatTurkishText(priority)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (timeline.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Zaman: ${_formatTurkishText(timeline)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Beklenen sonuç: ${_formatTurkishText(expectedOutcome)}',
            style: TextStyle(fontSize: 11, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  // Helper: List row for localized recommendations
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
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          _formatTurkishText(item),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ))
          else
            const Text('Yok', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
