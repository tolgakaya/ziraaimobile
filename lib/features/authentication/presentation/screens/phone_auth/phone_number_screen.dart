import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final _referralCodeController = TextEditingController();
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    // Use initialPhone if provided, otherwise use default test phone
    _phoneController.text = widget.initialPhone ?? '+905551234567';
    // Pre-fill referral code if provided (from deep link)
    if (widget.referralCode != null) {
      _referralCodeController.text = widget.referralCode!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _phoneError = _validatePhone(_phoneController.text);
    });

    if (_phoneError == null) {
      final phone = _phoneController.text.trim();
      // Get referral code from text field (could be from deep link or manual entry)
      final referralCode = _referralCodeController.text.trim().isEmpty
          ? null
          : _referralCodeController.text.trim();

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
      return 'Geçerli Türk telefon numarası girin (+905XX XXX XX XX)';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRegistration ? 'Kayıt Ol' : 'Giriş Yap'),
        centerTitle: true,
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
                  developmentOtpCode: state.otpCode,
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Logo/Icon
                    Icon(
                      Icons.phone_android,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      widget.isRegistration ? 'Telefon ile Kayıt' : 'Telefon ile Giriş',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Telefon numaranıza SMS ile doğrulama kodu göndereceğiz',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Phone number input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Telefon Numarası',
                        hintText: '+90 5XX XXX XX XX',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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

                    // Referral code field (only for registration)
                    if (widget.isRegistration) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referralCodeController,
                        keyboardType: TextInputType.text,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Davet Kodu (Opsiyonel)',
                          hintText: 'ZIRA-XXXXXX',
                          prefixIcon: Icon(
                            Icons.card_giftcard,
                            color: _referralCodeController.text.isNotEmpty
                                ? Colors.green[700]
                                : null,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: _referralCodeController.text.isNotEmpty,
                          fillColor: _referralCodeController.text.isNotEmpty
                              ? Colors.green[50]
                              : null,
                          helperText: _referralCodeController.text.isNotEmpty
                              ? 'Kayıt olduğunuzda davet eden kişi kredi kazanacak'
                              : null,
                          helperStyle: TextStyle(color: Colors.green[700]),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Z0-9\-]')),
                          LengthLimitingTextInputFormatter(20),
                        ],
                        onChanged: (_) {
                          setState(() {}); // Refresh UI for color change
                        },
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit button
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
                              'Doğrulama Kodu Gönder',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),

                    const Spacer(),

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
                        child: const Text('Hesabınız yok mu? Kayıt olun'),
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
                        child: const Text('Zaten hesabınız var mı? Giriş yapın'),
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
