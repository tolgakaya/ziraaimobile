import 'package:flutter/material.dart';
import '../widgets/action_buttons.dart';
import '../widgets/subscription_plan_card.dart';
import '../widgets/recent_analyses_grid.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/notification_bell_icon.dart';
import '../../../plant_analysis/presentation/pages/capture_screen.dart';
import '../../../plant_analysis/presentation/pages/analysis_history_screen.dart';
import '../../../subscription/presentation/screens/subscription_status_screen.dart';
import '../../../referral/presentation/screens/referral_dashboard_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../referral/presentation/bloc/referral_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../authentication/presentation/screens/login_screen.dart';
import '../../../sponsorship/presentation/screens/create_sponsor_profile_screen.dart';
import '../../../../core/security/token_manager.dart';
import 'sponsor_dashboard_page.dart';
import 'package:flutter/scheduler.dart';
import '../../../sponsorship/presentation/screens/farmer/sponsorship_redemption_screen.dart';
import '../../../dealer/presentation/screens/pending_invitations_screen.dart';
import '../../../profile/presentation/screens/farmer_profile_screen.dart';

class FarmerDashboardPage extends StatefulWidget {
  final String? pendingSponsorshipCode;
  final bool hasPendingDealerInvitations;

  const FarmerDashboardPage({
    super.key,
    this.pendingSponsorshipCode,
    this.hasPendingDealerInvitations = false,
  });

  @override
  State<FarmerDashboardPage> createState() => _FarmerDashboardPageState();
}

class _FarmerDashboardPageState extends State<FarmerDashboardPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Key _subscriptionCardKey = UniqueKey();
  Key _recentAnalysesKey = UniqueKey();
  bool _hasSponsorRole = false;

  void _refreshDashboard() {
    setState(() {
      _subscriptionCardKey = UniqueKey();
      _recentAnalysesKey = UniqueKey();
    });
  }

  Future<void> _navigateToSponsorDashboard() async {
    print('🎯 FarmerDashboard: _navigateToSponsorDashboard called, _hasSponsorRole: $_hasSponsorRole');

    // If not sponsor, navigate to create sponsor profile
    if (!_hasSponsorRole) {
      print('📝 FarmerDashboard: Opening CreateSponsorProfileScreen...');

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateSponsorProfileScreen(),
        ),
      );

      print('↩️ FarmerDashboard: Returned from CreateSponsorProfileScreen, result: $result');

      // Refresh dashboard and check sponsor role if profile was created
      if (result == true && mounted) {
        print('✅ FarmerDashboard: Profile created successfully, checking sponsor role...');

        // Re-check sponsor role from token (it should be updated after profile creation)
        await _checkSponsorRole();

        print('🔄 FarmerDashboard: After _checkSponsorRole, _hasSponsorRole: $_hasSponsorRole');

        _refreshDashboard();

        // If sponsor role was successfully added, navigate to sponsor dashboard
        if (_hasSponsorRole && mounted) {
          print('🎉 FarmerDashboard: Navigating to SponsorDashboardPage!');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SponsorDashboardPage(),
            ),
          );
        } else {
          print('⚠️ FarmerDashboard: Sponsor role NOT found after refresh!');
        }
      }
    } else {
      print('✨ FarmerDashboard: User already has Sponsor role, opening SponsorDashboard');
      // If already sponsor, navigate to sponsor dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SponsorDashboardPage(),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSponsorRole();

    // Handle pending sponsorship code navigation
    if (widget.pendingSponsorshipCode != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToSponsorshipRedemption(widget.pendingSponsorshipCode!);
        }
      });
    }

    // ✅ Handle pending dealer invitations navigation
    if (widget.hasPendingDealerInvitations) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            print('[Dashboard] 🧭 Navigating to PendingInvitationsScreen');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PendingInvitationsScreen(),
              ),
            );
          }
        });
      });
    }
  }

  void _navigateToSponsorshipRedemption(String code) async {
    print('[Dashboard] 🧭 Navigating to redemption screen with code: $code');

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SponsorshipRedemptionScreen(
          autoFilledCode: code,
        ),
      ),
    );

    // Refresh dashboard if redemption was successful
    if (result == true && mounted) {
      print('[Dashboard] 🔄 Refreshing dashboard after successful redemption');
      _refreshDashboard();
    }

    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sponsorluk kodu bulundu! SMS\'den kod otomatik dolduruldu.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ✅ REMOVED: _navigateToDealerInvitation method
  // Dealer invitation navigation now handled in LoginScreen/RegisterScreen via backend API

  Future<void> _checkSponsorRole() async {
    try {
      print('🔍 FarmerDashboard: Starting sponsor role check...');
      final tokenManager = GetIt.instance<TokenManager>();

      // Get all roles from token
      final allRoles = await tokenManager.getUserRoles();
      print('📋 FarmerDashboard: All roles in token: $allRoles');

      final hasSponsor = await tokenManager.hasRole('Sponsor');

      if (mounted) {
        setState(() {
          _hasSponsorRole = hasSponsor;
        });
      }

      print('🔍 FarmerDashboard: Sponsor role check - hasSponsor: $hasSponsor');
    } catch (e) {
      print('⚠️ FarmerDashboard: Error checking sponsor role: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force refresh subscription card when app resumes
      setState(() {
        _subscriptionCardKey = UniqueKey();
      });
    }
  }

  void _onItemTapped(int index) {
    // Navigate to screens based on tab
    if (index == 0) {
      // Ana Sayfa - Already on dashboard, do nothing or refresh
      setState(() {
        _selectedIndex = 0;
      });
    } else if (index == 1) {
      // Analizler - Navigate to Analysis History
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AnalysisHistoryScreen(),
        ),
      ).then((_) {
        // Reset selection when returning
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else if (index == 2) {
      // Mesajlar - Navigate to Analysis History with Active Conversations filter
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AnalysisHistoryScreen(
            initialFilter: 'active',
          ),
        ),
      ).then((_) {
        // Reset selection when returning
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else if (index == 3) {
      // Analiz - Camera/Capture
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CaptureScreen(),
        ),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else if (index == 4) {
      // Davet - Referral
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => GetIt.instance<ReferralBloc>(),
            child: const ReferralDashboardScreen(),
          ),
        ),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: Color(0x80FFFFFF), // bg-white/80
              // Backdrop blur effect (approximate)
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/logos/ziraai_logo.png',
                          height: 90,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to text if image fails to load
                            return const Text(
                              'ZiraAI',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Notifications Bell with Badge
                        const NotificationBellIcon(),
                        const SizedBox(width: 8),
                        // Profile Icon
                        IconButton(
                          icon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF059669), // Green color for profile
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FarmerProfileScreen(),
                              ),
                            );
                          },
                          tooltip: 'Profilim',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons
                  ActionButtons(
                    hasSponsorRole: _hasSponsorRole,
                    onSponsorButtonTap: _navigateToSponsorDashboard,
                  ),

                  const SizedBox(height: 24),

                  // Subscription Plan Card
                  SubscriptionPlanCard(
                    key: _subscriptionCardKey,
                    onNavigateToSubscription: () async {
                      // Navigate and wait for result
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionStatusScreen(),
                        ),
                      );
                      
                      // Refresh dashboard if subscription was updated
                      if (result == true && mounted) {
                        _refreshDashboard();
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Recent Analyses Section
                  const Text(
                    'Son Analizler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 12),

                  RecentAnalysesGrid(key: _recentAnalysesKey),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}