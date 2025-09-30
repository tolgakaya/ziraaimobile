import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'app/app_router.dart';
import 'app/app_theme.dart';
import 'core/di/simple_injection.dart';
// import 'core/security/security_manager.dart';
import 'features/authentication/presentation/presentation.dart';
import 'features/authentication/presentation/bloc/auth_event.dart';
import 'core/services/signalr_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/signalr_notification_integration.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await setupSimpleDI();

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
  final SignalRService _signalRService = SignalRService();
  SignalRNotificationIntegration? _signalRIntegration;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSignalR();
  }
  
  Future<void> _initializeSignalR() async {
    try {
      final authService = getIt<AuthService>();
      final token = await authService.getToken();
      
      if (token != null && token.isNotEmpty) {
        await _signalRService.initialize(token);
        _setupSignalRIntegration();
        developer.log('SignalR initialized successfully', name: 'MainApp');
      } else {
        developer.log('No auth token available, skipping SignalR init', name: 'MainApp');
      }
    } catch (e) {
      developer.log('Failed to initialize SignalR: $e', name: 'MainApp', error: e);
    }
  }
  
  void _setupSignalRIntegration() {
    if (_signalRIntegration == null) {
      // Import AppRouter to access the static notification bloc
      final notificationBloc = AppRouter.notificationBloc;
      _signalRIntegration = SignalRNotificationIntegration(
        signalRService: _signalRService,
        notificationBloc: notificationBloc,
      );
      _signalRIntegration!.setupEventHandlers();
      developer.log('SignalR integration setup complete', name: 'MainApp');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle SignalR connection lifecycle
    if (state == AppLifecycleState.paused) {
      developer.log('App paused - SignalR will auto-reconnect', name: 'MainApp');
    } else if (state == AppLifecycleState.resumed) {
      developer.log('App resumed', name: 'MainApp');
      
      // Check SignalR connection and reconnect if needed
      if (!_signalRService.isConnected) {
        developer.log('SignalR disconnected, attempting to reconnect', name: 'MainApp');
        _initializeSignalR();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _signalRIntegration?.clearEventHandlers();
    _signalRService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()
            ..add(const AuthCheckStatusRequested()),
        ),
      ],
      child: Builder(
        builder: (context) {
          // This Builder ensures that the child has access to the providers
          return MaterialApp.router(
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

            // Builder for global configurations
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  // Clamp text scale for consistency
                  textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
                ),
                child: child ?? const SizedBox(),
              );
            },
          );
        },
      ),
    );
  }
}

