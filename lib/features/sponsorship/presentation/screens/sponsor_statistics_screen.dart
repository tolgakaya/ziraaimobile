import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/sponsor_statistics.dart';
import '../../data/models/package_statistics.dart';
import '../../data/models/impact_analytics.dart';
import '../../data/services/sponsor_service.dart';
import '../widgets/statistics_overview_card.dart';
import '../widgets/package_statistics_tab.dart';
import '../widgets/impact_analytics_tab.dart';

/// Sponsor statistics screen with comprehensive analytics
/// Shows overview metrics and detailed tabs for package and impact analytics
class SponsorStatisticsScreen extends StatefulWidget {
  const SponsorStatisticsScreen({super.key});

  @override
  State<SponsorStatisticsScreen> createState() => _SponsorStatisticsScreenState();
}

class _SponsorStatisticsScreenState extends State<SponsorStatisticsScreen>
    with SingleTickerProviderStateMixin {
  final SponsorService _sponsorService = GetIt.instance<SponsorService>();

  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  SponsorStatistics? _statistics;
  PackageStatistics? _packageStatistics;
  ImpactAnalytics? _impactAnalytics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all statistics in parallel for better performance
      final results = await Future.wait([
        _sponsorService.getStatistics(),
        _sponsorService.getPackageStatistics(),
        _sponsorService.getImpactAnalytics(),
      ]);

      setState(() {
        _statistics = results[0] as SponsorStatistics;
        _packageStatistics = results[1] as PackageStatistics;
        _impactAnalytics = results[2] as ImpactAnalytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Analitik & Raporlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAllStatistics,
                icon: const Icon(Icons.refresh),
                label: const Text('Yeniden Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_statistics == null || _packageStatistics == null || _impactAnalytics == null) {
      return const Center(
        child: Text('İstatistik verileri bulunamadı'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllStatistics,
      child: Column(
        children: [
          // Overview metrics section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detaylı istatistikler ve performans analizi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                _buildOverviewMetrics(),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF16A34A),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF16A34A),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Paket Performansı'),
                Tab(text: 'Etki Analizi'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PackageStatisticsTab(
                  statistics: _packageStatistics!,
                ),
                ImpactAnalyticsTab(
                  analytics: _impactAnalytics!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetrics() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatisticsOverviewCard(
          title: 'TOPLAM SATIN ALINAN',
          value: _statistics!.totalCodesPurchased.toString(),
          icon: Icons.shopping_cart,
          color: const Color(0xFF3B82F6),
        ),
        StatisticsOverviewCard(
          title: 'KULLANILAN KOD',
          value: _statistics!.totalCodesUsed.toString(),
          icon: Icons.check_circle,
          color: const Color(0xFF10B981),
        ),
        StatisticsOverviewCard(
          title: 'KULLANILMAYAN KOD',
          value: _statistics!.unusedCodes.toString(),
          icon: Icons.pending,
          color: const Color(0xFFF59E0B),
        ),
        StatisticsOverviewCard(
          title: 'KULLANIM ORANI',
          value: _statistics!.formattedUsageRate,
          icon: Icons.analytics,
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }
}
