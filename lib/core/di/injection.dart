import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
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
import '../../features/messaging/data/services/messaging_api_service.dart';
import '../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/domain/usecases/send_message_usecase.dart';
import '../../features/messaging/domain/usecases/get_messages_usecase.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
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
      tokenManager: getIt<TokenManager>(),
      biometricService: getIt<BiometricService>(),
    ),
  );

  // Network
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
      // CRITICAL: Remove any response size limits
      maxRedirects: 5,
      // Ensure we can receive large responses
      receiveDataWhenStatusError: true,
    ));

    // Add custom interceptor for debugging response size
    dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        final responseString = response.toString();
        print('🌾 FULL RESPONSE LENGTH: ${responseString.length} characters');
        print('🌾 RESPONSE DATA TYPE: ${response.data.runtimeType}');

        if (response.data is Map) {
          final jsonString = response.data.toString();
          print('🌾 RESPONSE MAP LENGTH: ${jsonString.length} characters');

          // Check for specific fields
          final dataMap = response.data as Map<String, dynamic>;
          if (dataMap.containsKey('data')) {
            final dataObject = dataMap['data'];
            print('🌾 DATA OBJECT TYPE: ${dataObject.runtimeType}');
            if (dataObject is Map) {
              print('🌾 DATA OBJECT KEYS: ${(dataObject as Map).keys.toList()}');

              // Check for farmerFriendlySummary specifically
              if (dataObject.containsKey('farmerFriendlySummary')) {
                print('✅ farmerFriendlySummary FOUND in data object!');
                print('🌾 farmerFriendlySummary: ${dataObject['farmerFriendlySummary']}');
              } else {
                print('❌ farmerFriendlySummary NOT FOUND in data object');
                print('🌾 Available keys in data: ${dataObject.keys.toList()}');
              }
            }
          }
        }

        handler.next(response);
      },
      onError: (error, handler) {
        print('🚨 DIO ERROR: ${error.message}');
        print('🚨 ERROR TYPE: ${error.type}');
        if (error.response != null) {
          print('🚨 ERROR RESPONSE LENGTH: ${error.response.toString().length}');
        }
        handler.next(error);
      },
    ));

    // Add LogInterceptor with no limits
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      error: true,
    ));

    return dio;
  });

  getIt.registerLazySingleton<NetworkClient>(
    () => NetworkClient(getIt<Dio>()),
  );

  // Repositories - will be auto-registered by injectable
  // Manual registration removed to use @injectable annotation

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );

  // Run injectable code generation - MUST be awaited
  await getIt.init();

  // ✅ MESSAGING SERVICES FIX - Ensure they are registered
  // Injectable might not register them properly, so we check and add if needed
  if (!getIt.isRegistered<MessagingApiService>()) {
    getIt.registerLazySingleton<MessagingApiService>(
      () => MessagingApiService(getIt<NetworkClient>()),
    );
  }

  if (!getIt.isRegistered<MessagingRepository>()) {
    getIt.registerLazySingleton<MessagingRepository>(
      () => MessagingRepositoryImpl(getIt<MessagingApiService>()),
    );
  }

  if (!getIt.isRegistered<SendMessageUseCase>()) {
    getIt.registerLazySingleton<SendMessageUseCase>(
      () => SendMessageUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetMessagesUseCase>()) {
    getIt.registerLazySingleton<GetMessagesUseCase>(
      () => GetMessagesUseCase(getIt<MessagingRepository>()),
    );
  }

  print('🔍 POST-INIT: MessagingApiService registered: ${getIt.isRegistered<MessagingApiService>()}');
  print('🔍 POST-INIT: MessagingRepository registered: ${getIt.isRegistered<MessagingRepository>()}');
  print('🔍 POST-INIT: SendMessageUseCase registered: ${getIt.isRegistered<SendMessageUseCase>()}');
  print('🔍 POST-INIT: GetMessagesUseCase registered: ${getIt.isRegistered<GetMessagesUseCase>()}');
}
