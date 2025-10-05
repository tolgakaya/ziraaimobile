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
import '../../../../../core/services/auth_service.dart';
import '../../../../dashboard/presentation/bloc/notification_bloc.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String mobilePhone;
  final bool isRegistration;
  final String? referralCode;
  final String? developmentOtpCode; // For development environment

  const OtpVerificationScreen({
    super.key,
    required this.mobilePhone,
    required this.isRegistration,
    this.referralCode,
    this.developmentOtpCode,
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

  @override
  void initState() {
    super.initState();
    _startResendCountdown();

    // Auto-fill OTP in development
    if (widget.developmentOtpCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoFillOtp(widget.developmentOtpCode!);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _autoFillOtp(String otp) {
    if (otp.length == 6) {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = otp[i];
      }
    }
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

        final notificationBloc = GetIt.instance<NotificationBloc>();
        final integration = SignalRNotificationIntegration(
          signalRService: signalRService,
          notificationBloc: notificationBloc,
        );
        integration.setupEventHandlers();

        print('✅ Phone Auth: SignalR initialized and integrated successfully');
      }
    } catch (e) {
      print('❌ Phone Auth: SignalR initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doğrulama Kodu'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            // Initialize SignalR after successful authentication
            await _initializeSignalRAfterAuth();

            // Navigate to dashboard
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const FarmerDashboardPage(),
                ),
                (route) => false,
              );
            }
          } else if (state is PhoneOtpSent) {
            // OTP resent successfully
            if (state.otpCode != null) {
              _autoFillOtp(state.otpCode!);
            }
          } else if (state is AuthError) {
            _showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // Icon
                  Icon(
                    Icons.message,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Kodu Girin',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Subtitle with phone number
                  Text(
                    '${widget.mobilePhone} numarasına gönderilen 6 haneli kodu girin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (widget.developmentOtpCode != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'DEV: ${widget.developmentOtpCode}',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 45,
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
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
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
                  ElevatedButton(
                    onPressed: isLoading ? null : _validateAndSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Doğrula',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Kod almadınız mı? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (_canResend)
                        TextButton(
                          onPressed: isLoading ? null : _resendOtp,
                          child: const Text('Tekrar Gönder'),
                        )
                      else
                        Text(
                          '($_resendCountdown sn)',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Change phone number
                  TextButton(
                    onPressed: isLoading ? null : () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Telefon numarasını değiştir'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
