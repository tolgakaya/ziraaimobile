import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/screens/login_screen.dart';
import '../../../sponsorship/data/services/sponsor_service.dart';
import '../../../sponsorship/data/models/sponsor_dashboard_summary.dart';
import '../../../sponsorship/presentation/screens/code_distribution_screen.dart';
import '../widgets/sponsor_metric_card.dart';
import '../widgets/sponsor_action_button.dart';
import '../widgets/active_package_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SponsorDashboardPage extends StatefulWidget {
  const SponsorDashboardPage({super.key});

  @override
  State<SponsorDashboardPage> createState() => _SponsorDashboardPageState();
}

class _SponsorDashboardPageState extends State<SponsorDashboardPage> {
  final SponsorService _sponsorService = GetIt.instance<SponsorService>();

  SponsorDashboardSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _sponsorService.getDashboardSummary();

      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Text('Çıkış Yap'),
          ],
        ),
        content: const Text(
          'Çıkış yapmak istediğinizden emin misiniz?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleLogout(context);
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    GetIt.instance<AuthBloc>().add(const AuthLogoutRequested());

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => GetIt.instance<AuthBloc>(),
          child: const LoginScreen(),
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header with ZiraAI Logo
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  // ZiraAI Logo
                  Image.asset(
                    'assets/logos/ziraai_logo.png',
                    height: 56,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'ZiraAI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // Switch to Farmer Dashboard button
                  IconButton(
                    icon: const Icon(
                      Icons.agriculture,
                      color: Color(0xFF10B981),
                    ),
                    tooltip: 'Çiftçi Paneli',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  // Logout button
                  IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Color(0xFFEF4444),
                    ),
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'Hata: $_errorMessage',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadDashboardData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tekrar Dene'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDashboardData,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Metric Cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: SponsorMetricCard(
                                        icon: Icons.send,
                                        iconColor: const Color(0xFF3B82F6),
                                        value: '${_summary!.sentCodesCount}/${_summary!.totalCodesCount}',
                                        label: 'Gönderilen Kodlar',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SponsorMetricCard(
                                        icon: Icons.analytics,
                                        iconColor: const Color(0xFFF59E0B),
                                        value: '${_summary!.totalAnalysesCount}',
                                        label: 'Analizler',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SponsorMetricCard(
                                        icon: Icons.shopping_bag,
                                        iconColor: const Color(0xFF10B981),
                                        value: '${_summary!.purchasesCount}',
                                        label: 'Satın Alımlar',
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Action Buttons
                                SponsorActionButton(
                                  icon: Icons.send,
                                  label: 'Kod Dağıt',
                                  color: const Color(0xFF3B82F6),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CodeDistributionScreen(),
                                      ),
                                    ).then((_) {
                                      // Refresh dashboard when returning
                                      _loadDashboardData();
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                SponsorActionButton(
                                  icon: Icons.shopping_cart,
                                  label: 'Paket Satın Al',
                                  color: const Color(0xFF10B981),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Paket Satın Alma - Yakında'),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                SponsorActionButton(
                                  icon: Icons.bar_chart,
                                  label: 'İstatistikleri Görüntüle',
                                  color: const Color(0xFFF59E0B),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('İstatistikler - Yakında'),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Active Packages Section
                                const Text(
                                  'Aktif Sponsorluk Paketleriniz',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Package Cards
                                if (_summary!.activePackages.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.inventory_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Henüz paket satın alınmadı',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _summary!.activePackages.length,
                                    itemBuilder: (context, index) {
                                      return ActivePackageCard(
                                        package: _summary!.activePackages[index],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.check_circle,
                isSelected: true,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                isSelected: false,
              ),
              _buildNavItem(
                icon: Icons.bar_chart_outlined,
                isSelected: false,
              ),
              _buildNavItem(
                icon: Icons.search,
                isSelected: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
  }) {
    return Icon(
      icon,
      color: isSelected ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
      size: 28,
    );
  }
}
