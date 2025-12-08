import 'package:flutter/material.dart';
import 'dart:io';
import '../../../plant_analysis/presentation/pages/analysis_results_screen.dart';
import '../../../plant_analysis/presentation/screens/analysis_detail_screen.dart';
import '../../../plant_analysis/data/models/analysis_list_response.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'farmer_analysis_card.dart';

class RecentAnalysesGrid extends StatefulWidget {
  const RecentAnalysesGrid({super.key});

  @override
  State<RecentAnalysesGrid> createState() => _RecentAnalysesGridState();
}

class _RecentAnalysesGridState extends State<RecentAnalysesGrid> {
  late Future<List<AnalysisSummary>> _analysesFuture;

  @override
  void initState() {
    super.initState();
    _analysesFuture = _loadAnalyses();
  }

  Future<List<AnalysisSummary>> _loadAnalyses() async {
    try {
      print('🚀🚀🚀 CLAUDE: Starting to load analyses with NEW CODE! 🚀🚀🚀');

      // ✅ CRITICAL FIX: Removed manual token handling!
      // TokenInterceptor in Dio now automatically:
      // 1. Adds Bearer token to every request
      // 2. Refreshes token if expired (before request)
      // 3. Handles 401 errors and retries with new token
      // This fixes "Authentication failed" errors!

      // Get network client
      final networkClient = getIt<NetworkClient>();

      print('🚀 CLAUDE: Making API call to plantanalyses/list (TokenInterceptor handles auth)');
      // Make API call to get analysis list
      final response = await networkClient.get(
        ApiConfig.plantAnalysesList,
        queryParameters: {'page': 1, 'pageSize': 10},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        print('🚀 CLAUDE: Response data type: ${response.data['data'].runtimeType}');
        print('🚀 CLAUDE: Response data content: ${response.data['data']}');

        // Parse using AnalysisListResponse model
        final analysisListResponse = AnalysisListResponse.fromJson(response.data);

        if (analysisListResponse.data != null) {
          final analyses = analysisListResponse.data!.analyses;
          print('🚀 CLAUDE: Found ${analyses.length} analyses from API');

          // Smart sorting: Sort by urgency score (unread messages from sponsor priority)
          analyses.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
          print('🚀 CLAUDE: Analyses sorted by urgency score');

          return analyses;
        }

        print('🚀 CLAUDE: No analyses data, returning empty list');
        return [];
      } else {
        print('🚀 CLAUDE: API call failed or no data, returning empty list');
        return [];
      }
    } catch (e) {
      print('🚀 CLAUDE: ERROR in _loadAnalyses: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AnalysisSummary>>(
      future: _analysesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final analyses = snapshot.data ?? [];

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
            return FarmerAnalysisCard(
              analysis: analysis,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnalysisDetailScreen(
                      analysisId: analysis.id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

}