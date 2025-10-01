import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../network/network_client.dart';
import '../storage/secure_storage_service.dart';
import '../storage/storage_service.dart';
import '../security/token_manager.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/plant_analysis/domain/repositories/plant_analysis_repository.dart';
import '../../features/plant_analysis/data/repositories/plant_analysis_repository_impl.dart';
import '../../features/plant_analysis/data/services/plant_analysis_api_service.dart';
import '../services/auth_service.dart';
import '../../features/subscription/services/subscription_service.dart';
import '../../features/dashboard/presentation/bloc/notification_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupMinimalServiceLocator() async {
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

  // Token management
  getIt.registerLazySingleton<TokenManager>(
    () => TokenManager(getIt<SecureStorageService>()),
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

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<NetworkClient>(),
      getIt<SecureStorageService>(),
    ),
  );

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

  // Subscription service - Real API implementation
  getIt.registerLazySingleton<SubscriptionService>(
    () => SubscriptionService(
      getIt<NetworkClient>(),
      getIt<SecureStorageService>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );

  // Notification bloc - Singleton
  getIt.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(),
  );
}