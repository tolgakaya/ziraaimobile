import 'package:flutter/material.dart';
import '../../../data/models/plant_analysis_detail_dto.dart';

class PestDiseaseCard extends StatelessWidget {
  final PestDiseaseDto pestDisease;

  const PestDiseaseCard({
    Key? key,
    required this.pestDisease,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bug_report,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Zararlı & Hastalık Analizi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111811),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Affected Area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getSpreadRiskColor(pestDisease.spreadRisk).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getSpreadRiskColor(pestDisease.spreadRisk).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.area_chart,
                    color: _getSpreadRiskColor(pestDisease.spreadRisk),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Etkilenen Alan: %${pestDisease.affectedAreaPercentage}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getSpreadRiskColor(pestDisease.spreadRisk),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSpreadRiskColor(pestDisease.spreadRisk),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Yayılım: ${pestDisease.spreadRisk}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Primary Issue
            if (pestDisease.primaryIssue != null && pestDisease.primaryIssue!.isNotEmpty) ...[
              _buildSectionHeader('Ana Sorun'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  pestDisease.primaryIssue!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Diseases
            if (pestDisease.diseasesDetected.isNotEmpty) ...[
              _buildSectionHeader('Tespit Edilen Hastalıklar (${pestDisease.diseasesDetected.length})'),
              const SizedBox(height: 8),
              ...pestDisease.diseasesDetected.map((disease) => _buildDiseaseItem(disease)),
              const SizedBox(height: 16),
            ],
            
            // Pests
            if (pestDisease.pestsDetected.isNotEmpty) ...[
              _buildSectionHeader('Tespit Edilen Zararlılar (${pestDisease.pestsDetected.length})'),
              const SizedBox(height: 8),
              ...pestDisease.pestsDetected.map((pest) => _buildPestItem(pest)),
              const SizedBox(height: 16),
            ],
            
            // Damage Pattern
            if (pestDisease.damagePattern.isNotEmpty) ...[
              _buildSectionHeader('Hasar Deseni'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  pestDisease.damagePattern,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111811),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildDiseaseItem(DiseaseDto disease) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.coronavirus,
                color: _getSeverityColor(disease.severity),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  disease.type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111811),
                  ),
                ),
              ),
              _buildConfidenceBadge(disease.confidence),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChip(disease.category, Colors.blue),
              const SizedBox(width: 8),
              _buildChip(disease.severity, _getSeverityColor(disease.severity)),
            ],
          ),
          if (disease.affectedParts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: disease.affectedParts.map((part) {
                return Chip(
                  label: Text(part, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.orange.shade50,
                  side: BorderSide(color: Colors.orange.shade200),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPestItem(PestDto pest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                color: _getSeverityColor(pest.severity),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pest.type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111811),
                  ),
                ),
              ),
              _buildConfidenceBadge(pest.confidence),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChip(pest.category, Colors.green),
              const SizedBox(width: 8),
              _buildChip(pest.severity, _getSeverityColor(pest.severity)),
            ],
          ),
          if (pest.affectedParts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: pest.affectedParts.map((part) {
                return Chip(
                  label: Text(part, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.orange.shade50,
                  side: BorderSide(color: Colors.orange.shade200),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    Color color = _getConfidenceColor(confidence);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '%${confidence.toInt()}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'yüksek':
      case 'kritik':
        return Colors.red;
      case 'orta':
        return Colors.orange;
      case 'düşük':
      case 'hafif':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getSpreadRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'yüksek':
      case 'hızlı':
        return Colors.red;
      case 'orta':
        return Colors.orange;
      case 'düşük':
      case 'yavaş':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }
}