import 'package:flutter/material.dart';
import 'dart:io';
import '../../../plant_analysis/presentation/pages/analysis_results_screen.dart';
import '../../../plant_analysis/presentation/screens/analysis_detail_screen.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/config/api_config.dart';
import 'package:dio/dio.dart';

class RecentAnalysesGrid extends StatefulWidget {
  const RecentAnalysesGrid({super.key});

  @override
  State<RecentAnalysesGrid> createState() => _RecentAnalysesGridState();
}

class _RecentAnalysesGridState extends State<RecentAnalysesGrid> {
  late Future<List<AnalysisItem>> _analysesFuture;

  @override
  void initState() {
    super.initState();
    _analysesFuture = _loadAnalyses();
  }

  Future<List<AnalysisItem>> _loadAnalyses() async {
    try {
      print('🚀🚀🚀 CLAUDE: Starting to load analyses with NEW CODE! 🚀🚀🚀');
      // Get network client and auth token
      final networkClient = getIt<NetworkClient>();
      final secureStorage = getIt<SecureStorageService>();
      final token = await secureStorage.getToken();

      if (token == null) {
        print('🚀 CLAUDE: No token found, returning mock data');
        // If no token, show mock data for demo
        return _getMockAnalyses();
      }

      print('🚀 CLAUDE: Making API call to plantanalyses/list');
      // Make API call to get analysis list
      final response = await networkClient.get(
        ApiConfig.plantAnalysesList,
        queryParameters: {'page': 1, 'pageSize': 10},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        print('🚀 CLAUDE: Response data type: ${response.data['data'].runtimeType}');
        print('🚀 CLAUDE: Response data content: ${response.data['data']}');

        final dynamic data = response.data['data'];
        List<dynamic> analyses = [];

        if (data is Map<String, dynamic>) {
          print('🚀 CLAUDE: Data is Map, extracting analyses array');
          // If data is a Map with analyses array
          analyses = data['analyses'] as List<dynamic>? ?? [];
        } else if (data is List<dynamic>) {
          print('🚀 CLAUDE: Data is List, using directly');
          // If data is directly a List of analyses
          analyses = data;
        } else {
          print('🚀 CLAUDE: Unknown data type: ${data.runtimeType}');
        }

        print('🚀 CLAUDE: Found ${analyses.length} analyses, converting to AnalysisItem');
        return analyses.map((item) => _convertToAnalysisItem(item as Map<String, dynamic>)).toList();
      } else {
        print('🚀 CLAUDE: API call failed or no data, returning mock data');
        // Fallback to mock data if API fails
        return _getMockAnalyses();
      }
    } catch (e) {
      print('🚀 CLAUDE: ERROR in _loadAnalyses: $e');
      // Fallback to mock data on error
      return _getMockAnalyses();
    }
  }

  /// Convert API response to AnalysisItem
  AnalysisItem _convertToAnalysisItem(Map<String, dynamic> apiItem) {
    print('🔍 CLAUDE: Converting API item: ${apiItem.keys}');
    print('🔍 CLAUDE: thumbnailUrl: ${apiItem['thumbnailUrl']}');
    print('🔍 CLAUDE: imagePath: ${apiItem['imagePath']}');
    print('🔍 CLAUDE: imageUrl: ${apiItem['imageUrl']}');

    // Try multiple possible image URL fields from API response
    String imageUrl = apiItem['thumbnailUrl'] ??
                     apiItem['imagePath'] ??
                     apiItem['imageUrl'] ??
                     apiItem['image'] ??
                     'assets/images/mock_plant1.jpg';

    print('🔍 CLAUDE: Final imageUrl: $imageUrl');

    return AnalysisItem(
      id: apiItem['id']?.toString() ?? apiItem['analysisId'] ?? '',  // Use numeric ID first
      plantName: apiItem['plantSpecies'] ?? 'Bilinmeyen Bitki',
      analysisDate: apiItem['formattedDate'] ?? _formatDate(apiItem['createdDate'] ?? apiItem['analysisDate']),
      status: _mapStatus(apiItem['status']),
      imageUrl: imageUrl,
      description: apiItem['primaryConcern'] ?? 'Analiz tamamlandı',
    );
  }

