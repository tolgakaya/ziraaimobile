import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/sponsorship_tier_comparison.dart';
import '../../data/services/sponsor_service.dart';
import '../widgets/tier_card_widget.dart';
import '../widgets/tier_detail_card_widget.dart';
import '../widgets/tier_comparison_table_widget.dart';
import 'quantity_selection_screen.dart';

/// Tier selection screen for sponsor package purchase
/// Displays multiple views: grid, detailed cards, and comparison table
class TierSelectionScreen extends StatefulWidget {
  const TierSelectionScreen({super.key});

  @override
  State<TierSelectionScreen> createState() => _TierSelectionScreenState();
}

class _TierSelectionScreenState extends State<TierSelectionScreen>
    with SingleTickerProviderStateMixin {
  final _sponsorService = GetIt.instance<SponsorService>();

  List<SponsorshipTierComparison>? _tiers;
  SponsorshipTierComparison? _selectedTier;
  bool _isLoading = true;
  String? _errorMessage;

  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadTiers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTiers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tiers = await _sponsorService.getTiersForPurchase();
      setState(() {
        _tiers = tiers;
        _isLoading = false;

        // Auto-select recommended tier (M tier)
        _selectedTier = tiers.firstWhere(
          (t) => t.isRecommended,
          orElse: () => tiers.first,
        );
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectTier(SponsorshipTierComparison tier) {
    setState(() {
      _selectedTier = tier;
    });
  }

  void _continue() {
    if (_selectedTier == null) return;

    // Navigate to quantity selection screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuantitySelectionScreen(
          selectedTier: _selectedTier!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Paket Seçimi',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF10B981),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF10B981),
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.grid_view, size: 20),
                    text: 'Hızlı',
                  ),
                  Tab(
                    icon: Icon(Icons.view_agenda, size: 20),
                    text: 'Detaylı',
                  ),
                  Tab(
                    icon: Icon(Icons.compare, size: 20),
                    text: 'Karşılaştır',
                  ),
                ],
              ),
              Container(
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              'Paketler Yüklenemedi',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTiers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_tiers == null || _tiers!.isEmpty) {
      return const Center(
        child: Text('Henüz paket bulunmamaktadır.'),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Grid View (Quick)
        _buildGridView(),
        // Detailed Card View
        _buildDetailView(),
        // Comparison Table View
        _buildComparisonView(),
      ],
    );
  }

  Widget _buildGridView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Size En Uygun Paketi Seçin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Paketler, çiftçilere sağladığınız ayrıcalıkları belirler',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // 2x2 Grid Layout matching sponsor_packages.png
          _buildTierGrid(),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detaylı Paket Bilgileri',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Her paketin sunduğu tüm özellikler',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // Detailed Cards
          ..._tiers!.map((tier) {
            final isSelected = _selectedTier?.id == tier.id;
            return TierDetailCardWidget(
              tier: tier,
              isSelected: isSelected,
              onTap: () => _selectTier(tier),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildComparisonView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paket Karşılaştırması',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tüm paketleri yan yana karşılaştırın',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // Comparison Table
          TierComparisonTableWidget(
            tiers: _tiers!,
            selectedTier: _selectedTier,
            onTierSelected: _selectTier,
          ),

          const SizedBox(height: 16),

          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İpucu:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Mevcut özellik',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Mevcut değil',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columns for 2x2 grid
        childAspectRatio: 0.75, // Card aspect ratio
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _tiers!.length,
      itemBuilder: (context, index) {
        final tier = _tiers![index];
        final isSelected = _selectedTier?.id == tier.id;

        return TierCardWidget(
          tier: tier,
          isSelected: isSelected,
          onTap: () => _selectTier(tier),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final hasSelection = _selectedTier != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasSelection) ...[
              Text(
                '${_selectedTier!.displayName} - ${_selectedTier!.monthlyPrice.toStringAsFixed(0)} ${_selectedTier!.currency}/ay',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: hasSelection ? _continue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSelection
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE5E7EB),
                foregroundColor: hasSelection
                    ? Colors.white
                    : const Color(0xFF9CA3AF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Devam Et',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
