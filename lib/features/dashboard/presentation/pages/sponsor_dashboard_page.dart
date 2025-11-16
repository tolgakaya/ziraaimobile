import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/screens/login_screen.dart';
import '../../../sponsorship/data/services/sponsor_service.dart';
import '../../../sponsorship/data/models/sponsor_dashboard_summary.dart';
import '../../../sponsorship/presentation/screens/code_distribution_screen.dart';
import '../../../sponsorship/presentation/screens/tier_selection_screen.dart';
import '../../../sponsorship/presentation/screens/sponsored_analyses_list_screen.dart';
import '../../../sponsorship/presentation/screens/sponsor_profile_screen.dart';
import '../../../dealer/data/dealer_api_service.dart';
import '../../../dealer/domain/models/dealer_dashboard_summary.dart';
import '../../../dealer/presentation/screens/pending_invitations_screen.dart';
import '../widgets/sponsor_metric_card.dart';
import '../widgets/sponsor_action_button.dart';
import '../widgets/active_package_card.dart';
import '../widgets/bottom_navigation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SponsorDashboardPage extends StatefulWidget {
  const SponsorDashboardPage({super.key});

  @override
  State<SponsorDashboardPage> createState() => _SponsorDashboardPageState();
}

class _SponsorDashboardPageState extends State<SponsorDashboardPage> with WidgetsBindingObserver {
  final SponsorService _sponsorService = GetIt.instance<SponsorService>();
  final DealerApiService _dealerApiService = GetIt.instance<DealerApiService>();

  SponsorDashboardSummary? _summary;
  DealerDashboardSummary? _dealerSummary;
  bool _isLoading = true;
  bool _isDealerDataLoading = false;
  String? _errorMessage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh dashboard when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
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

        // Load dealer data separately (non-blocking)
        _loadDealerData();
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

  Future<void> _loadDealerData() async {
    setState(() {
      _isDealerDataLoading = true;
    });

    try {
      final dealerSummary = await _dealerApiService.getMyDashboard();

      if (mounted) {
        setState(() {
          _dealerSummary = dealerSummary;
          _isDealerDataLoading = false;
        });
      }
    } catch (e) {
      print('[SponsorDashboard] ℹ️ Dealer data not available (user may not be a dealer): $e');
      if (mounted) {
        setState(() {
          _isDealerDataLoading = false;
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

  void _onItemTapped(int index) {
    // Navigate to screens based on tab
    if (index == 0) {
      // Ana Sayfa - Already on dashboard, do nothing or refresh
      setState(() {
        _selectedIndex = 0;
      });
    } else if (index == 1) {
      // Analizler - Navigate to Sponsored Analyses List Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SponsoredAnalysesListScreen(),
        ),
      ).then((_) {
        // Reset selection when returning
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else if (index == 2) {
      // Mesajlar - Navigate to Sponsored Analyses List with Unread filter
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SponsoredAnalysesListScreen(
            initialFilter: 'unread',
          ),
        ),
      ).then((_) {
        // Reset selection when returning
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else if (index == 3) {
      // Analiz - TODO: Navigate to sponsor analysis
      setState(() {
        _selectedIndex = 0;
      });
    } else if (index == 4) {
      // Davet - TODO: Navigate to sponsor invitations
      setState(() {
        _selectedIndex = 0;
      });
    }
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
                    height: 90,
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
                  // Profile button
                  IconButton(
                    icon: const Icon(
                      Icons.person,
                      color: Color(0xFF10B981),
                    ),
                    tooltip: 'Profil',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SponsorProfileScreen(),
                        ),
                      );
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

                                // Action Buttons - 2x2 Grid Layout
                                Row(
                                  children: [
                                    // Sol üst: Kod Dağıt (Gönder)
                                    Expanded(
                                      child: SponsorActionButton(
                                        icon: Icons.send,
                                        label: 'Gönder',
                                        color: const Color(0xFF3B82F6),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CodeDistributionScreen(
                                                dashboardSummary: _summary!,
                                              ),
                                            ),
                                          ).then((_) {
                                            // Refresh dashboard when returning
                                            _loadDashboardData();
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Sağ üst: Paket Satın Al (Satın Al)
                                    Expanded(
                                      child: SponsorActionButton(
                                        icon: Icons.shopping_cart,
                                        label: 'Satın Al',
                                        color: const Color(0xFF10B981),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const TierSelectionScreen(),
                                            ),
                                          ).then((_) {
                                            // Refresh dashboard when returning
                                            _loadDashboardData();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Sol alt: Sponsorlu Analizleri Görüntüle (Analizler)
                                    Expanded(
                                      child: SponsorActionButton(
                                        icon: Icons.analytics,
                                        label: 'Analizler',
                                        color: const Color(0xFF8B5CF6),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const SponsoredAnalysesListScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Sağ alt: İstatistikleri Görüntüle (İstatistik)
                                    Expanded(
                                      child: SponsorActionButton(
                                        icon: Icons.bar_chart,
                                        label: 'İstatistik',
                                        color: const Color(0xFFF59E0B),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('İstatistikler - Yakında'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
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

                                // Dealer Statistics Section (only show if dealer data available)
                                if (_dealerSummary != null) ...[
                                  const SizedBox(height: 24),
                                  _buildDealerCodesCard(),
                                  const SizedBox(height: 12),
                                  _buildPendingInvitationsCard(),
                                ],
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DashboardBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDealerCodesCard() {
    if (_dealerSummary == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Dealer Kodlarım',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.archive,
                    iconColor: const Color(0xFF10B981),
                    label: 'Toplam Transfer',
                    value: '${_dealerSummary!.totalCodesReceived}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.send,
                    iconColor: const Color(0xFF3B82F6),
                    label: 'Gönderilmiş',
                    value: '${_dealerSummary!.codesSent}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    iconColor: const Color(0xFF8B5CF6),
                    label: 'Kullanılmış',
                    value: '${_dealerSummary!.codesUsed}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.inventory,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Kullanılabilir',
                    value: '${_dealerSummary!.codesAvailable}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Usage Rate Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kullanım Oranı',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '${_dealerSummary!.usageRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _dealerSummary!.usageRate / 100,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _dealerSummary!.usageRate >= 80
                          ? const Color(0xFF10B981)
                          : _dealerSummary!.usageRate >= 50
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInvitationsCard() {
    if (_dealerSummary == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _dealerSummary!.pendingInvitationsCount > 0
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PendingInvitationsScreen(),
                  ),
                ).then((_) {
                  // Refresh dealer data when returning
                  _loadDealerData();
                });
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _dealerSummary!.pendingInvitationsCount > 0
                      ? const Color(0xFFF59E0B).withOpacity(0.1)
                      : const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _dealerSummary!.pendingInvitationsCount > 0
                      ? Icons.mail
                      : Icons.check_circle,
                  color: _dealerSummary!.pendingInvitationsCount > 0
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bekleyen Dealer Davetiyelerim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dealerSummary!.pendingInvitationsCount > 0
                          ? '${_dealerSummary!.pendingInvitationsCount} adet bekleyen davetiniz var'
                          : 'Bekleyen davetiniz bulunmuyor',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon (only if there are pending invitations)
              if (_dealerSummary!.pendingInvitationsCount > 0)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF9CA3AF),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
