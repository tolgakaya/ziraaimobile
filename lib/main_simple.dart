import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/utils/minimal_service_locator.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/screens/login_screen.dart';
import 'core/services/signalr_service.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't initialize SignalR here - wait for user to login first
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Reconnect SignalR when app resumes (if user is authenticated)
    if (state == AppLifecycleState.resumed) {
      if (!_signalRService.isConnected) {
        print('🔄 App resumed: Attempting to reconnect SignalR...');
        // SignalR will be reconnected via login screen if authenticated
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
        child: const LoginScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}