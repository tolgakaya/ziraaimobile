import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../features/dashboard/presentation/widgets/bottom_navigation.dart';
import '../../features/plant_analysis/presentation/pages/capture_screen.dart';
import '../../features/plant_analysis/presentation/pages/analysis_history_screen.dart';
import '../../features/referral/presentation/screens/referral_dashboard_screen.dart';
import '../../features/referral/presentation/bloc/referral_bloc.dart';
import '../../features/dashboard/presentation/pages/farmer_dashboard_page.dart';

/// Reusable bottom navigation for farmer-facing screens
/// Shows consistent navigation across: dashboard, analysis, capture, referral, subscription screens
class FarmerBottomNav extends StatelessWidget {
  final int currentIndex;

  const FarmerBottomNav({
    super.key,
    this.currentIndex = 0,
  });

  void _onItemTapped(BuildContext context, int index) {
    // Navigate to screens based on tab
    if (index == 0) {
      // Ana Sayfa - Navigate to dashboard
      if (index == currentIndex) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const FarmerDashboardPage(),
        ),
        (route) => false,
      );
    } else if (index == 1) {
      // Analizler - Navigate to Analysis History
      // Always navigate to analysis history, even from detail screens (both use index 1)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AnalysisHistoryScreen(),
        ),
        (route) => route.settings.name == '/dashboard' || route.isFirst,
      );
    } else if (index == 2) {
      // Mesajlar - Navigate to Analysis History with Active Conversations filter
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AnalysisHistoryScreen(
            initialFilter: 'active',
          ),
        ),
      );
    } else if (index == 3) {
      // Analiz - Camera/Capture
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CaptureScreen(),
        ),
      );
    } else if (index == 4) {
      // Davet - Referral
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => GetIt.instance<ReferralBloc>(),
            child: const ReferralDashboardScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardBottomNavigation(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
    );
  }
}
