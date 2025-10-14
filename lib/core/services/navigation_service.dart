import 'package:flutter/material.dart';

/// Global navigation service for app-wide navigation without context
/// Useful for services that need to navigate (SMS listeners, notifications, etc.)
class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey;

  NavigationService(this.navigatorKey);

  /// Get current navigator context
  BuildContext? get currentContext => navigatorKey.currentContext;

  /// Check if navigator is ready
  bool get isReady => currentContext != null;

  /// Navigate to a new route
  Future<T?>? navigateTo<T>(Widget screen) {
    final context = currentContext;
    if (context == null) {
      print('⚠️ NavigationService: Context not ready');
      return null;
    }

    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Navigate and replace current route
  Future<T?>? navigateAndReplace<T>(Widget screen) {
    final context = currentContext;
    if (context == null) {
      print('⚠️ NavigationService: Context not ready');
      return null;
    }

    return Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Navigate and remove all previous routes
  Future<T?>? navigateAndRemoveUntil<T>(Widget screen) {
    final context = currentContext;
    if (context == null) {
      print('⚠️ NavigationService: Context not ready');
      return null;
    }

    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  /// Pop current route
  void pop<T>([T? result]) {
    final context = currentContext;
    if (context == null) {
      print('⚠️ NavigationService: Context not ready');
      return;
    }

    Navigator.of(context).pop<T>(result);
  }

  /// Check if can pop
  bool canPop() {
    final context = currentContext;
    if (context == null) return false;
    return Navigator.of(context).canPop();
  }
}
