import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/utils/minimal_service_locator.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/screens/splash_screen.dart';
import 'core/services/signalr_service.dart';
import 'core/services/deep_link_service.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupMinimalServiceLocator();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SignalRService _signalRService = SignalRService();
  final DeepLinkService _deepLinkService = DeepLinkService();
  StreamSubscription<String>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't initialize SignalR here - SplashScreen handles auto-login and SignalR

    // Initialize deep link service
    _deepLinkService.initialize();
    _deepLinkSubscription = _deepLinkService.deepLinkStream?.listen((link) {
      print('📱 Main: Deep link received: $link');
      // Handle deep link in current context
      if (mounted) {
        DeepLinkService.handleDeepLink(context, link);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Reconnect SignalR when app resumes (if user is authenticated)
    if (state == AppLifecycleState.resumed) {
      if (!_signalRService.isConnected) {
        print('🔄 App resumed: Attempting to reconnect SignalR...');
        // SignalR will be reconnected automatically if token is valid
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _signalRService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZiraAI Mobile',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => GetIt.instance<AuthBloc>(),
        child: const SplashScreen(), // Start with SplashScreen for auto-login
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}