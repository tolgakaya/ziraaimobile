import 'package:flutter/material.dart';
import '../../data/models/package_statistics.dart';

/// Package statistics tab content
/// Displays detailed package performance metrics
class PackageStatisticsTab extends StatelessWidget {
  final PackageStatistics statistics;

  const PackageStatisticsTab({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildTierBreakdownSection(),
          const SizedBox(height: 16),
          _buildPackageBreakdownSection(),
          const SizedBox(height: 16),
          _buildChannelBreakdownSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
              Icon(Icons.summarize, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'Özet İstatistikler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Dağıtılmayan Kod', statistics.codesNotDistributed.toString()),
          const SizedBox(height: 12),
          _buildSummaryRow('Dağıtılan Ancak Kullanılmayan', statistics.codesDistributedNotRedeemed.toString()),
          const SizedBox(height: 12),
          _buildSummaryRow('Dağıtım Oranı', '${statistics.distributionRate.toStringAsFixed(1)}%'),
          const SizedBox(height: 12),
          _buildSummaryRow('Kullanım Oranı', '${statistics.redemptionRate.toStringAsFixed(1)}%'),
          const SizedBox(height: 12),
          _buildSummaryRow('Genel Başarı Oranı', '${statistics.overallSuccessRate.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildTierBreakdownSection() {
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
              Icon(Icons.layers, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'Paket Seviyesi Analizi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...statistics.tierBreakdowns.map((tier) => _buildTierCard(tier)),
        ],
      ),
    );
  }

  Widget _buildTierCard(TierBreakdown tier) {
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
                'Paket ${tier.tierDisplayName}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tier.codesPurchased} kod',
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
              Expanded(
                child: _buildTierMetric('Dağıtılan', tier.codesDistributed.toString()),
              ),
              Expanded(
                child: _buildTierMetric('Kullanılan', tier.codesRedeemed.toString()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTierMetric('Dağıtım', '${tier.distributionRate.toStringAsFixed(1)}%'),
              ),
              Expanded(
                child: _buildTierMetric('Kullanım', '${tier.redemptionRate.toStringAsFixed(1)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageBreakdownSection() {
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
              Icon(Icons.list_alt, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'Paket Detayları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...statistics.packageBreakdowns.take(5).map((package) => _buildPackageCard(package)),
          if (statistics.packageBreakdowns.length > 5) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '+${statistics.packageBreakdowns.length - 5} daha fazla paket',
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

  Widget _buildPackageCard(PackageBreakdown package) {
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
                'Paket ${package.tierName} #${package.purchaseId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                package.formattedPurchaseDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${package.codesPurchased} kod',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                package.formattedTotalAmount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPackageMetric('Dağıtılan', package.codesDistributed.toString(), Colors.blue),
              const SizedBox(width: 16),
              _buildPackageMetric('Kullanılan', package.codesRedeemed.toString(), Colors.green),
              const SizedBox(width: 16),
              _buildPackageMetric('Dağıtım', '${package.distributionRate.toStringAsFixed(0)}%', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageMetric(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelBreakdownSection() {
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
              Icon(Icons.send, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'Dağıtım Kanalları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...statistics.channelBreakdowns.map((channel) => _buildChannelCard(channel)),
        ],
      ),
    );
  }

  Widget _buildChannelCard(ChannelBreakdown channel) {
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
          Text(
            channel.channel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildChannelMetric('Dağıtılan', channel.codesDistributed.toString()),
              ),
              Expanded(
                child: _buildChannelMetric('Teslim Edilen', channel.codesDelivered.toString()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildChannelMetric('Teslimat', '${channel.deliveryRate.toStringAsFixed(1)}%'),
              ),
              Expanded(
                child: _buildChannelMetric('Kullanım', '${channel.redemptionRate.toStringAsFixed(1)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
