import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../widgets/action_buttons.dart';
import '../widgets/subscription_plan_card.dart';
import '../widgets/recent_analyses_grid.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/notification_bell_icon.dart';
import '../../../plant_analysis/presentation/pages/capture_screen.dart';
import '../../../subscription/presentation/screens/subscription_status_screen.dart';

class FarmerDashboardPage extends StatefulWidget {
  const FarmerDashboardPage({super.key});

  @override
  State<FarmerDashboardPage> createState() => _FarmerDashboardPageState();
}

class _FarmerDashboardPageState extends State<FarmerDashboardPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Key _subscriptionCardKey = UniqueKey();
  Key _recentAnalysesKey = UniqueKey();
  
  void _refreshDashboard() {
    setState(() {
      _subscriptionCardKey = UniqueKey();
      _recentAnalysesKey = UniqueKey();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to capture screen when analysis tab is tapped
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CaptureScreen(),
        ),
      );
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
                          height: 56,  // %30 küçültüldü (80 * 0.7)
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
                    SizedBox(
                      width: 96,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Notifications Bell with Badge
                          const NotificationBellIcon(),
                          const SizedBox(width: 8),
                          // Settings Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Color(0xFF6B7280),
                                size: 28,
                              ),
                              onPressed: () {
                                // Settings functionality
                              },
                            ),
                          ),
                        ],
                      ),
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
                  const ActionButtons(),

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