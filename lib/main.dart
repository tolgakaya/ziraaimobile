import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/utils/minimal_service_locator.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/screens/splash_screen.dart';
import 'features/authentication/presentation/screens/phone_auth/phone_number_screen.dart';
import 'core/services/signalr_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/navigation_service.dart';
// import 'core/services/install_referrer_service.dart';  // TEMPORARILY DISABLED
import 'core/services/sms_referral_service.dart';
import 'core/services/sponsorship_sms_listener.dart';
// ✅ REMOVED: dealer_invitation_sms_listener - switched to backend API integration
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupMinimalServiceLocator();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // Static flags to communicate with SplashScreen
  static bool _smsCheckComplete = false;
  static bool _smsReferralNavigated = false;

  /// Public getter for SplashScreen to check if SMS navigation happened
  static bool get hasSmsReferralNavigated => _smsReferralNavigated;

  /// Public getter for SplashScreen to check if SMS check is complete
  static bool get isSmsCheckComplete => _smsCheckComplete;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SignalRService _signalRService = SignalRService();
  final DeepLinkService _deepLinkService = DeepLinkService();
  StreamSubscription<String>? _deepLinkSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  String? _pendingReferralCode;
  // bool _installReferrerChecked = false;  // TEMPORARILY DISABLED
  bool _hasCheckedSms = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register NavigationService with the navigator key
    GetIt.instance.registerSingleton<NavigationService>(
      NavigationService(navigatorKey),
    );

    // Don't initialize SignalR here - SplashScreen handles auto-login and SignalR

    // Check Install Referrer for deferred deep linking (first app launch after install)
    // TEMPORARILY DISABLED - install_referrer package API changed, using SMS solution instead
    // _checkInstallReferrer();

    // Check SMS for referral code (deferred deep linking - app not installed scenario)
    _checkSmsForReferralCode();

    // Initialize sponsorship SMS listener for automatic code detection
    _initializeSponsorshipSmsListener();

    // ✅ REMOVED: Dealer invitation SMS listener - switched to backend API integration
    // Dealer invitations are now checked via backend API in login/register screens

    // Initialize deep link service with app_links
    _initializeDeepLinks();
  }

  /// Check Play Store Install Referrer for deferred deep linking
  /// This runs once after app installation from Play Store
  /// TEMPORARILY DISABLED - install_referrer package incompatible, using SMS solution
  /*
  Future<void> _checkInstallReferrer() async {
    if (_installReferrerChecked) return;

    try {
      final installReferrerService = getIt<InstallReferrerService>();

      print('📦 Main: Checking install referrer...');
      final referralCode = await installReferrerService.checkInstallReferrer();

      if (referralCode != null) {
        print('✅ Main: Install referrer code found: $referralCode');
        _pendingReferralCode = referralCode;

        // Wait for MaterialApp to be ready, then navigate
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _pendingReferralCode != null) {
            _handleReferralCode(_pendingReferralCode!);
            _pendingReferralCode = null;
          }
        });
      } else {
        print('📦 Main: No install referrer code found');
      }

      _installReferrerChecked = true;
    } catch (e) {
      print('❌ Main: Install referrer check error: $e');
      _installReferrerChecked = true;
    }
  }
  */

  /// Check SMS for referral code (deferred deep linking)
  /// This runs once after app installation when user doesn't have app installed
  Future<void> _checkSmsForReferralCode() async {
    // Bir kez kontrol et
    if (_hasCheckedSms) {
      print('ℹ️ SMS zaten kontrol edildi');
      MyApp._smsCheckComplete = true;
      return;
    }

    // UI hazır olmasını bekle - SplashScreen'den önce bitirmek için daha kısa
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      print('🔍 SMS\'den referral kodu aranıyor...');

      final smsService = getIt<SmsReferralService>();
      final referralCode = await smsService.extractReferralFromSms();

      _hasCheckedSms = true;  // İşaretlendi

      if (referralCode != null) {
        print('✅ SMS\'den kod bulundu: $referralCode');
        _handleReferralCode(referralCode);
      } else {
        print('ℹ️ SMS\'de kod yok - normal flow devam ediyor');
      }
    } catch (e, stackTrace) {
      print('⚠️ SMS kontrolü hatası: $e');
      print('Stack trace: $stackTrace');
      _hasCheckedSms = true;
    } finally {
      // Always mark SMS check as complete
      MyApp._smsCheckComplete = true;
      print('✅ SMS check complete - SplashScreen can now proceed');
    }
  }

  /// Initialize sponsorship SMS listener
  /// This enables automatic code detection from SMS messages
  /// DELAYED: Start after 3 seconds to avoid permission conflicts
  Future<void> _initializeSponsorshipSmsListener() async {
    // CRITICAL FIX: Delay SMS listener to avoid permission conflicts with FlutterContacts
    // This prevents "Reply already submitted" crash when using phone contacts picker
    await Future.delayed(const Duration(seconds: 3));

    try {
      print('🎁 Main: Initializing sponsorship SMS listener (delayed)...');

      // ✅ FIX: Use GetIt to get singleton instance (prevents garbage collection)
      final smsListener = getIt<SponsorshipSmsListener>();
      await smsListener.initialize();

      print('✅ Main: Sponsorship SMS listener initialized successfully');
    } catch (e) {
      print('❌ Main: Failed to initialize sponsorship SMS listener: $e');
      print('❌ Stack trace: ${StackTrace.current}');  // ✅ Added stack trace for debugging
      // Don't block app startup if SMS listener fails
      // Silently ignore errors to prevent crashes
    }
  }

  /// ✅ REMOVED: Dealer invitation SMS listener initialization
  /// Dealer invitations are now checked via backend API integration:
  /// - LoginScreen: checks backend after email/password login
  /// - RegisterScreen: checks backend after registration
  /// - OtpVerificationScreen: checks backend after phone OTP login
  /// - SignalR: real-time notifications for new invitations
  /// SMS listener is NO LONGER USED for dealer invitations
  /// (SMS scanning is still active for sponsorship codes via SponsorshipSmsListener)

  /// Initialize deep link handling with app_links package
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

    // Listen to sponsorship code stream (NOT IMPLEMENTED YET - navigation handled in login_screen.dart)
    // Sponsorship codes are handled via post-login hook, not direct navigation
    // This stream can be used for real-time notifications if needed
    _deepLinkService.sponsorshipCodeStream.listen((sponsorshipCode) {
      print('📱 Main: Sponsorship code received from deep link: $sponsorshipCode');
      // Note: Actual navigation happens in login_screen.dart post-login hook
      // This is just for logging/monitoring purposes
    });

    // Listen to dealer invitation token stream
    _deepLinkService.dealerInvitationTokenStream.listen((token) {
      print('📱 Main: Dealer invitation token received from deep link: $token');
      // Note: Navigation will be handled in DealerInvitationScreen
      // For now, just log for monitoring purposes
      // Actual implementation will check if user is logged in and navigate accordingly
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

    // Navigate directly to phone registration with referral code (seamless experience)
    // No dialog - user goes straight to registration with code in background
    print('🎯 Navigating to registration screen with referral code: $referralCode');

    // Mark that SMS referral navigation is happening
    MyApp._smsReferralNavigated = true;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhoneNumberScreen(
          isRegistration: true,
          referralCode: referralCode,
        ),
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

        // Localization support for Turkish keyboard and characters
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'), // Turkish
          Locale('en', 'US'), // English
        ],
        locale: const Locale('tr', 'TR'), // Default to Turkish

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