import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../../../dashboard/presentation/pages/farmer_dashboard_page.dart';
import '../../../../../core/services/signalr_service.dart';
import '../../../../../core/services/signalr_notification_integration.dart';
import '../../../../../core/services/notification_signalr_service.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../dashboard/presentation/bloc/notification_bloc.dart';
import '../../../../../core/services/sponsorship_sms_listener.dart';
// ✅ REMOVED: dealer_invitation_sms_listener - no longer used (switched to backend API)
import '../../../../sponsorship/presentation/screens/farmer/sponsorship_redemption_screen.dart';
import '../../../../dealer/presentation/screens/pending_invitations_screen.dart';
import '../../../../dealer/data/dealer_api_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../../core/services/otp_sms_listener.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String mobilePhone;
  final bool isRegistration;
  final String? referralCode;

  const OtpVerificationScreen({
    super.key,
    required this.mobilePhone,
    required this.isRegistration,
    this.referralCode,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String? _otpError;
  int _resendCountdown = 60;
  bool _canResend = false;
  StreamSubscription<String>? _otpSmsSubscription;
  final _otpSmsListener = OtpSmsListener();

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    _initializeOtpSmsListener();
  }

  @override
  void dispose() {
    _otpSmsSubscription?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Initialize OTP SMS listener and subscribe to auto-fill stream
  Future<void> _initializeOtpSmsListener() async {
    try {
      print('[OTP_SCREEN] 🎧 Initializing OTP SMS auto-fill...');

      // Initialize listener (will request SMS permission if needed)
      await _otpSmsListener.initialize();

      // Subscribe to OTP code stream
      _otpSmsSubscription = _otpSmsListener.otpCodeStream.listen((otpCode) {
        print('[OTP_SCREEN] 📱 Received OTP code from SMS: $otpCode');
        _autoFillOtp(otpCode);
      });

      // Also check recent SMS for codes (in case SMS arrived before screen opened)
      final recentCode = await _otpSmsListener.checkRecentSmsForOtp();
      if (recentCode != null && mounted) {
        print('[OTP_SCREEN] 📱 Found OTP in recent SMS: $recentCode');
        _autoFillOtp(recentCode);
      }

      print('[OTP_SCREEN] ✅ OTP SMS auto-fill initialized');
    } catch (e) {
      print('[OTP_SCREEN] ❌ Failed to initialize OTP SMS listener: $e');
    }
  }

  /// Auto-fill OTP fields with received code
  void _autoFillOtp(String otpCode) {
    if (!mounted) return;

    // Clear any error
    setState(() => _otpError = null);

    // Fill each digit into corresponding field
    for (int i = 0; i < otpCode.length && i < 6; i++) {
      _otpControllers[i].text = otpCode[i];
    }

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Doğrulama kodu SMS\'den otomatik dolduruldu',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // Auto-submit after brief delay (let user see the auto-fill)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _validateAndSubmit();
      }
    });
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
        }
      });

      return _resendCountdown > 0;
    });
  }

  void _validateAndSubmit() {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() {
        _otpError = '6 haneli kodu tam girin';
      });
      return;
    }

    final otpCode = int.tryParse(otp);
    if (otpCode == null) {
      setState(() {
        _otpError = 'Geçersiz kod formatı';
      });
      return;
    }

    setState(() => _otpError = null);

    if (widget.isRegistration) {
      context.read<AuthBloc>().add(
        PhoneRegisterOtpVerifyRequested(
          mobilePhone: widget.mobilePhone,
          code: otpCode,
          referralCode: widget.referralCode,
        ),
      );
    } else {
      context.read<AuthBloc>().add(
        PhoneLoginOtpVerifyRequested(
          mobilePhone: widget.mobilePhone,
          code: otpCode,
        ),
      );
    }
  }

  void _resendOtp() {
    if (!_canResend) return;

    if (widget.isRegistration) {
      context.read<AuthBloc>().add(
        PhoneRegisterOtpRequested(
          mobilePhone: widget.mobilePhone,
          referralCode: widget.referralCode,
        ),
      );
    } else {
      context.read<AuthBloc>().add(
        PhoneLoginOtpRequested(mobilePhone: widget.mobilePhone),
      );
    }

    _startResendCountdown();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yeni doğrulama kodu gönderildi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'TAMAM',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _initializeSignalRAfterAuth() async {
    try {
      final authService = GetIt.instance<AuthService>();
      final token = await authService.getToken();

      if (token != null && token.isNotEmpty) {
        print('🔌 Phone Auth: Initializing SignalR after successful authentication...');

        final signalRService = SignalRService();
        await signalRService.initialize(token);

        // ✅ Initialize NotificationHub for dealer invitations
        print('🔔 Phone Auth: Initializing NotificationHub for dealer invitations...');
        final notificationHubService = GetIt.instance<NotificationSignalRService>();
        await notificationHubService.initialize(token);
        print('✅ Phone Auth: NotificationHub initialized successfully');

        final notificationBloc = GetIt.instance<NotificationBloc>();
        final localNotifications = GetIt.instance<FlutterLocalNotificationsPlugin>();
        final integration = SignalRNotificationIntegration(
          signalRService: signalRService,
          notificationHubService: notificationHubService,
          notificationBloc: notificationBloc,
          localNotifications: localNotifications,
        );
        integration.setupEventHandlers();

        print('✅ Phone Auth: SignalR and NotificationHub integrated successfully');
      }
    } catch (e) {
      print('❌ Phone Auth: SignalR initialization error: $e');
    }
  }

  /// Check for pending sponsorship code from SMS after authentication
  /// Returns the pending code if found (will be handled after dashboard navigation)
  Future<String?> _checkPendingSponsorshipCode() async {
    try {
      print('[OTP] 🔍 Checking for pending sponsorship code...');

      final pendingCode = await SponsorshipSmsListener.checkPendingCode();

      if (pendingCode != null) {
        print('[OTP] ✅ Found pending code: $pendingCode');
        // Clear from storage
        await SponsorshipSmsListener.clearPendingCode();
        return pendingCode;
      } else {
        print('[OTP] ℹ️ No pending sponsorship code found');
        return null;
      }
    } catch (e) {
      print('[OTP] ❌ Error checking pending code: $e');
      return null;
    }
  }

  /// ✅ UPDATED: Check backend API for pending dealer invitations after authentication
  /// Returns true if pending invitations found (will navigate to PendingInvitationsScreen)
  /// Returns false if no invitations (caller should proceed to dashboard)
  Future<bool> _checkPendingDealerInvitationsAfterAuth() async {
    try {
      print('[OTP] 🔍 Checking backend for pending dealer invitations...');

      // ✅ NEW: Call backend API to get pending invitations
      final dealerApi = GetIt.instance<DealerApiService>();
      final invitations = await dealerApi.getMyPendingInvitations();

      if (invitations.isNotEmpty) {
        print('[OTP] ✅ Found ${invitations.length} pending dealer invitation(s)');
        return true; // ✅ Signal caller to navigate to PendingInvitationsScreen instead of dashboard
      } else {
        print('[OTP] ℹ️ No pending dealer invitations found');
        return false; // Proceed to dashboard normally
      }
    } catch (e) {
      print('[OTP] ❌ Error fetching dealer invitations from backend: \$e');
      return false; // Don't block login flow if this fails
    }
  }

  /// Navigate to redemption screen after dashboard is ready
  void _navigateToRedemption(String code) {
    // Wait for dashboard to be fully initialized
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      print('[OTP] 🧭 Navigating to redemption screen with code: $code');

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SponsorshipRedemptionScreen(
            autoFilledCode: code,
          ),
        ),
      );

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            // Initialize SignalR after successful authentication
            await _initializeSignalRAfterAuth();

            // Check for pending sponsorship code from SMS
            final pendingCode = await _checkPendingSponsorshipCode();

            // ✅ NEW: Check backend API for pending dealer invitations
            final hasPendingInvitations = await _checkPendingDealerInvitationsAfterAuth();

            // Navigate to dashboard with pending dealer invitations flag
            if (mounted) {
              print('[OTP] 🧭 Navigating to dashboard (hasPendingInvitations: $hasPendingInvitations)');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => FarmerDashboardPage(
                    pendingSponsorshipCode: pendingCode,
                    hasPendingDealerInvitations: hasPendingInvitations,
                  ),
                ),
                (route) => false,
              );
            }
          } else if (state is PhoneOtpSent) {
            // OTP resent successfully
            // No auto-fill since OTP is sent via real SMS service
          } else if (state is AuthError) {
            _showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // ZiraAI Logo
                    Image.asset(
                      'assets/logos/ziraai_logo.png',
                      height: 160,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'ZiraAI',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Slogan
                    const Text(
                      'Akıllı ziraatçi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Title
                    const Text(
                      'Doğrulama Kodu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Subtitle with phone number
                    Text(
                      '${widget.mobilePhone} numarasına gönderilen 6 haneli kodu girin',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 48),

                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 45,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
                            enabled: !isLoading,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              if (_otpError != null) {
                                setState(() => _otpError = null);
                              }

                              if (value.isNotEmpty && index < 5) {
                                _otpFocusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _otpFocusNodes[index - 1].requestFocus();
                              }

                              // Auto-submit when all fields filled
                              if (index == 5 && value.isNotEmpty) {
                                final allFilled = _otpControllers.every(
                                  (c) => c.text.isNotEmpty,
                                );
                                if (allFilled) {
                                  _validateAndSubmit();
                                }
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_otpError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _otpError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Verify button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF17CF17),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF17CF17).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: isLoading ? null : _validateAndSubmit,
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Doğrula',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Kod almadınız mı? ',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      if (_canResend)
                        TextButton(
                          onPressed: isLoading ? null : _resendOtp,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF17CF17),
                          ),
                          child: const Text(
                            'Tekrar Gönder',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Text(
                          '($_resendCountdown sn)',
                          style: const TextStyle(
                            color: Color(0xFF17CF17),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Change phone number
                  TextButton(
                    onPressed: isLoading ? null : () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                    ),
                    child: const Text(
                      'Telefon numarasını değiştir',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }
}
