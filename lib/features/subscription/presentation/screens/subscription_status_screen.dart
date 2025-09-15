import 'package:flutter/material.dart';
import '../../models/usage_status.dart';
import '../../services/mock_subscription_service.dart';
import '../../services/subscription_service.dart';
import '../../../../core/utils/minimal_service_locator.dart';

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
  late final SubscriptionService _subscriptionService;
  UsageStatus? usageStatus;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _subscriptionService = getIt<SubscriptionService>();
    _loadUsageStatus();
  }

  Future<void> _loadUsageStatus() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final status = await _subscriptionService.getUsageStatus();
      setState(() {
        usageStatus = status;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanım durumu yüklenemedi: ${e.toString()}';
        isLoading = false;
        // Fallback to mock data based on scenario for demo purposes
        usageStatus = MockSubscriptionService.getMockUsageStatus(scenario: widget.scenario);
      });
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsageStatus,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Abonelik durumu yükleniyor...'),
                ],
              ),
            )
          : usageStatus == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage ?? 'Abonelik durumu yüklenemedi',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsageStatus,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'API\'den veri alınamadı, demo verisi gösteriliyor',
                                  style: TextStyle(color: Colors.orange[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                      if (usageStatus!.hasActiveSubscription) _buildUsageDetails(),
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
              usageStatus?.getStatusMessage() ?? 'Durum bilgisi yükleniyor...',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (usageStatus == null) {
      return const SizedBox.shrink();
    }

    final actions = usageStatus!.getAvailableActions();

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
            _buildUsageRow('Günlük Limit', '${usageStatus!.dailyUsed}/${usageStatus!.dailyLimit}',
                           usageStatus!.dailyUsed / usageStatus!.dailyLimit),
            const SizedBox(height: 12),
            _buildUsageRow('Aylık Limit', '${usageStatus!.monthlyUsed}/${usageStatus!.monthlyLimit}',
                           usageStatus!.monthlyUsed / usageStatus!.monthlyLimit),
            const SizedBox(height: 16),
            _buildInfoRow('Paket', usageStatus!.subscriptionTier),
            _buildInfoRow('Yenileme', usageStatus!.nextRenewalDate),
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
    if (usageStatus == null) return Icons.info;
    if (!usageStatus!.hasActiveSubscription) return Icons.lock;
    if (usageStatus!.isDailyQuotaExceeded) return Icons.schedule;
    if (usageStatus!.isMonthlyQuotaExceeded) return Icons.warning;
    return Icons.check_circle;
  }

  Color _getStatusColor() {
    if (usageStatus == null) return Colors.grey;
    if (!usageStatus!.hasActiveSubscription) return Colors.grey;
    if (usageStatus!.isQuotaExceeded) return Colors.red;
    return Colors.green;
  }

  String _getStatusTitle() {
    if (usageStatus == null) return 'Durum Yükleniyor';
    if (!usageStatus!.hasActiveSubscription) return 'Abonelik Gerekli';
    if (usageStatus!.isDailyQuotaExceeded) return 'Günlük Limit Doldu';
    if (usageStatus!.isMonthlyQuotaExceeded) return 'Aylık Limit Doldu';
    return 'Aktif Abonelik';
  }

  void _showUpgradeOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UpgradeOptionsSheet(subscriptionService: _subscriptionService),
    );
  }

  void _showSponsorCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => _SponsorCodeDialog(subscriptionService: _subscriptionService),
    );
  }
}

/// Upgrade options bottom sheet
class _UpgradeOptionsSheet extends StatefulWidget {
  final SubscriptionService subscriptionService;

  const _UpgradeOptionsSheet({required this.subscriptionService});

  @override
  State<_UpgradeOptionsSheet> createState() => _UpgradeOptionsSheetState();
}

class _UpgradeOptionsSheetState extends State<_UpgradeOptionsSheet> {
  List<SubscriptionTier>? tiers;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedTiers = await widget.subscriptionService.getSubscriptionTiers();
      setState(() {
        tiers = loadedTiers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Paketler yüklenemedi: ${e.toString()}';
        isLoading = false;
        // Fallback to mock data
        tiers = MockSubscriptionService.getMockSubscriptionTiers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Abonelik paketleri yükleniyor...'),
            ],
          ),
        ),
      );
    }

    if (tiers == null || tiers!.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Paketler yüklenemedi',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTiers,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

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
          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API\'den veri alınamadı, demo paketleri gösteriliyor',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: tiers!.length,
              itemBuilder: (context, index) => _buildTierCard(context, tiers![index]),
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

  Future<void> _selectTier(BuildContext context, SubscriptionTier tier) async {
    Navigator.pop(context);

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
              const SizedBox(width: 12),
              Text('${tier.displayName} paketi satın alınıyor...'),
            ],
          ),
          duration: const Duration(seconds: 10),
        ),
      );

      final success = await widget.subscriptionService.subscribeTo(tier.id);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
              ? '${tier.displayName} paketi başarıyla satın alındı! 🎉'
              : '${tier.displayName} paketi satın alınamadı. Lütfen tekrar deneyin.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Satın alma işlemi başarısız: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Sponsor code input dialog
class _SponsorCodeDialog extends StatefulWidget {
  final SubscriptionService subscriptionService;

  const _SponsorCodeDialog({required this.subscriptionService});

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

  Future<void> _redeemCode() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.subscriptionService.redeemSponsorCode(code);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
              ? 'Sponsor kodu başarıyla kullanıldı! 🎉'
              : 'Geçersiz sponsor kodu veya hata oluştu ❌'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sponsor kodu kullanılamadı: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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