import 'package:flutter/material.dart';
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: BlocBuilder<AnalysisDetailBloc, AnalysisDetailState>(
          builder: (context, state) {
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
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF111811)),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                detail.cropType ?? 'Analiz Detayı',
                style: const TextStyle(
                  color: Color(0xFF111811),
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF17CF17),
                      Color(0xFF15B815),
                    ],
                  ),
                ),
                child: _buildHeroSection(detail),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Plant Identification Card
                if (detail.plantIdentification != null)
                  _buildPlantIdentificationCard(detail.plantIdentification!),

                const SizedBox(height: 16),

                // Health Assessment Card
                if (detail.healthAssessment != null)
                  _buildHealthAssessmentCard(detail.healthAssessment!),

                const SizedBox(height: 16),

                // Diseases Section
                if (detail.diseases != null && detail.diseases!.isNotEmpty)
                  _buildDiseasesSection(detail.diseases!),

                const SizedBox(height: 16),

                // Treatments Section
                if (detail.treatments != null && detail.treatments!.isNotEmpty)
                  _buildTreatmentsSection(detail.treatments!),

                const SizedBox(height: 16),

                // Analysis Info Card
                _buildAnalysisInfoCard(detail),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(PlantAnalysisResult detail) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.plantIdentification?.confidence != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${detail.plantIdentification!.confidence!.toInt()}% Güven',
                style: const TextStyle(
                  color: Color(0xFF111811),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlantIdentificationCard(detail) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bitki Tanımlaması',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111811),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Tür', detail.species ?? 'Bilinmiyor'),
            _buildInfoRow('Çeşit', detail.variety ?? 'Bilinmiyor'),
            _buildInfoRow('Büyüme Evresi', detail.growthStage ?? 'Bilinmiyor'),
            _buildInfoRow('Güven Oranı', '${detail.confidence?.toInt() ?? 0}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthAssessmentCard(detail) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sağlık Değerlendirmesi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111811),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Canlılık Skoru', '${detail.vigorScore ?? 0}/10'),
            _buildInfoRow('Yaprak Rengi', detail.leafColor ?? 'Bilinmiyor'),
            _buildInfoRow('Yaprak Dokusu', detail.leafTexture ?? 'Bilinmiyor'),
            _buildInfoRow('Büyüme Düzeni', detail.growthPattern ?? 'Bilinmiyor'),
            _buildInfoRow('Şiddet', detail.severity ?? 'Bilinmiyor'),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseasesSection(List diseases) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tespit Edilen Hastalıklar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111811),
              ),
            ),
            const SizedBox(height: 12),
            ...diseases.map((disease) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease.name ?? 'Bilinmeyen Hastalık',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (disease.severity != null)
                      Text('Şiddet: ${disease.severity}'),
                    if (disease.description != null)
                      Text(disease.description!),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentsSection(List treatments) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Önerilen Tedaviler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111811),
              ),
            ),
            const SizedBox(height: 12),
            ...treatments.map((treatment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treatment.name ?? 'Bilinmeyen Tedavi',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (treatment.type != null)
                      Text('Tür: ${treatment.type}'),
                    if (treatment.description != null)
                      Text(treatment.description!),
                    if (treatment.priority != null)
                      Text('Öncelik: ${treatment.priority}'),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisInfoCard(PlantAnalysisResult detail) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analiz Bilgileri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111811),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Analiz ID', detail.analysisId ?? 'Bilinmiyor'),
            _buildInfoRow('Durum', detail.analysisStatus ?? 'Bilinmiyor'),
            _buildInfoRow('Konum', detail.location ?? 'Belirtilmemiş'),
            if (detail.analysisDate != null)
              _buildInfoRow('Tarih', _formatDate(detail.analysisDate!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111811),
              ),
            ),
          ),
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
            Text(
              'Analiz detayları yüklenemedi',
              style: const TextStyle(
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
}