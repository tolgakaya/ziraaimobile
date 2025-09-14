import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/simple_injection.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';

class AuthRouter {

  static List<RouteBase> get routes => [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<AuthBloc>(),
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<AuthBloc>(),
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<AuthBloc>(),
        child: const ForgotPasswordScreen(),
      ),
    ),
  ];
}

class AuthGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    // Check authentication state from BlocProvider
    final authState = context.read<AuthBloc>().state;
    final isAuthenticated = authState is AuthAuthenticated;

    final isGoingToAuth = state.uri.toString().startsWith('/login') ||
                         state.uri.toString().startsWith('/register') ||
                         state.uri.toString().startsWith('/forgot-password');

    // If not authenticated and not going to auth page, redirect to login
    if (!isAuthenticated && !isGoingToAuth) {
      return '/login';
    }

    // If authenticated and going to auth page, redirect to home
    if (isAuthenticated && isGoingToAuth) {
      return '/home';
    }

    // No redirect needed
    return null;
  }
}

// Extension to make navigation easier
extension AuthNavigation on BuildContext {
  void goToLogin() => go('/login');
  void goToRegister() => go('/register');
  void goToForgotPassword() => go('/forgot-password');
  void goToHome() => go('/home');

  void pushLogin() => push('/login');
  void pushRegister() => push('/register');
  void pushForgotPassword() => push('/forgot-password');
}