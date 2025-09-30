import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../network/network_client.dart';
import '../storage/secure_storage_service.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/plant_analysis/domain/repositories/plant_analysis_repository.dart';
import '../../features/plant_analysis/data/repositories/plant_analysis_repository_impl.dart';
import '../../features/plant_analysis/data/services/plant_analysis_api_service.dart';
import '../services/auth_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupSimpleDI() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Dio
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: ApiConfig.defaultHeaders,
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    return dio;
  });

  // Network client
  getIt.registerLazySingleton<NetworkClient>(() => NetworkClient(getIt()));

  // Secure storage
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  // Auth repository
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt(), getIt()));

  // Auth service
  getIt.registerLazySingleton<AuthService>(() => AuthServiceImpl(getIt()));

  // Plant Analysis API service
  getIt.registerLazySingleton<PlantAnalysisApiService>(() => PlantAnalysisApiService(getIt<Dio>()));

  // Plant Analysis repository - Interface to implementation
  getIt.registerLazySingleton<PlantAnalysisRepository>(
    () => PlantAnalysisRepositoryImpl(
      getIt<PlantAnalysisApiService>(),
      getIt<AuthService>(),
    ),
  );

  // Auth bloc
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt()));
}