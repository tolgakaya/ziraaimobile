import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/utils/minimal_service_locator.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/screens/splash_screen.dart';
import 'features/authentication/presentation/screens/phone_auth/phone_number_screen.dart';
import 'core/services/signalr_service.dart';
import 'core/services/deep_link_service.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupMinimalServiceLocator();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SignalRService _signalRService = SignalRService();
  final DeepLinkService _deepLinkService = DeepLinkService();
  StreamSubscription<String>? _deepLinkSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  String? _pendingReferralCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't initialize SignalR here - SplashScreen handles auto-login and SignalR

    // Initialize deep link service with uni_links
    _initializeDeepLinks();
  }

  /// Initialize deep link handling with uni_links package
  Future<void> _initializeDeepLinks() async {
    await _deepLinkService.initialize();

    // Listen to referral code stream
    _deepLinkSubscription = _deepLinkService.referralCodeStream.listen((referralCode) {
      print('📱 Main: Referral code received from deep link: $referralCode');
      // Store referral code for registration screen
      // We'll navigate to PhoneNumberScreen with this code
      if (mounted) {
        _handleReferralCode(referralCode);
      }
    });
  }

  /// Handle received referral code from deep link
  void _handleReferralCode(String referralCode) {
    print('📱 Main: Referral code received from deep link: $referralCode');

    // Use navigator key to access context
    final context = navigatorKey.currentContext;
    if (context == null || !mounted) {
      print('⚠️ Navigator context not ready, will retry after delay');
      _pendingReferralCode = referralCode;

      // Retry after a short delay to give MaterialApp time to initialize
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pendingReferralCode != null) {
          final code = _pendingReferralCode;
          _pendingReferralCode = null;
          if (code != null) {
            _handleReferralCode(code);
          }
        }
      });
      return;
    }

    // Show dialog to inform user about referral
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.green[600]),
            const SizedBox(width: 12),
            const Text('Davet Kodu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Davet edildiniz! Kayıt olduğunuzda ücretsiz kredi kazanacaksınız.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                referralCode,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Navigate to phone registration with referral code
              // No need for BlocProvider - it's available from the MaterialApp ancestor
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PhoneNumberScreen(
                    isRegistration: true,
                    referralCode: referralCode,
                  ),
                ),
              );
            },
            child: const Text('Kayıt Ol'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Reconnect SignalR when app resumes (if user is authenticated)
    if (state == AppLifecycleState.resumed) {
      if (!_signalRService.isConnected) {
        print('🔄 App resumed: Attempting to reconnect SignalR...');
        // SignalR will be reconnected automatically if token is valid
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _signalRService.disconnect();
    _deepLinkSubscription?.cancel();
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check for pending referral code after first frame
    if (_pendingReferralCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final code = _pendingReferralCode;
        _pendingReferralCode = null;
        if (code != null) {
          _handleReferralCode(code);
        }
      });
    }

    return BlocProvider(
      create: (_) => GetIt.instance<AuthBloc>(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'ZiraAI Mobile',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: const SplashScreen(), // Start with SplashScreen for auto-login
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}