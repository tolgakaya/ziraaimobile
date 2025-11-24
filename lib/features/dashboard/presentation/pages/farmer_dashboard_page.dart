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
import '../../../sponsorship/presentation/screens/farmer/sponsorship_inbox_screen.dart';
import '../../../dealer/presentation/screens/pending_invitations_screen.dart';
import '../../../profile/presentation/screens/farmer_profile_screen.dart';
import '../../../../core/services/sponsorship_sms_listener.dart';
import '../../../sponsorship/data/services/sponsor_service.dart';
import '../../../sponsorship/data/models/sponsorship_inbox_item.dart';

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
  int _activeOffersCount = 0; // Track active sponsorship offers

  void _refreshDashboard() {
    // Trigger token refresh to get updated user info (including new subscription)
    context.read<AuthBloc>().add(const AuthCheckStatusRequested());

    // Re-check active offers (in case user redeemed a code)
    _checkActiveOffers();

    // Refresh UI widgets
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
    _checkActiveOffers(); // Check for active sponsorship offers

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

  /// Check for active sponsorship offers
  /// Only shows inbox card if there are active (unused, non-expired) offers
  Future<void> _checkActiveOffers() async {
    try {
      print('📬 FarmerDashboard: Checking for active sponsorship offers...');
      final sponsorService = GetIt.instance<SponsorService>();

      // Fetch inbox with only active codes (no used, no expired)
      final response = await sponsorService.fetchInbox(
        includeUsed: false,
        includeExpired: false,
      );

      // Convert to model objects
      final items = response
          .map((json) => SponsorshipInboxItem.fromJson(json))
          .toList();

      // Count active offers
      final activeCount = items.where((item) => item.isActive).length;

      if (mounted) {
        setState(() {
          _activeOffersCount = activeCount;
        });
      }

      print('✅ FarmerDashboard: Found $activeCount active offers');
    } catch (e) {
      print('⚠️ FarmerDashboard: Error checking active offers: $e');
      // On error, hide the card by setting count to 0
      if (mounted) {
        setState(() {
          _activeOffersCount = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      print('[Dashboard] 📱 App resumed - refreshing dashboard state');

      // Force refresh subscription card when app resumes
      setState(() {
        _subscriptionCardKey = UniqueKey();
      });

      // Check for active sponsorship offers (in case new codes arrived)
      _checkActiveOffers();

      // Check for pending sponsorship code from SMS
      await _checkPendingSponsorshipCode();
    }
  }

  /// Check for pending sponsorship code and navigate to redemption if found
  Future<void> _checkPendingSponsorshipCode() async {
    try {
      // Check for pending sponsorship code from SMS listener
      final pendingCode = await SponsorshipSmsListener.checkPendingCode();

      if (pendingCode != null && mounted) {
        print('[Dashboard] ✅ Found pending sponsorship code from SMS: $pendingCode');

        // Clear the pending code from storage before navigation
        await SponsorshipSmsListener.clearPendingCode();

        // Navigate to redemption screen
        _navigateToSponsorshipRedemption(pendingCode);
      } else {
        print('[Dashboard] ℹ️ No pending sponsorship code found');
      }
    } catch (e) {
      print('[Dashboard] ❌ Error checking pending sponsorship code: $e');
    }
  }

  void _onItemTapped(int index) {
    // Navigate to screens based on tab
    if (index == 0) {
      // Ana Sayfa - Already on dashboard, refresh offers check
      _checkActiveOffers(); // Check for new offers when user returns to home
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
        // Reset selection when returning and check for new offers
        _checkActiveOffers();
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
        // Reset selection when returning and check for new offers
        _checkActiveOffers();
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
        _checkActiveOffers();
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
        _checkActiveOffers();
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
                            ).then((_) {
                              // Check for new offers when returning from profile
                              _checkActiveOffers();
                            });
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

                  const SizedBox(height: 16),

                  // Sponsorship Inbox Card (only show if there are active offers)
                  if (_activeOffersCount > 0) ...[
                    _buildSponsorshipInboxCard(),
                    const SizedBox(height: 24),
                  ],

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

  /// Build Sponsorship Inbox Card
  /// Shows inbox entry point with active code count
  Widget _buildSponsorshipInboxCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () async {
          // Navigate to inbox and await result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SponsorshipInboxScreen(),
            ),
          );

          // If user redeemed a code, refresh dashboard
          if (result == true && mounted) {
            print('📬 Dashboard: User returned from inbox, refreshing...');
            _checkActiveOffers();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inbox,
                  color: Color(0xFF22C55E),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Text content
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sponsorluk Teklifleri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Size gönderilen kodları görüntüleyin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}