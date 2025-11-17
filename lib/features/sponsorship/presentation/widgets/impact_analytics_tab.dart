import 'package:flutter/material.dart';
import '../../data/models/impact_analytics.dart';

/// Impact analytics tab content
/// Displays farmer reach and crop analysis metrics
class ImpactAnalyticsTab extends StatelessWidget {
  final ImpactAnalytics analytics;

  const ImpactAnalyticsTab({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeCard(),
          const SizedBox(height: 16),
          _buildFarmerMetricsCard(),
          const SizedBox(height: 16),
          _buildCropMetricsCard(),
          const SizedBox(height: 16),
          _buildTopCitiesSection(),
          const SizedBox(height: 16),
          _buildTopCropsSection(),
          const SizedBox(height: 16),
          _buildTopDiseasesSection(),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 8),
          Text(
            'Veri Aralığı: ${analytics.formattedDateRange}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerMetricsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.people, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'Çiftçi Erişimi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Toplam Erişilen',
                  analytics.totalFarmersReached.toString(),
                  Icons.accessibility_new,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Son 30 Gün Aktif',
                  analytics.activeFarmersLast30Days.toString(),
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Elde Tutma Oranı',
                  '${analytics.farmerRetentionRate.toStringAsFixed(1)}%',
                  Icons.loyalty,
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Ort. Yaşam Süresi',
                  '${analytics.averageFarmerLifetimeDays.toStringAsFixed(1)} gün',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropMetricsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.eco, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'Ürün Analizi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Toplam Analiz',
                  analytics.totalCropsAnalyzed.toString(),
                  Icons.analytics,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Ürün Türü',
                  analytics.uniqueCropTypes.toString(),
                  Icons.category,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Tespit Edilen Hastalık',
                  analytics.diseasesDetected.toString(),
                  Icons.bug_report,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Çözülen Kritik Sorun',
                  analytics.criticalIssuesResolved.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Ulaşılan Şehir',
                  analytics.citiesReached.toString(),
                  Icons.location_city,
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Ulaşılan İlçe',
                  analytics.districtsReached.toString(),
                  Icons.map,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCitiesSection() {
    if (analytics.topCities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'En Çok Erişilen Şehirler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analytics.topCities.map((city) => _buildCityCard(city)),
        ],
      ),
    );
  }

  Widget _buildCityCard(TopCity city) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                city.cityName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '%${city.percentage.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${city.farmerCount} çiftçi',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.analytics, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${city.analysisCount} analiz',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          if (city.mostCommonCrop.isNotEmpty && city.mostCommonCrop != 'Unknown') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.eco, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'En Yaygın Ürün: ${city.mostCommonCrop}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopCropsSection() {
    if (analytics.topCrops.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.agriculture, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'En Çok Analiz Edilen Ürünler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analytics.topCrops.map((crop) => _buildCropCard(crop)),
        ],
      ),
    );
  }

  Widget _buildCropCard(TopCrop crop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop.cropType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.analytics, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${crop.analysisCount} analiz',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${crop.uniqueFarmers} çiftçi',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '%${crop.percentage.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDiseasesSection() {
    if (analytics.topDiseases.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show only top 5 diseases
    final displayDiseases = analytics.topDiseases.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.healing, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'En Yaygın Hastalıklar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayDiseases.map((disease) => _buildDiseaseCard(disease)),
          if (analytics.topDiseases.length > 5) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '+${analytics.topDiseases.length - 5} daha fazla hastalık',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(TopDisease disease) {
    Color categoryColor = _getCategoryColor(disease.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  disease.diseaseName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: categoryColor.withOpacity(0.3)),
                ),
                child: Text(
                  disease.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.bar_chart, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${disease.occurrenceCount} tespit',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '%${disease.percentage.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          if (disease.affectedCrops.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.eco, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Etkilenen: ${disease.affectedCrops.join(", ")}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'kritik':
      case 'critical':
        return Colors.red;
      case 'yüksek':
      case 'high':
        return Colors.orange;
      case 'orta':
      case 'moderate':
      case 'medium':
        return Colors.amber;
      case 'düşük':
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
