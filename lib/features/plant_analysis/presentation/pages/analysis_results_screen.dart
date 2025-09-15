import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../data/repositories/plant_analysis_repository.dart';
import 'package:share_plus/share_plus.dart';

class AnalysisResultsScreen extends StatefulWidget {
  final PlantAnalysisResult analysisResult;
  final File originalImage;

  const AnalysisResultsScreen({
    super.key,
    required this.analysisResult,
    required this.originalImage,
  });

  @override
  State<AnalysisResultsScreen> createState() => _AnalysisResultsScreenState();
}

class _AnalysisResultsScreenState extends State<AnalysisResultsScreen> {
  bool _showFullImage = false;

  void _shareResults() async {
    final analysisText = '''
Bitki Analizi Sonucu
══════════════════
📊 Güven: ${widget.analysisResult.confidence.toStringAsFixed(1)}%
🏥 Tespit Edilen Sorunlar: ${widget.analysisResult.diseases.length}
💊 Tedavi Önerileri: ${widget.analysisResult.treatments.length}

📋 Detaylar:
${widget.analysisResult.diseases.map((d) => '• ${d.name} (${d.severity})').join('\n')}

🌱 ZiraAI ile analiz edildi
''';

    try {
      await Share.share(analysisText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşım başarısız oldu')),
        );
      }
    }
  }

  void _copyAnalysisId() {
    Clipboard.setData(ClipboardData(text: widget.analysisResult.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analiz ID kopyalandı'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDateTime(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.analysisResult;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Analysis Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy, color: Color(0xFF111827)),
            onPressed: _copyAnalysisId,
            tooltip: 'Analiz ID\'sini Kopyala',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF111827)),
            onPressed: _shareResults,
            tooltip: 'Sonuçları Paylaş',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analysis Image with Confidence
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFullImage = !_showFullImage;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    color: const Color(0xFF111827),
                    child: Image.file(
                      widget.originalImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                // Confidence badge
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Güven: ${result.confidence.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Expand button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _showFullImage ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _showFullImage = !_showFullImage;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analysis metadata
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(result.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'ID: ${result.id.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Disease Detection Section
                  if (result.diseases.isNotEmpty) ...[
                    const Text(
                      'Hastalık Tespiti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...result.diseases.map((disease) => _buildDiseaseCard(disease)),
                    const SizedBox(height: 24),
                  ],

                  // Treatment Recommendations Section
                  if (result.treatments.isNotEmpty) ...[
                    const Text(
                      'Tedavi Önerileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Organic treatments
                    if (result.organicTreatments.isNotEmpty) ...[
                      const Text(
                        '🌿 Organik Seçenekler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...result.organicTreatments.map((treatment) => _buildTreatmentCard(treatment)),
                      const SizedBox(height: 16),
                    ],

                    // Chemical treatments
                    if (result.chemicalTreatments.isNotEmpty) ...[
                      const Text(
                        '🧪 Kimyasal Seçenekler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...result.chemicalTreatments.map((treatment) => _buildTreatmentCard(treatment)),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // Visual Indicators (if available)
                  if (result.visualIndicators?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Görsel Göstergeler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...result.visualIndicators!.map((indicator) => _buildVisualIndicatorCard(indicator)),
                  ],

                  // Analysis Metadata (if available)
                  if (result.metadata != null) ...[
                    const SizedBox(height: 24),
                    _buildMetadataCard(result.metadata!),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseCard(PlantDisease disease) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(int.parse('0xFF${disease.severityColor.substring(1)}')),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  disease.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${disease.severityColor.substring(1)}')),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  disease.severity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Güven: ${disease.confidence.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (disease.description != null) ...[
            const SizedBox(height: 8),
            Text(
              disease.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(PlantTreatment treatment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                treatment.treatmentIcon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  treatment.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: treatment.isOrganic
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: treatment.isOrganic
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF3B82F6),
                  ),
                ),
                child: Text(
                  treatment.type,
                  style: TextStyle(
                    color: treatment.isOrganic
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF3B82F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            treatment.instructions,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          if (treatment.frequency != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Sıklık: ${treatment.frequency}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisualIndicatorCard(VisualIndicator indicator) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${indicator.type} - ${indicator.location}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                if (indicator.details != null)
                  Text(
                    indicator.details!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${indicator.confidence.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(AnalysisMetadata metadata) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analiz Bilgileri',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          if (metadata.cropType != null)
            _buildMetadataRow('Bitki Türü', metadata.cropType!),
          if (metadata.location != null)
            _buildMetadataRow('Konum', metadata.location!),
          if (metadata.notes != null)
            _buildMetadataRow('Notlar', metadata.notes!),
          if (metadata.processingTime != null)
            _buildMetadataRow('İşlem Süresi', '${metadata.processingTime!.toStringAsFixed(1)}s'),
          if (metadata.modelVersion != null)
            _buildMetadataRow('Model Versiyonu', metadata.modelVersion!),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}