  /// Format API date to user-friendly format
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Bilinmeyen';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) return 'Bugün';
      if (difference == 1) return 'Dün';
      if (difference < 7) return '$difference gün önce';
      if (difference < 30) return '${(difference / 7).round()} hafta önce';
      return '${(difference / 30).round()} ay önce';
    } catch (e) {
      return dateStr;
    }
  }

  /// Map API status to UI status
  AnalysisStatus _mapStatus(String? apiStatus) {
    switch (apiStatus?.toLowerCase()) {
      case 'completed':
        return AnalysisStatus.healthy;
      case 'processing':
      case 'pending':
        return AnalysisStatus.warning;
      case 'failed':
      case 'error':
        return AnalysisStatus.disease;
      default:
        return AnalysisStatus.healthy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AnalysisItem>>(
      future: _analysesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final analyses = snapshot.data ?? _getMockAnalyses();

        if (analyses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Henüz analiz geçmişi yok',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'İlk bitki analizinizi yapmak için "Bitki Analizi" butonuna tıklayın',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: analyses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final analysis = analyses[index];
            return _AnalysisCard(analysis: analysis);
          },
        );
      },
    );
  }

  List<AnalysisItem> _getMockAnalyses() {
    return [
      AnalysisItem(
        id: '1',
        plantName: 'Domates Bitkisi',
        analysisDate: '2 gün önce',
        status: AnalysisStatus.healthy,
        imageUrl: 'assets/images/mock_plant1.jpg',
        description: 'Genel sağlık durumu iyi, büyüme oranları normal seviyede',
      ),
      AnalysisItem(
        id: '2',
        plantName: 'Mısır Tarlası',
        analysisDate: '3 gün önce',
        status: AnalysisStatus.warning,
        imageUrl: 'assets/images/mock_plant2.jpg',
        description: 'Hafif beslenme eksikliği tespit edildi, gübreleme önerisi',
      ),
      AnalysisItem(
        id: '3',
        plantName: 'Buğday Ürünü',
        analysisDate: '5 gün önce',
        status: AnalysisStatus.healthy,
        imageUrl: 'assets/images/mock_plant3.jpg',
        description: 'Mükemmel gelişim gösteriyor, hasat zamanı yaklaşıyor',
      ),
      AnalysisItem(
        id: '4',
        plantName: 'Soya Fasulyesi',
        analysisDate: '1 hafta önce',
        status: AnalysisStatus.disease,
        imageUrl: 'assets/images/mock_plant4.jpg',
        description: 'Fungal enfeksiyon riski, acil müdahale gerekiyor',
      ),
    ];
  }

}

class _AnalysisCard extends StatelessWidget {
  final AnalysisItem analysis;

  const _AnalysisCard({
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to analysis detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisDetailScreen(
              analysisId: analysis.id.toString(),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: const Color(0xFFF3F4F6), // Placeholder color
              ),
              child: Stack(
                children: [
                  // Plant Image (real analyzed image from API)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: _buildPlantImage(analysis.imageUrl),
                  ),
                  // Status Badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _StatusBadge(status: analysis.status),
                  ),
                ],
              ),
            ),
            // Plant Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis.plantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysis.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysis.analysisDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
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

  /// Build plant image widget with network loading and fallback
  Widget _buildPlantImage(String imageUrl) {
    print('📸 CLAUDE: Building image for URL: $imageUrl');

    // Check if it's a network URL or asset path
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF3F4F6),
                    const Color(0xFFE5E7EB),
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ CLAUDE: Failed to load image: $imageUrl, Error: $error');
            return _buildFallbackImage();
          },
        ),
      );
    } else {
      // Asset image or fallback
      return _buildFallbackImage();
    }
  }

  /// Build fallback placeholder image
  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF3F4F6),
            const Color(0xFFE5E7EB),
          ],
        ),
      ),
      child: const Icon(
        Icons.local_florist,
        size: 48,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AnalysisStatus status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusConfig.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusConfig.textColor,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.healthy:
        return _StatusConfig(
          label: 'Sağlıklı',
          backgroundColor: const Color(0xFFDCFCE7), // green-100
          textColor: const Color(0xFF166534), // green-800
        );
      case AnalysisStatus.warning:
        return _StatusConfig(
          label: 'Dikkat',
          backgroundColor: const Color(0xFFFEF3C7), // yellow-100
          textColor: const Color(0xFF92400E), // yellow-800
        );
      case AnalysisStatus.disease:
        return _StatusConfig(
          label: 'Hastalık',
          backgroundColor: const Color(0xFFFEE2E2), // red-100
          textColor: const Color(0xFF991B1B), // red-800
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

// Data Models
class AnalysisItem {
  final String id;
  final String plantName;
  final String analysisDate;
  final AnalysisStatus status;
  final String imageUrl;
  final String description;

  AnalysisItem({
    required this.id,
    required this.plantName,
    required this.analysisDate,
    required this.status,
    required this.imageUrl,
    required this.description,
  });

  // TODO: Add API integration when models are resolved
}

enum AnalysisStatus {
  healthy,
  warning,
  disease,
}

// Simplified mock data helper
class _MockDataHelper {
  // This class is simplified to avoid complex API dependencies
  // Real API integration will be added later
}