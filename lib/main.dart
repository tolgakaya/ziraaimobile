import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/utils/minimal_service_locator.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/screens/splash_screen.dart';
import 'features/authentication/presentation/screens/phone_auth/phone_number_screen.dart';
import 'features/sponsorship/presentation/screens/farmer/sponsorship_redemption_screen.dart';
import 'features/dealer/presentation/screens/dealer_invitation_screen.dart';
import 'features/farmer_invitation/presentation/screens/farmer_invitation_screen.dart';
import 'core/services/signalr_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/install_referrer_service.dart';
import 'core/services/sms_referral_service.dart';
import 'core/services/sponsorship_sms_listener.dart';
import 'core/services/otp_sms_listener.dart';
import 'core/security/token_manager.dart';
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
  bool _installReferrerChecked = false;
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

    // Hybrid deferred deep linking strategy:
    // 1. Try Install Referrer (reliable for Play Store downloads)
    _checkInstallReferrer();

    // 2. Fall back to SMS scanning (works for APK and if Play Store referrer unavailable)
    _checkSmsForReferralCode();

    // Initialize sponsorship SMS listener for automatic code detection
    _initializeSponsorshipSmsListener();

    // Initialize OTP SMS listener for automatic code extraction (SMS Retriever API)
    _initializeOtpSmsListener();

    // ✅ REMOVED: Dealer invitation SMS listener - switched to backend API integration
    // Dealer invitations are now checked via backend API in login/register screens

    // Initialize deep link service with app_links
    _initializeDeepLinks();
  }

  /// Check Play Store Install Referrer for deferred deep linking
  /// This runs once after app installation from Play Store
  /// HYBRID STRATEGY: Try Install Referrer first, fall back to SMS if not found
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

  /// Check SMS for referral code (deferred deep linking)
  /// FALLBACK METHOD: Only runs if Install Referrer didn't find anything
  /// This runs once after app installation when user doesn't have app installed
  Future<void> _checkSmsForReferralCode() async {
    // Bir kez kontrol et
    if (_hasCheckedSms) {
      print('ℹ️ SMS zaten kontrol edildi');
      MyApp._smsCheckComplete = true;
      return;
    }

    // Wait for Install Referrer to finish first
    await Future.delayed(const Duration(milliseconds: 200));

    // Check if Install Referrer already found a code
    if (_pendingReferralCode != null) {
      print('✅ Install Referrer already found code, skipping SMS check');
      _hasCheckedSms = true;
      MyApp._smsCheckComplete = true;
      return;
    }

    try {
      print('🔍 SMS fallback: Searching for referral code in SMS...');

      final smsService = getIt<SmsReferralService>();
      final referralCode = await smsService.extractReferralFromSms();

      _hasCheckedSms = true;  // İşaretlendi

      if (referralCode != null) {
        print('✅ SMS fallback: Code found: $referralCode');
        _handleReferralCode(referralCode);
      } else {
        print('ℹ️ SMS fallback: No code found - normal flow continues');
      }
    } catch (e, stackTrace) {
      print('⚠️ SMS fallback error: $e');
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
    // CRITICAL FIX: Delay SMS listener to avoid permission conflicts
    // - FlutterContacts: Prevents "Reply already submitted" crash with phone contacts picker
    // - SmsReferralService: Avoids race condition when both request SMS permission simultaneously
    // Wait 5 seconds to ensure SplashScreen's SMS check completes first
    await Future.delayed(const Duration(seconds: 5));

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

  /// Get app signature hash for backend SMS integration
  /// This ONLY gets the hash - does NOT start listening
  /// The actual SMS listener will be started by CodeAutoFill mixin in OTP screen
  Future<void> _initializeOtpSmsListener() async {
    try {
      print('📲 Main: Getting app signature hash for backend...');

      // Get app signature hash WITHOUT starting listener
      final hash = await OtpSmsListener().getAppSignature();

      print('✅ Main: App Signature Hash: $hash');
      print('⚠️ Backend must include this hash in SMS: <#> $hash');
    } catch (e) {
      print('❌ Main: Failed to get app signature: $e');
      // Don't block app startup if hash retrieval fails
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

    // Listen to sponsorship code stream for deep link redemption
    _deepLinkService.sponsorshipCodeStream.listen((sponsorshipCode) {
      print('📱 Main: Sponsorship code received from deep link: $sponsorshipCode');
      if (mounted) {
        _handleSponsorshipCode(sponsorshipCode);
      }
    });

    // Listen to dealer invitation token stream
    _deepLinkService.dealerInvitationTokenStream.listen((token) {
      print('📱 Main: Dealer invitation token received from deep link: $token');
      if (mounted) {
        _handleDealerInvitationToken(token);
      }
    });

    // Listen to farmer invitation token stream
    _deepLinkService.farmerInvitationTokenStream.listen((token) {
      print('📱 Main: Farmer invitation token received from deep link: $token');
      if (mounted) {
        _handleFarmerInvitationToken(token);
      }
    });
  }

  /// Handle received referral code from deep link
  void _handleReferralCode(String referralCode) async {
    print('📱 Main: Referral code received from deep link: $referralCode');

    // Check if user is already logged in (has valid token)
    final tokenManager = getIt<TokenManager>();
    final accessToken = await tokenManager.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      print('⚠️ User already logged in, ignoring referral code');
      print('ℹ️ Referral codes can only be used during new user registration');
      return;
    }

    // Check if user has already used a referral code before
    final installReferrerService = getIt<InstallReferrerService>();
    final hasPendingCode = await installReferrerService.hasDeferredReferralCode();

    if (hasPendingCode) {
      print('ℹ️ User already has a pending referral code, not overwriting');
      return;
    }

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

    // Use pushReplacement to prevent back button returning to splash screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PhoneNumberScreen(
          isRegistration: true,
          referralCode: referralCode,
        ),
      ),
    );
  }

  /// Handle received sponsorship code from deep link
  void _handleSponsorshipCode(String sponsorshipCode) {
    print('📱 Main: Sponsorship code received from deep link: $sponsorshipCode');

    // Use navigator key to access context
    final context = navigatorKey.currentContext;
    if (context == null || !mounted) {
      print('⚠️ Navigator context not ready, will retry after delay');

      // Retry after a short delay to give MaterialApp time to initialize
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _handleSponsorshipCode(sponsorshipCode);
        }
      });
      return;
    }

    // Navigate directly to sponsorship redemption screen with code pre-filled
    print('🎯 Navigating to redemption screen with sponsorship code: $sponsorshipCode');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SponsorshipRedemptionScreen(
          autoFilledCode: sponsorshipCode,
        ),
      ),
    );
  }

  /// Handle received dealer invitation token from deep link
  void _handleDealerInvitationToken(String token) {
    print('📱 Main: Dealer invitation token received from deep link: $token');

    // Use navigator key to access context
    final context = navigatorKey.currentContext;
    if (context == null || !mounted) {
      print('⚠️ Navigator context not ready, will retry after delay');

      // Retry after a short delay to give MaterialApp time to initialize
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _handleDealerInvitationToken(token);
        }
      });
      return;
    }

    // Navigate directly to dealer invitation screen with token pre-filled
    print('🎯 Navigating to dealer invitation screen with token: $token');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DealerInvitationScreen(
          token: token,
        ),
      ),
    );
  }

  /// Handle received farmer invitation token from deep link
  void _handleFarmerInvitationToken(String token) {
    print('📱 Main: Farmer invitation token received from deep link: $token');

    // Use navigator key to access context
    final context = navigatorKey.currentContext;
    if (context == null || !mounted) {
      print('⚠️ Navigator context not ready, will retry after delay');

      // Retry after a short delay to give MaterialApp time to initialize
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _handleFarmerInvitationToken(token);
        }
      });
      return;
    }

    // Navigate directly to farmer invitation screen with token pre-filled
    print('🎯 Navigating to farmer invitation screen with token: $token');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FarmerInvitationScreen(
          invitationToken: token,
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