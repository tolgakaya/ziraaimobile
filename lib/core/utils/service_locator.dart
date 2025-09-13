import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  ));

  // Core
  sl.registerLazySingleton(() => Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
      headers: {
        'Content-Type': ApiConstants.contentType,
      },
    ),
  ));

  sl.registerLazySingleton<LocalStorage>(() => LocalStorageImpl(sl()));
  sl.registerLazySingleton<SecureStorage>(() => SecureStorageImpl(sl()));
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // Features will be registered here
  // Authentication
  // _initAuth();

  // Plant Analysis
  // _initPlantAnalysis();

  // Sponsorship
  // _initSponsorship();

  // Profile
  // _initProfile();
}

// Future<void> _initAuth() async {
//   // Repositories
//   sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
//     apiClient: sl(),
//     localStorage: sl(),
//     secureStorage: sl(),
//   ));

//   // Use cases
//   sl.registerLazySingleton(() => LoginUseCase(sl()));
//   sl.registerLazySingleton(() => RegisterUseCase(sl()));
//   sl.registerLazySingleton(() => LogoutUseCase(sl()));

//   // BLoC
//   sl.registerFactory(() => AuthBloc(
//     loginUseCase: sl(),
//     registerUseCase: sl(),
//     logoutUseCase: sl(),
//   ));
// }