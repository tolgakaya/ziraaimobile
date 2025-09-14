import 'package:flutter/material.dart';
import 'dart:io';

class AnalysisResultsScreen extends StatelessWidget {
  final String analysisId;
  final File? analysisImage;
  final String? imageUrl; // For remote images
  final double confidence;
  final List<DiseaseDetection> diseases;
  final List<TreatmentRecommendation> recommendations;
  final DateTime analysisDate;

  const AnalysisResultsScreen({
    super.key,
    required this.analysisId,
    this.analysisImage,
    this.imageUrl,
    required this.confidence,
    required this.diseases,
    required this.recommendations,
    required this.analysisDate,
  });

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.share, color: Color(0xFF111827)),
            onPressed: () {
              // Share functionality
            },
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
                Container(
                  width: double.infinity,
                  height: 300,
                  color: const Color(0xFF111827),
                  child: analysisImage != null
                      ? Image.file(
                          analysisImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : imageUrl != null
                          ? Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(
                                Icons.image,
                                size: 64,
                                color: Color(0xFF9CA3AF),
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
                      'Confidence: ${confidence.toInt()}%',
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
                      icon: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        // Full screen image view
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
                  // Analysis ID
                  Text(
                    'Analysis ID: $analysisId',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Disease Detection Section
                  const Text(
                    'Disease Detection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Disease List
                  ...diseases.map((disease) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                disease.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Severity: ${disease.severity}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: disease.severity == 'High'
                                      ? const Color(0xFFDC2626)
                                      : disease.severity == 'Medium'
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${disease.confidence.toInt()}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),

                  // Visual Indicators
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Visual Indicators',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            // Show visual indicators detail
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Treatment Recommendations
                  const Text(
                    'Treatment Recommendations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Recommendations List
                  ...recommendations.asMap().entries.map((entry) {
                    int index = entry.key;
                    TreatmentRecommendation recommendation = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
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
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: recommendation.isOrganic
                                      ? const Color(0xFF22C55E).withOpacity(0.1)
                                      : const Color(0xFF3B82F6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  recommendation.isOrganic ? Icons.eco : Icons.science,
                                  color: recommendation.isOrganic
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFF3B82F6),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${index + 1}. ${recommendation.name}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      recommendation.isOrganic ? 'Organic Option' : 'Chemical Option',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: recommendation.isOrganic
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFF3B82F6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (recommendation.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              recommendation.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Models
class DiseaseDetection {
  final String name;
  final String severity;
  final double confidence;

  DiseaseDetection({
    required this.name,
    required this.severity,
    required this.confidence,
  });
}

class TreatmentRecommendation {
  final String name;
  final String description;
  final bool isOrganic;

  TreatmentRecommendation({
    required this.name,
    required this.description,
    required this.isOrganic,
  });
}