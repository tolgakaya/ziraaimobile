import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../../models/usage_status.dart';
import '../../models/subscription_tier.dart';
import '../../services/subscription_service.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../../core/error/subscription_exceptions.dart';
import 'sponsor_request_screen.dart';
import 'payment_screen.dart';

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

  String _getTimeUntilDailyReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntil = tomorrow.difference(now);
    final hours = timeUntil.inHours;
    final minutes = timeUntil.inMinutes % 60;
    return '${hours}sa ${minutes}dk';
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
        // Show null instead of mock data
        usageStatus = null;
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
      children: [
        // Existing action buttons
        ...actions.map((action) => _buildActionButton(action)).toList(),
        
        // Always show sponsorship request button
        const SizedBox(height: 8),
        _buildSponsorshipRequestButton(),
      ],
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
          'Yarın Tekrar Dene (${_getTimeUntilDailyReset()})',
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

  Widget _buildSponsorshipRequestButton() {
    return _buildSecondaryButton(
      'Sponsorluk İsteği Gönder',
      Icons.handshake,
      () => _navigateToSponsorshipRequest(),
    );
  }

  void _navigateToSponsorshipRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SponsorRequestScreen(),
      ),
    );
  }

  void _showSponsorCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => _SponsorCodeDialog(subscriptionService: _subscriptionService),
    );
  }
}

/// Upgrade options bottom sheet with enhanced sponsor options
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
      // Filter out Trial tier as it's not purchasable
      final purchasableTiers = loadedTiers.where((tier) =>
        tier.name.toLowerCase() != 'trial'
      ).toList();
      setState(() {
        tiers = purchasableTiers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        // Enhanced error handling with specific messages
        if (e is SubscriptionTierException) {
          errorMessage = 'Paketler yüklenemedi: ${e.message}';
        } else {
          errorMessage = 'Paketler yüklenemedi: ${e.toString()}';
        }
        // No fallback to mock data - show error instead
        tiers = [];
      });
      print('Error loading subscription tiers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.upgrade, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Planını Yükselt',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Abonelik paketleri yükleniyor...'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Current Plan Card
                        _buildCurrentPlanCard(),
                        const SizedBox(height: 24),
                        
                        // Sponsor Options Section
                        _buildSponsorOptionsSection(),
                        const SizedBox(height: 24),
                        
                        // Divider with "veya"
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'veya',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Purchase Section
                        _buildPurchaseSection(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCurrentPlanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              const Text(
                'Mevcut Planınız',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Temel',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '15/50 günlük analiz kullanıldı • 15 gün kaldı',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSponsorOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Text(
              'Ücretsiz Seçenekler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Sponsor Code Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.confirmation_number, color: Colors.green.shade600),
            ),
            title: const Text(
              'Sponsor Kodu Var mı?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Sponsor kodunuz varsa hemen kullanın',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            onTap: () {
              Navigator.pop(context);
              _showSponsorCodeDialog();
            },
          ),
        ),
        const SizedBox(height: 8),
        
        // Sponsorship Request Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.handshake, color: Colors.blue.shade600),
            ),
            title: const Text(
              'Sponsorluk İsteği Gönder',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Tarım firmalarından sponsorluk talep edin',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            onTap: _navigateToSponsorRequest,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPurchaseSection() {
    if (tiers == null || tiers!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Abonelik paketleri yüklenemedi',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTiers,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payment, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(
              'Satın Alma Seçenekleri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Tier List
        ...tiers!.map((tier) => _buildTierCard(tier)).toList(),
      ],
    );
  }
  
  Widget _buildTierCard(SubscriptionTier tier) {
    final isRecommended = tier.name == 'Premium';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isRecommended ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isRecommended 
              ? BorderSide(color: Colors.orange.shade300, width: 2)
              : BorderSide.none,
        ),
        child: Stack(
          children: [
            if (isRecommended)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ÖNERİLEN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Text(
                    tier.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${tier.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const Text(
                        '/ ay',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    '${tier.dailyAnalysisLimit} günlük • ${tier.monthlyAnalysisLimit} aylık analiz',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (tier.features.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...tier.features.take(2).map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 14, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _navigateToPayment(tier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRecommended 
                            ? Colors.orange.shade600 
                            : Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Satın Al',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSponsorCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => _SponsorCodeDialog(subscriptionService: widget.subscriptionService),
    );
  }
  
  void _navigateToSponsorRequest() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SponsorRequestScreen(),
      ),
    );
  }
  
  void _navigateToPayment(SubscriptionTier tier) async {
    Navigator.pop(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(selectedTier: tier),
      ),
    );

    // If payment was successful, navigate to dashboard and refresh data
    if (result == true) {
      // Navigate to dashboard (go back to root)
      Navigator.of(context).popUntil((route) => route.isFirst);
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
        String errorMessage = 'Sponsor kodu kullanılamadı';
        
        // Enhanced error handling with specific messages
        if (e is SponsorshipRedeemException) {
          switch (e.errorCode) {
            case 'INVALID_CODE':
              errorMessage = 'Geçersiz sponsor kodu';
              break;
            case 'ALREADY_USED':
              errorMessage = 'Bu kod daha önce kullanılmış';
              break;
            case 'EXPIRED':
              errorMessage = 'Kodun süresi dolmuş';
              break;
            default:
              errorMessage = e.message;
          }
        } else {
          errorMessage = 'Bağlantı hatası oluştu';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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