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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Simplified lifecycle management - no security manager for now
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      ),
    );
  }
}

