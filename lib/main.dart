import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'app/app_router.dart';
import 'app/app_theme.dart';
import 'core/utils/service_locator.dart';
import 'core/security/security_manager.dart';
import 'features/authentication/presentation/presentation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await setupServiceLocator();

  // Initialize security services
  await initializeSecurity();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for security
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Disable screenshots in production for security
  // This would typically be enabled only in production builds
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);

  runApp(const ZiraAIApp());
}

class ZiraAIApp extends StatefulWidget {
  const ZiraAIApp({super.key});

  @override
  State<ZiraAIApp> createState() => _ZiraAIAppState();
}

class _ZiraAIAppState extends State<ZiraAIApp> with WidgetsBindingObserver {
  late final SecurityManager _securityManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _securityManager = GetIt.instance<SecurityManager>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - record user activity
        _securityManager.recordUserActivity();
        break;
      case AppLifecycleState.paused:
        // App went to background - record time for session management
        _securityManager.recordUserActivity();
        break;
      case AppLifecycleState.inactive:
        // App became inactive (e.g., during phone call)
        break;
      case AppLifecycleState.detached:
        // App is being destroyed
        _cleanup();
        break;
      case AppLifecycleState.hidden:
        // App is hidden (newer Flutter versions)
        break;
    }
  }

  void _cleanup() {
    disposeSecurity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => GetIt.instance<AuthBloc>()
            ..add(const AuthCheckStatusRequested()),
        ),
      ],
      child: MaterialApp.router(
        title: 'ZiraAI',
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,

        // Localization with security-aware messages
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [
          Locale('tr', 'TR'), // Turkish (Primary for ZiraAI)
          Locale('en', 'US'), // English
          Locale('ar', 'SA'), // Arabic
        ],

        // Router configuration
        routerConfig: AppRouter.router,

        // Builder for global configurations and security
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Clamp text scale for security and consistency
              textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
            child: SecurityWrapper(
              child: child ?? const SizedBox(),
            ),
          );
        },
      ),
    );
  }
}

/// Security wrapper widget that handles app-level security features
class SecurityWrapper extends StatefulWidget {
  final Widget child;

  const SecurityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper> {
  late final SecurityManager _securityManager;
  bool _isSecurityInitialized = false;
  bool _showSecurityWarning = false;
  String _securityWarningMessage = '';

  @override
  void initState() {
    super.initState();
    _securityManager = GetIt.instance<SecurityManager>();
    _initializeSecurity();
  }

  Future<void> _initializeSecurity() async {
    try {
      // Check device security status
      final deviceStatus = await _securityManager.checkDeviceSecurityStatus();

      if (!deviceStatus.isSecure) {
        final highSeverityIssues = deviceStatus.issues
            .where((issue) => issue.severity == SecuritySeverity.high)
            .toList();

        if (highSeverityIssues.isNotEmpty) {
          setState(() {
            _showSecurityWarning = true;
            _securityWarningMessage = _buildSecurityWarningMessage(highSeverityIssues);
          });
        }
      }

      setState(() {
        _isSecurityInitialized = true;
      });
    } catch (e) {
      // Handle security initialization error
      setState(() {
        _showSecurityWarning = true;
        _securityWarningMessage = 'Güvenlik sistemi başlatılamadı. Lütfen uygulamayı yeniden başlatın.';
        _isSecurityInitialized = true;
      });
    }
  }

  String _buildSecurityWarningMessage(List<SecurityIssue> issues) {
    if (issues.length == 1) {
      return 'Güvenlik Uyarısı: ${issues.first.description}';
    } else {
      return 'Güvenlik Uyarısı: ${issues.length} güvenlik sorunu tespit edildi.';
    }
  }

  Widget _buildSecurityWarning() {
    return Material(
      child: Container(
        color: Colors.red.shade50,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.security,
                  color: Colors.red.shade700,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _securityWarningMessage,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showSecurityWarning = false;
                        });
                      },
                      child: const Text('Devam Et'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Uygulamayı Kapat'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSecurityInitialized) {
      // Show loading screen while security initializes
      return const Material(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Güvenlik sistemi başlatılıyor...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_showSecurityWarning) {
      return _buildSecurityWarning();
    }

    return widget.child;
  }
}