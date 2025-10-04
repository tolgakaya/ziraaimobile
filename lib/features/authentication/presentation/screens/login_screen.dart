import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_screen.dart';
import 'phone_auth/phone_number_screen.dart';
import '../../../dashboard/presentation/pages/farmer_dashboard_page.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/services/signalr_notification_integration.dart';
import '../../../../core/services/auth_service.dart';
import '../../../dashboard/presentation/bloc/notification_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  String? _phoneError;

  // Login mode: 'phone' or 'email' - DEFAULT is PHONE
  String _loginMode = 'phone';

  @override
  void initState() {
    super.initState();
    // Default test credentials for development (only for email mode)
    _emailController.text = 'farmer61@example.com';
    _passwordController.text = 'SecurePass123!';
    // Default test phone for development
    _phoneController.text = '+905551234567';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validateAndLogin() {
    if (_loginMode == 'phone') {
      // Validate phone and navigate to OTP screen
      setState(() {
        _phoneError = _validatePhone(_phoneController.text);
      });

      if (_phoneError == null) {
        // Navigate to PhoneNumberScreen with pre-filled phone
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => GetIt.instance<AuthBloc>(),
              child: PhoneNumberScreen(
                isRegistration: false,
                initialPhone: _phoneController.text.trim(),
              ),
            ),
          ),
        );
      }
    } else {
      // Email/password login
      setState(() {
        _emailError = _validateEmail(_emailController.text);
        _passwordError = _validatePassword(_passwordController.text);
      });

      if (_emailError == null && _passwordError == null) {
        context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email or Phone is required';
    }
    // Accept both email and phone
    bool isEmail = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value);
    bool isPhone = RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
    
    if (!isEmail && !isPhone) {
      return 'Enter valid email or phone';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          // Initialize SignalR after successful login
          await _initializeSignalRAfterLogin();

          // Navigate to dashboard on successful login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const FarmerDashboardPage(),
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
                  
                  const SizedBox(height: 80),
                  
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
        // ZiraAI Logo - Dark green circular background
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFF2D5A41), // Dark green from design
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.eco, // Plant/leaf icon
            color: Color(0xFF17CF17), // Green icon color
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        
        // ZiraAI Title
        const Text(
          'ZiraAI',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111811),
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 8),
        
        // Welcome Message
        const Text(
          'Welcome back, Farmer!',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Login Mode Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModeButton('Telefon ile', 'phone'),
              const SizedBox(width: 12),
              _buildModeButton('Email ile', 'email'),
            ],
          ),

          const SizedBox(height: 24),

          // Conditional inputs based on login mode
          if (_loginMode == 'phone') ..._buildPhoneInput()
          else ..._buildEmailPasswordInputs(),

          const SizedBox(height: 16),

          // Remember Me and Forgot Password Row (only for email mode)
          if (_loginMode == 'email')
            Row(
              children: [
                // Remember Me Checkbox
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF17CF17),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _rememberMe = !_rememberMe;
                    });
                  },
                  child: const Text(
                    'Remember me',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),

                const Spacer(),

                // Forgot Password Link
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to forgot password
                    _showErrorSnackBar('Forgot password functionality pending...');
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF17CF17),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 32),

          // Login Button
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
                          : Text(
                              _loginMode == 'phone' ? 'Kod Gönder' : 'Login',
                              style: const TextStyle(
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

          const SizedBox(height: 24),

          // Register Link
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: 'Register',
                    style: const TextStyle(
                      color: Color(0xFF17CF17),
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => GetIt.instance<AuthBloc>(),
                              child: const RegisterScreen(),
                            ),
                          ),
                        );
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, String mode) {
    final isActive = _loginMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _loginMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF17CF17) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFF17CF17) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
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
            hintText: '+90 5XX XXX XX XX',
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

  List<Widget> _buildEmailPasswordInputs() {
    return [
      // Email Input
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
            prefixIcon: const Icon(
              Icons.alternate_email,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorText: _emailError,
          ),
          onChanged: (value) {
            if (_emailError != null) {
              setState(() {
                _emailError = _validateEmail(value);
              });
            }
          },
        ),
      ),

      const SizedBox(height: 16),

      // Password Input
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorText: _passwordError,
          ),
          onChanged: (value) {
            if (_passwordError != null) {
              setState(() {
                _passwordError = _validatePassword(value);
              });
            }
          },
        ),
      ),
    ];
  }

}