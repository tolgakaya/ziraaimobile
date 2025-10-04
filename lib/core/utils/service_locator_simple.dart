import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../network/network_client.dart';
import '../security/biometric_service.dart';
import '../security/security_manager.dart';

import '../security/token_manager.dart';
import '../storage/secure_storage_service.dart';
import '../storage/storage_service.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Core services
  getIt.registerLazySingleton<StorageService>(
    () => StorageService(getIt<SharedPreferences>()),
  );
  
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
  

  
  getIt.registerLazySingleton<TokenManager>(
    () => TokenManager(getIt<SecureStorageService>()),
  );
  
  getIt.registerLazySingleton<BiometricService>(
    () => BiometricService(
      localAuth: LocalAuthentication(),
      secureStorage: getIt<SecureStorageService>(),
    ),
  );
  
  getIt.registerLazySingleton<SecurityManager>(
    () => SecurityManager(
      secureStorage: getIt<SecureStorageService>(),
      biometricService: getIt<BiometricService>(),
      tokenManager: getIt<TokenManager>(),
    ),
  );

  // Network
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    ));
    
    // Add interceptors
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
    
    return dio;
  });
  
  getIt.registerLazySingleton<NetworkClient>(
    () => NetworkClient(getIt<Dio>()),
  );

  // Repositories - removed, will use injectable auto-registration

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );
}