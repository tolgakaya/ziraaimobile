import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
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
      return 'E-posta adresi gerekli';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
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
          label: 'Tamam',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Navigate to main app
          context.go('/home');
        } else if (state is AuthFailure) {
          _showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: mediaQuery.size.height -
                    mediaQuery.padding.top -
                    mediaQuery.padding.bottom -
                    keyboardHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Logo and Title Section
                    _buildHeaderSection(),

                    const SizedBox(height: 48),

                    // Login Form
                    _buildLoginForm(),

                    const SizedBox(height: 32),

                    // Action Buttons
                    _buildActionButtons(),

                    const SizedBox(height: 24),

                    // Social Login Options
                    _buildSocialLoginSection(),

                    const SizedBox(height: 32),

                    // Footer Links
                    _buildFooterLinks(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // ZiraAI Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.agriculture,
            size: 40,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          'ZiraAI',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Tarımsal analiz platformuna hoş geldiniz',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          AuthTextField(
            label: 'E-posta',
            hint: 'ornek@email.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _emailError,
            onChanged: (value) {
              if (_emailError != null) {
                setState(() {
                  _emailError = _validateEmail(value);
                });
              }
            },
          ),
          const SizedBox(height: 20),

          // Password Field
          AuthTextField(
            label: 'Şifre',
            hint: 'Şifrenizi girin',
            controller: _passwordController,
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outlined),
            errorText: _passwordError,
            onChanged: (value) {
              if (_passwordError != null) {
                setState(() {
                  _passwordError = _validatePassword(value);
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Remember Me and Forgot Password Row
          Row(
            children: [
              // Remember Me Checkbox
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: Text(
                          'Beni hatırla',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Forgot Password Link
              TextButton(
                onPressed: () {
                  context.push('/forgot-password');
                },
                child: Text(
                  'Şifremi unuttum',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Login Button
            LoginButton(
              onPressed: isLoading ? null : _validateAndLogin,
              isLoading: isLoading,
            ),
            const SizedBox(height: 16),

            // Register Navigation Button
            AuthButton(
              text: 'Hesabınız yok mu? Kayıt olun',
              onPressed: () {
                context.push('/register');
              },
              type: AuthButtonType.text,
              size: AuthButtonSize.medium,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialLoginSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Divider with "veya" text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: colorScheme.outline.withOpacity(0.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'veya',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: colorScheme.outline.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Google Sign In Button
        GoogleSignInButton(
          onPressed: () {
            // TODO: Implement Google Sign In
            _showErrorSnackBar('Google ile giriş henüz kullanılamıyor');
          },
        ),
      ],
    );
  }

  Widget _buildFooterLinks() {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        TextButton(
          onPressed: () {
            // TODO: Show terms of service
          },
          child: Text(
            'Kullanım Koşulları',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Text(
          '•',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Show privacy policy
          },
          child: Text(
            'Gizlilik Politikası',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}