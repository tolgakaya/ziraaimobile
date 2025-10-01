import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/security/token_manager.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/services/signalr_notification_integration.dart';
import '../../../dashboard/presentation/bloc/notification_bloc.dart';
import '../../../dashboard/presentation/pages/farmer_dashboard_page.dart';
import '../bloc/auth_bloc.dart';
import 'login_screen.dart';

/// Splash screen with automatic login check
///
/// Flow:
/// 1. Check if valid token exists
/// 2. If yes → Auto-login to Dashboard
/// 3. If no → Try refresh token
/// 4. If refresh fails → Go to Login
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  /// Check authentication and navigate accordingly
  Future<void> _checkAuthenticationStatus() async {
    try {
      print('🔐 SplashScreen: Checking authentication status...');

      // Wait a moment for better UX (splash should be visible briefly)
      await Future.delayed(const Duration(milliseconds: 500));

      final tokenManager = GetIt.instance<TokenManager>();
      final authService = GetIt.instance<AuthService>();

      // Check if we have a token
      final token = await tokenManager.getToken();

      if (token == null || token.isEmpty) {
        print('❌ SplashScreen: No token found, navigating to login');
        _navigateToLogin();
        return;
      }

      print('✅ SplashScreen: Token found, checking validity...');

      // Check if token belongs to current environment
      if (!tokenManager.isTokenForCurrentEnvironment(token)) {
        print('❌ SplashScreen: Token is for different environment, clearing tokens');
        await tokenManager.clearTokens();
        _navigateToLogin();
        return;
      }

      // Check if token is valid (not expired)
      if (!tokenManager.isTokenExpired(token)) {
        print('✅ SplashScreen: Token is valid, auto-login successful');

        // Token is valid, initialize SignalR and go to dashboard
        await _initializeSignalRAfterAutoLogin();

        _navigateToDashboard();
        return;
      }

      // Token is expired, try to refresh
      print('⚠️ SplashScreen: Token expired, attempting refresh...');

      final refreshToken = await tokenManager.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        print('❌ SplashScreen: No refresh token, navigating to login');
        _navigateToLogin();
        return;
      }

      // Try to refresh token
      final refreshSuccess = await _attemptTokenRefresh(refreshToken);

      if (refreshSuccess) {
        print('✅ SplashScreen: Token refreshed successfully, auto-login successful');

        // Initialize SignalR after successful refresh
        await _initializeSignalRAfterAutoLogin();

        _navigateToDashboard();
      } else {
        print('❌ SplashScreen: Token refresh failed, navigating to login');
        await tokenManager.clearTokens();
        _navigateToLogin();
      }
    } catch (e, stackTrace) {
      print('❌ SplashScreen: Error during authentication check: $e');
      print('Stack trace: $stackTrace');

      // On error, go to login for safety
      _navigateToLogin();
    }
  }

  /// Attempt to refresh access token
  Future<bool> _attemptTokenRefresh(String refreshToken) async {
    try {
      // Use Dio directly for refresh to avoid circular dependencies
      final dio = Dio();

      final response = await dio.post(
        'https://ziraai-api-sit.up.railway.app/api/v1/auth/refresh-token',
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Extract new tokens
        String? newAccessToken;
        String? newRefreshToken;

        if (data.containsKey('data')) {
          final tokenData = data['data'] as Map<String, dynamic>;
          newAccessToken = tokenData['token'] ?? tokenData['accessToken'];
          newRefreshToken = tokenData['refreshToken'];
        } else {
          newAccessToken = data['token'] ?? data['accessToken'];
          newRefreshToken = data['refreshToken'];
        }

        if (newAccessToken != null) {
          final tokenManager = GetIt.instance<TokenManager>();
          await tokenManager.saveToken(newAccessToken);

          if (newRefreshToken != null) {
            await tokenManager.saveRefreshToken(newRefreshToken);
          }

          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ SplashScreen: Token refresh error: $e');
      return false;
    }
  }

  /// Initialize SignalR after successful auto-login
  Future<void> _initializeSignalRAfterAutoLogin() async {
    try {
      final authService = GetIt.instance<AuthService>();
      final token = await authService.getToken();

      if (token != null && token.isNotEmpty) {
        print('🔌 SplashScreen: Initializing SignalR after auto-login...');

        final signalRService = SignalRService();
        await signalRService.initialize(token);

        // Setup SignalR notification integration
        final notificationBloc = GetIt.instance<NotificationBloc>();
        final integration = SignalRNotificationIntegration(
          signalRService: signalRService,
          notificationBloc: notificationBloc,
        );
        integration.setupEventHandlers();

        print('✅ SplashScreen: SignalR initialized successfully');
      }
    } catch (e) {
      print('⚠️ SplashScreen: Failed to initialize SignalR (non-critical): $e');
      // Don't block auto-login if SignalR fails
    }
  }

  /// Navigate to Dashboard
  void _navigateToDashboard() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const FarmerDashboardPage(),
      ),
    );
  }

  /// Navigate to Login Screen
  void _navigateToLogin() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => GetIt.instance<AuthBloc>(),
          child: const LoginScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22C55E), // ZiraAI green
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.eco,
                size: 60,
                color: Color(0xFF22C55E),
              ),
            ),

            const SizedBox(height: 32),

            // App name
            const Text(
              'ZiraAI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tarımda Yapay Zeka',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Yükleniyor...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
