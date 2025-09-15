import 'package:flutter/material.dart';
import '../../models/usage_status.dart';
import '../../services/mock_subscription_service.dart';

/// Enhanced 403 error screen with smart usage status display
class SubscriptionStatusScreen extends StatefulWidget {
  final String scenario;
  final VoidCallback? onBack;

  const SubscriptionStatusScreen({
    super.key,
    this.scenario = 'daily_exceeded',
    this.onBack,
  });

  @override
  State<SubscriptionStatusScreen> createState() => _SubscriptionStatusScreenState();
}

class _SubscriptionStatusScreenState extends State<SubscriptionStatusScreen> {
  late UsageStatus usageStatus;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsageStatus();
  }

  void _loadUsageStatus() {
    usageStatus = MockSubscriptionService.getMockUsageStatus(scenario: widget.scenario);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Abonelik Durumu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
            if (usageStatus.hasActiveSubscription) _buildUsageDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(),
              size: 64,
              color: _getStatusColor(),
            ),
            const SizedBox(height: 16),
            Text(
              _getStatusTitle(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              usageStatus.getStatusMessage(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final actions = usageStatus.getAvailableActions();

    return Column(
      children: actions.map((action) => _buildActionButton(action)).toList(),
    );
  }

  Widget _buildActionButton(String action) {
    Widget button;

    switch (action) {
      case 'subscribe':
        button = _buildPrimaryButton(
          'Abonelik Satın Al',
          Icons.shopping_cart,
          () => _showUpgradeOptions(),
          Colors.green,
        );
        break;
      case 'upgrade':
        button = _buildPrimaryButton(
          'Abonelik Yükselt',
          Icons.upgrade,
          () => _showUpgradeOptions(),
          Colors.orange,
        );
        break;
      case 'sponsor_code':
        button = _buildSecondaryButton(
          'Sponsor Kodu Gir',
          Icons.card_giftcard,
          () => _showSponsorCodeDialog(),
        );
        break;
      case 'wait_tomorrow':
        button = _buildInfoButton(
          'Yarın Tekrar Dene (${MockSubscriptionService.getTimeUntilDailyReset()})',
          Icons.schedule,
        );
        break;
      default:
        button = const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: button,
    );
  }

  Widget _buildPrimaryButton(String text, IconData icon, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildInfoButton(String text, IconData icon) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 16, color: Colors.blue[700])),
        ],
      ),
    );
  }

  Widget _buildUsageDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kullanım Detayları',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildUsageRow('Günlük Limit', '${usageStatus.dailyUsed}/${usageStatus.dailyLimit}',
                           usageStatus.dailyUsed / usageStatus.dailyLimit),
            const SizedBox(height: 12),
            _buildUsageRow('Aylık Limit', '${usageStatus.monthlyUsed}/${usageStatus.monthlyLimit}',
                           usageStatus.monthlyUsed / usageStatus.monthlyLimit),
            const SizedBox(height: 16),
            _buildInfoRow('Paket', usageStatus.subscriptionTier),
            _buildInfoRow('Yenileme', usageStatus.nextRenewalDate),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.red : (progress >= 0.8 ? Colors.orange : Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    if (!usageStatus.hasActiveSubscription) return Icons.lock;
    if (usageStatus.isDailyQuotaExceeded) return Icons.schedule;
    if (usageStatus.isMonthlyQuotaExceeded) return Icons.warning;
    return Icons.check_circle;
  }

  Color _getStatusColor() {
    if (!usageStatus.hasActiveSubscription) return Colors.grey;
    if (usageStatus.isQuotaExceeded) return Colors.red;
    return Colors.green;
  }

  String _getStatusTitle() {
    if (!usageStatus.hasActiveSubscription) return 'Abonelik Gerekli';
    if (usageStatus.isDailyQuotaExceeded) return 'Günlük Limit Doldu';
    if (usageStatus.isMonthlyQuotaExceeded) return 'Aylık Limit Doldu';
    return 'Aktif Abonelik';
  }

  void _showUpgradeOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UpgradeOptionsSheet(),
    );
  }

  void _showSponsorCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => _SponsorCodeDialog(),
    );
  }
}

/// Upgrade options bottom sheet
class _UpgradeOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiers = MockSubscriptionService.getMockSubscriptionTiers();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Abonelik Paketleri',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: tiers.length,
              itemBuilder: (context, index) => _buildTierCard(context, tiers[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(BuildContext context, SubscriptionTier tier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tier.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₺${tier.monthlyPrice}/ay',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(tier.description),
            const SizedBox(height: 12),
            ...tier.features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(feature),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _selectTier(context, tier),
                child: const Text('Bu Paketi Seç'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTier(BuildContext context, SubscriptionTier tier) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tier.displayName} paketi seçildi (Mock)')),
    );
  }
}

/// Sponsor code input dialog
class _SponsorCodeDialog extends StatefulWidget {
  @override
  State<_SponsorCodeDialog> createState() => _SponsorCodeDialogState();
}

class _SponsorCodeDialogState extends State<_SponsorCodeDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sponsor Kodu Gir'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Sponsor kodunuzu girerek ücretsiz analiz hakkı kazanabilirsiniz.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Sponsor Kodu',
              hintText: 'Örn: DEMO2025',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _redeemCode,
          child: _isLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Kullan'),
        ),
      ],
    );
  }

  void _redeemCode() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final success = await MockSubscriptionService.redeemSponsorCode(code);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
              ? 'Sponsor kodu başarıyla kullanıldı! 🎉'
              : 'Geçersiz sponsor kodu ❌'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}