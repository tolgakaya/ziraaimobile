import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  String? _emailError;
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
    });

    if (_emailError == null) {
      context.read<AuthBloc>().add(
            AuthResetPasswordRequested(email: _emailController.text.trim()),
          );
    }
  }

  void _resendEmail() {
    context.read<AuthBloc>().add(
          AuthResetPasswordRequested(email: _emailController.text.trim()),
        );
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

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSent) {
          setState(() {
            _isEmailSent = true;
          });
        } else if (state is AuthFailure) {
          _showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: colorScheme.onSurface,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Şifre Sıfırla',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Content based on state
                if (!_isEmailSent) ...[
                  _buildResetPasswordForm(),
                ] else ...[
                  _buildEmailSentContent(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetPasswordForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset,
            size: 40,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Şifrenizi mi unuttunuz?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Description
        Text(
          'Endişelenmeyin! E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Form
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Email Field
              AuthTextField(
                label: 'E-posta',
                hint: 'Kayıtlı e-posta adresiniz',
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
              const SizedBox(height: 32),

              // Reset Button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return AuthButton(
                    text: 'Sıfırlama Bağlantısı Gönder',
                    onPressed: isLoading ? null : _resetPassword,
                    isLoading: isLoading,
                    type: AuthButtonType.primary,
                    size: AuthButtonSize.large,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Back to Login
              AuthButton(
                text: 'Giriş sayfasına dön',
                onPressed: () => context.go('/login'),
                type: AuthButtonType.text,
                size: AuthButtonSize.medium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSentContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read,
            size: 40,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),

        // Success Title
        Text(
          'E-posta Gönderildi!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Success Description
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Şifre sıfırlama bağlantısı '),
              TextSpan(
                text: _emailController.text.trim(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const TextSpan(text: ' adresine gönderildi. '),
              const TextSpan(text: 'E-posta kutunuzu kontrol edin.'),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sonraki adımlar:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInstructionItem(
                '1. E-posta kutunuzu kontrol edin',
                theme,
                colorScheme,
              ),
              _buildInstructionItem(
                '2. "Şifreyi Sıfırla" bağlantısına tıklayın',
                theme,
                colorScheme,
              ),
              _buildInstructionItem(
                '3. Yeni şifrenizi belirleyin',
                theme,
                colorScheme,
              ),
              _buildInstructionItem(
                '4. Yeni şifrenizle giriş yapın',
                theme,
                colorScheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Action Buttons
        Column(
          children: [
            // Resend Email
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return AuthButton(
                  text: 'E-postayı Tekrar Gönder',
                  onPressed: isLoading ? null : _resendEmail,
                  isLoading: isLoading,
                  type: AuthButtonType.outline,
                  size: AuthButtonSize.large,
                  icon: const Icon(Icons.refresh, size: 18),
                );
              },
            ),
            const SizedBox(height: 16),

            // Back to Login
            AuthButton(
              text: 'Giriş sayfasına dön',
              onPressed: () => context.go('/login'),
              type: AuthButtonType.text,
              size: AuthButtonSize.medium,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Help Text
        Container(
          padding: const EdgeInsets.all(12),
          child: Text(
            'E-posta gelmedi mi? Spam klasörünü kontrol edin veya birkaç dakika bekleyin.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(
    String text,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }
}