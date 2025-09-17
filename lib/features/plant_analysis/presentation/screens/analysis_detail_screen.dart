import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/plant_analysis_result.dart';
import '../blocs/analysis_detail/analysis_detail_bloc.dart';
import '../blocs/analysis_detail/analysis_detail_event.dart';
import '../blocs/analysis_detail/analysis_detail_state.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/disease_card.dart';
import '../widgets/treatment_card.dart';

class AnalysisDetailScreen extends StatelessWidget {
  final String analysisId;
  
  const AnalysisDetailScreen({
    Key? key,
    required this.analysisId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalysisDetailBloc()
        ..add(LoadAnalysisDetail(analysisId: analysisId)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Analiz Detayları'),
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          actions: [
            BlocBuilder<AnalysisDetailBloc, AnalysisDetailState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<AnalysisDetailBloc>().add(
                      RefreshAnalysisDetail(analysisId: analysisId),
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<AnalysisDetailBloc, AnalysisDetailState>(
          builder: (context, state) {
            if (state is AnalysisDetailLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
                ),
              );
            } else if (state is AnalysisDetailLoaded) {
              return _buildDetailContent(context, state.analysisResult);
            } else if (state is AnalysisDetailError) {
              return _buildErrorState(context, state.message);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, PlantAnalysisResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.plantSpecies ?? 'Bilinmeyen Bitki',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              result.status ?? 'Durum bilinmiyor',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ConfidenceBadge(confidence: result.confidence ?? 0.0),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (result.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        result.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (result.healthStatus != null) ...[
                    _buildInfoRow('Sağlık Durumu', result.healthStatus!),
                    const SizedBox(height: 8),
                  ],
                  if (result.growthStage != null) ...[
                    _buildInfoRow('Gelişim Aşaması', result.growthStage!),
                    const SizedBox(height: 8),
                  ],
                  if (result.environmentalConditions != null) ...[
                    _buildInfoRow('Çevresel Koşullar', result.environmentalConditions!),
                  ],
                ],
              ),
            ),
          ),
          
          // Diseases Section
          if (result.diseases != null && result.diseases!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Tespit Edilen Hastalıklar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            ...result.diseases!.map((disease) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DiseaseCard(disease: disease),
            )),
          ],
          
          // Treatments Section
          if (result.treatments != null && result.treatments!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Önerilen Tedaviler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            ...result.treatments!.map((treatment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TreatmentCard(treatment: treatment),
            )),
          ],
          
          // Recommendations Section
          if (result.recommendations != null && result.recommendations!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFFFA726),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Öneriler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...result.recommendations!.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
          
          // Analysis Metadata
          const SizedBox(height: 20),
          Card(
            elevation: 1,
            color: Colors.grey[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analiz ID: ${result.analysisId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (result.createdDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tarih: ${_formatDate(result.createdDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Hata',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<AnalysisDetailBloc>().add(
                  LoadAnalysisDetail(analysisId: analysisId),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}