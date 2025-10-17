import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'phone_auth/phone_number_screen.dart';
import 'phone_auth/otp_verification_screen.dart';
import '../../../dashboard/presentation/pages/farmer_dashboard_page.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/services/signalr_notification_integration.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sponsorship_sms_listener.dart';
import '../../../dashboard/presentation/bloc/notification_bloc.dart';
import '../../../sponsorship/presentation/screens/farmer/sponsorship_redemption_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  String? _phoneError;

  // Screen mode: 'login' or 'register'
  String _screenMode = 'login';

  @override
  void initState() {
    super.initState();
    // Default test phone for development
    _phoneController.text = '05551234567';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validateAndLogin() {
    // Validate phone and request OTP
    setState(() {
      _phoneError = _validatePhone(_phoneController.text);
    });

    if (_phoneError == null) {
      final phone = _phoneController.text.trim();

      // Dispatch OTP request event
      context.read<AuthBloc>().add(
        PhoneLoginOtpRequested(mobilePhone: phone),
      );
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gerekli';
    }

    // Remove spaces, dashes, parentheses
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Turkish phone validation: +90 5XX XXX XX XX or 05XX XXX XX XX
    final withCountryCode = RegExp(r'^\+90[5][0-9]{9}$');
    final withoutCountryCode = RegExp(r'^0[5][0-9]{9}$');

    if (!withCountryCode.hasMatch(cleanPhone) && !withoutCountryCode.hasMatch(cleanPhone)) {
      return 'Geçerli bir Türk telefon numarası girin';
    }

    return null;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _initializeSignalRAfterLogin() async {
    try {
      final authService = GetIt.instance<AuthService>();
      final token = await authService.getToken();

      if (token != null && token.isNotEmpty) {
        print('🔌 Login: Initializing SignalR after successful login...');

        final signalRService = SignalRService();
        await signalRService.initialize(token);

        // Setup SignalR notification integration
        final notificationBloc = GetIt.instance<NotificationBloc>();
        final integration = SignalRNotificationIntegration(
          signalRService: signalRService,
          notificationBloc: notificationBloc,
        );
        integration.setupEventHandlers();

        print('✅ Login: SignalR initialized and connected!');
      }
    } catch (e) {
      print('❌ Login: Failed to initialize SignalR: $e');
      // Don't block login flow if SignalR fails
    }
  }

  /// Check for pending sponsorship code from SMS after login
  /// If code exists and not expired, navigate to redemption screen
  Future<void> _checkPendingSponsorshipCode() async {
    try {
      print('[Login] 🔍 Checking for pending sponsorship code...');

      final pendingCode = await SponsorshipSmsListener.checkPendingCode();

      if (pendingCode != null && mounted) {
        print('[Login] ✅ Found pending code: $pendingCode');

        // Clear from storage
        await SponsorshipSmsListener.clearPendingCode();

        // Small delay to let dashboard initialize first
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate to redemption screen with auto-filled code
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SponsorshipRedemptionScreen(
                autoFilledCode: pendingCode,
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
        }
      } else {
        print('[Login] ℹ️ No pending sponsorship code found');
      }
    } catch (e) {
      print('[Login] ❌ Error checking pending code: $e');
      // Don't block login flow if this fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          // Initialize SignalR after successful login
          await _initializeSignalRAfterLogin();

          // Check for pending sponsorship code from SMS
          await _checkPendingSponsorshipCode();

          // Navigate to dashboard on successful login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const FarmerDashboardPage(),
            ),
          );
        } else if (state is PhoneOtpSent) {
          // Navigate to OTP verification screen
          final authBloc = GetIt.instance<AuthBloc>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: authBloc,
                child: OtpVerificationScreen(
                  mobilePhone: state.mobilePhone,
                  isRegistration: state.isRegistration,
                  developmentOtpCode: state.otpCode,
                ),
              ),
            ),
          );
        } else if (state is AuthError) {
          _showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  
                  // Header Section - Matching design exactly
                  _buildHeader(),

                  const SizedBox(height: 32),

                  // Form Section
                  _buildForm(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // ZiraAI Logo
        Image.asset(
          'assets/logos/ziraai_logo.png',
          height: 160,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to text if image fails to load
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

        // Tab Navigation - Login / Register (iOS Segmented Control Style)
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              Expanded(child: _buildSegmentButton('Giriş Yap', 'login')),
              Expanded(child: _buildSegmentButton('Kayıt Ol', 'register')),
            ],
          ),
        ),
      ],
    );
  }

  // iOS-style Segmented Control Button
  Widget _buildSegmentButton(String label, String mode) {
    final isActive = _screenMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _screenMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phone input for login
          if (_screenMode == 'login')
            ..._buildPhoneInput()
          // Register navigation
          else if (_screenMode == 'register')
            ..._buildRegisterOptions(),

          if (_screenMode == 'login') const SizedBox(height: 32),

          // Login Button (only for login mode)
          if (_screenMode == 'login')
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return Container(
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
                      onTap: isLoading ? null : _validateAndLogin,
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
                                'Giriş',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Register Options - Navigate to phone registration screen
  List<Widget> _buildRegisterOptions() {
    // Navigate to phone registration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PhoneNumberScreen(
              isRegistration: true,
            ),
          ),
        ).then((_) {
          // Return to login mode after registration screen is closed
          if (mounted) {
            setState(() {
              _screenMode = 'login';
            });
          }
        });
      }
    });

    return [
      Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.phone_android,
              size: 48,
              color: Color(0xFF17CF17),
            ),
            const SizedBox(height: 16),
            const Text(
              'Telefon ile kayıt olun',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildPhoneInput() {
    return [
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: '05XX XXX XX XX',
            hintStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
            prefixIcon: const Icon(
              Icons.phone_android,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorText: _phoneError,
          ),
          onChanged: (value) {
            if (_phoneError != null) {
              setState(() {
                _phoneError = _validatePhone(value);
              });
            }
          },
        ),
      ),
    ];
  }


}