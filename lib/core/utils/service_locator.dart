import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';
import '../security/token_manager.dart';
import '../security/biometric_service.dart';
import '../security/security_manager.dart';
import '../security/secure_network_service.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/authentication/domain/usecases/login_user.dart';
import '../../features/authentication/domain/usecases/register_user.dart';
import '../../features/authentication/domain/usecases/logout_user.dart';
import '../../features/authentication/domain/usecases/get_current_user.dart';
import '../../features/authentication/domain/usecases/reset_password.dart';
import '../../features/authentication/domain/usecases/validate_session.dart';
import '../../features/authentication/domain/usecases/authenticate_with_biometrics.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'ziraai_secure_prefs',
      preferencesKeyPrefix: 'ziraai_',
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.ziraai.mobile',
      accountName: 'ZiraAI',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  ));

  sl.registerLazySingleton(() => LocalAuthentication());
  sl.registerLazySingleton(() => Connectivity());

  // Core services
  _initCore();

  // Security services
  _initSecurity();

  // Features
  _initAuth();
}

void _initCore() {
  // Dio instance for API client
  sl.registerLazySingleton(() => Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
      headers: {
        'Content-Type': ApiConstants.contentType,
        'User-Agent': 'ZiraAI-Mobile/1.0.0',
      },
    ),
  ));

  // Storage services
  sl.registerLazySingleton<LocalStorage>(() => LocalStorageImpl(sl()));
  sl.registerLazySingleton<SecureStorage>(() => SecureStorageImpl.withSecureOptions());

  // API client
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));
}

void _initSecurity() {
  // Token manager
  sl.registerLazySingleton<TokenManager>(() => TokenManager(sl()));

  // Biometric service
  sl.registerLazySingleton<BiometricService>(() => BiometricService(
    localAuth: sl(),
    secureStorage: sl(),
  ));

  // Secure network service
  sl.registerLazySingleton<SecureNetworkService>(() => SecureNetworkService(
    tokenManager: sl(),
    connectivity: sl(),
  ));

  // Security manager (central security controller)
  sl.registerLazySingleton<SecurityManager>(() => SecurityManager(
    secureStorage: sl(),
    tokenManager: sl(),
    biometricService: sl(),
  ));
}

void _initAuth() {
  // Repository - removed, will use injectable auto-registration

  // Use cases
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => ResetPassword(sl()));
  sl.registerLazySingleton(() => ValidateSession(sl()));
  sl.registerLazySingleton(() => AuthenticateWithBiometrics(sl()));

  // BLoC
  sl.registerFactory(() => AuthBloc(sl()));
}

/// Initialize security services at app startup
Future<void> initializeSecurity() async {
  final securityManager = sl<SecurityManager>();
  await securityManager.initialize();
}

/// Dispose security resources when app is closing
void disposeSecurity() {
  if (sl.isRegistered<SecurityManager>()) {
    final securityManager = sl<SecurityManager>();
    securityManager.dispose();
  }

  if (sl.isRegistered<TokenManager>()) {
    final tokenManager = sl<TokenManager>();
    tokenManager.dispose();
  }

  if (sl.isRegistered<SecureNetworkService>()) {
    final networkService = sl<SecureNetworkService>();
    networkService.dispose();
  }
}