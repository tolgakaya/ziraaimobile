import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

class SponsorLoginScreen extends StatefulWidget {
  const SponsorLoginScreen({super.key});

  @override
  State<SponsorLoginScreen> createState() => _SponsorLoginScreenState();
}

class _SponsorLoginScreenState extends State<SponsorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndLogin() {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });

    if (_emailError == null && _passwordError == null) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Navigate to sponsor dashboard - will implement routing later
          _showErrorSnackBar('Sponsor login successful! Navigation pending...');
        } else if (state is AuthFailure) {
          _showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header with back button
              _buildHeader(),
              
              // Main content - centered
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        
                        // Logo and Title Section
                        _buildLogoSection(),
                        
                        const SizedBox(height: 48),
                        
                        // Login Form
                        _buildForm(),
                        
                        const SizedBox(height: 32),
                        
                        // Social Login Section
                        _buildSocialLogin(),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Back button
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: Color(0xFF57534E), // stone-600
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // ZiraAI Logo - Circular with darker green
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFF0F766E), // Teal-700 from design
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'ZirAI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Title
        const Text(
          'Sponsor Login',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C1917), // stone-900
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        const Text(
          'Welcome back, please enter your details.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF78716C), // stone-500
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
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
          // Email/Phone Input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAF9), // stone-50
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE7E5E4)), // stone-200
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1C1917), // stone-900
              ),
              decoration: InputDecoration(
                hintText: 'Email or Phone',
                hintStyle: const TextStyle(
                  color: Color(0xFF78716C), // stone-500
                  fontSize: 16,
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
              color: const Color(0xFFFAFAF9), // stone-50
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE7E5E4)), // stone-200
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1C1917), // stone-900
              ),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(
                  color: Color(0xFF78716C), // stone-500
                  fontSize: 16,
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
          
          const SizedBox(height: 16),
          
          // Remember Me and Forgot Password Row
          Row(
            children: [
              // Remember Me Checkbox
              Row(
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF22C55E), // green-500
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
                        color: Color(0xFF57534E), // stone-600
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Forgot Password Link
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to forgot password
                  _showErrorSnackBar('Forgot password functionality pending...');
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF16A34A), // green-600
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Login Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              
              return Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E), // green-500
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
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
                              'Log in',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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

  Widget _buildSocialLogin() {
    return Column(
      children: [
        // Divider with "Or continue with"
        Row(
          children: [
            const Expanded(
              child: Divider(color: Color(0xFFE7E5E4)), // stone-200
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF78716C), // stone-500
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: Color(0xFFE7E5E4)), // stone-200
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Social Login Buttons
        Row(
          children: [
            // Facebook Button
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE7E5E4)), // stone-200
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      _showErrorSnackBar('Facebook login not implemented');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.facebook,
                          size: 20,
                          color: Color(0xFF44403C), // stone-700
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Facebook',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF44403C), // stone-700
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Google Button
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE7E5E4)), // stone-200
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      _showErrorSnackBar('Google login not implemented');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.g_translate,
                          size: 20,
                          color: Color(0xFF44403C), // stone-700
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF44403C), // stone-700
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF57534E), // stone-600
            ),
            children: [
              const TextSpan(text: "Don't have an account? "),
              TextSpan(
                text: 'Sign up',
                style: const TextStyle(
                  color: Color(0xFF16A34A), // green-600
                  fontWeight: FontWeight.w500,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // TODO: Navigate to sponsor registration
                    _showErrorSnackBar('Sponsor registration pending...');
                  },
              ),
            ],
          ),
        ),
      ),
    );
  }
}