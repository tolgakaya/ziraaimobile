import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import 'otp_verification_screen.dart';

class PhoneNumberScreen extends StatefulWidget {
  final bool isRegistration;
  final String? referralCode;
  final String? initialPhone;

  const PhoneNumberScreen({
    super.key,
    this.isRegistration = false,
    this.referralCode,
    this.initialPhone,
  });

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _phoneError;
  bool _agreeToTerms = true; // Default olarak seçili

  @override
  void initState() {
    super.initState();
    // Use initialPhone if provided, otherwise leave empty
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _phoneError = _validatePhone(_phoneController.text);
    });

    if (_phoneError == null) {
      final phone = _phoneController.text.trim();
      // Get referral code from deep link if available
      final referralCode = widget.referralCode;

      if (widget.isRegistration) {
        context.read<AuthBloc>().add(
          PhoneRegisterOtpRequested(
            mobilePhone: phone,
            referralCode: referralCode,
          ),
        );
      } else {
        context.read<AuthBloc>().add(
          PhoneLoginOtpRequested(mobilePhone: phone),
        );
      }
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gerekli';
    }

    // Remove spaces and special characters for validation
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Turkish phone format: +90XXXXXXXXXX or 05XXXXXXXXX
    bool isValidFormat = RegExp(r'^\+90[1-9]\d{9}$').hasMatch(cleanPhone) ||
                        RegExp(r'^05\d{9}$').hasMatch(cleanPhone);

    if (!isValidFormat) {
      return 'Geçerli Türk telefon numarası girin (05XX XXX XX XX)';
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
          label: 'TAMAM',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://www.ziraai.com/privacy-policy');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          _showErrorSnackBar('Gizlilik politikası sayfası açılamadı');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Link açılırken bir hata oluştu');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Disable back button if user came from referral link
      canPop: widget.referralCode == null,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          // Hide back button if user came from referral link
          // This prevents returning to splash screen with referral code
          leading: widget.referralCode == null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
        body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PhoneOtpSent) {
            // Navigate to OTP verification screen
            // No BlocProvider needed - it will use the ancestor BlocProvider from main_simple.dart
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OtpVerificationScreen(
                  mobilePhone: state.mobilePhone,
                  isRegistration: state.isRegistration,
                  referralCode: widget.referralCode,
                ),
              ),
            );
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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

                      // Title and instructions
                      if (widget.isRegistration) ...[
                        // Registration instructions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF17CF17).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF17CF17).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.how_to_reg,
                                      color: Color(0xFF17CF17),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Hızlı Kayıt',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Kayıt olmak istediğiniz telefon numarasını aşağıdaki textboxa yazınız. Bir doğrulama SMS\'i göndereceğiz. Sonra ZiraAI\'yi rahatlıkla kullanabilirsiniz.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF374151),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ] else ...[
                        // Login title
                        const Text(
                          'Telefon ile Giriş',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Telefon numaranıza SMS ile doğrulama kodu göndereceğiz',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                      ],

                      // Referral info (only shown if coming from deep link)
                      if (widget.isRegistration && widget.referralCode != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF17CF17)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.card_giftcard,
                                color: Color(0xFF17CF17),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Davet koduyla kayıt oluyorsunuz',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.referralCode!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF17CF17),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Phone number input
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !isLoading,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Telefon numarası',
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
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-\(\)]')),
                          ],
                          onChanged: (_) {
                            if (_phoneError != null) {
                              setState(() => _phoneError = null);
                            }
                          },
                        ),
                      ),

                      // KVKK/Privacy Policy Checkbox (only for registration)
                      if (widget.isRegistration) ...[
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _agreeToTerms,
                                onChanged: isLoading ? null : (value) {
                                  setState(() {
                                    _agreeToTerms = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF17CF17),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _openPrivacyPolicy,
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF374151),
                                      height: 1.5,
                                    ),
                                    children: [
                                      TextSpan(text: 'Kayıt olarak '),
                                      TextSpan(
                                        text: 'KVKK/Gizlilik Politikası',
                                        style: TextStyle(
                                          color: Color(0xFF17CF17),
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: '\'nı kabul ediyorum.'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Submit button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: (widget.isRegistration && !_agreeToTerms)
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF17CF17),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: (widget.isRegistration && !_agreeToTerms)
                              ? []
                              : [
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
                            onTap: (isLoading || (widget.isRegistration && !_agreeToTerms))
                                ? null
                                : _validateAndSubmit,
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
                                  : Text(
                                      widget.isRegistration ? 'Kaydol' : 'Giriş Yap',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Switch between login and registration
                      if (!widget.isRegistration)
                        TextButton(
                          onPressed: isLoading ? null : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const PhoneNumberScreen(
                                  isRegistration: true,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                          ),
                          child: const Text(
                            'Hesabınız yok mu? Kayıt olun',
                            style: TextStyle(fontSize: 14),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: isLoading ? null : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const PhoneNumberScreen(
                                  isRegistration: false,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                          ),
                          child: const Text(
                            'Zaten hesabınız var mı? Giriş yapın',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}
