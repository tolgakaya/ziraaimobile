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
      onError: (error, handler) async {
        print('🚨 DIO ERROR: ${error.message}');
        print('🚨 ERROR TYPE: ${error.type}');
        
        // Handle 401 Unauthorized - Token expired
        if (error.response?.statusCode == 401) {
          print('🔄 Token expired (401), attempting refresh...');
          
          try {
            // Get fresh token from secure storage
            final secureStorage = getIt<SecureStorageService>();
            final refreshToken = await secureStorage.getRefreshToken();
            
            if (refreshToken != null) {
              print('✅ Refresh token found, refreshing access token...');
              
              // Create a new dio instance to avoid interceptor recursion
              final refreshDio = Dio(BaseOptions(
                baseUrl: ApiConfig.apiBaseUrl,
              ));
              
              // Call refresh token endpoint
              final refreshResponse = await refreshDio.post(
                '/api/v1/auth/refresh-token',
                data: {'refreshToken': refreshToken},
              );
              
              if (refreshResponse.statusCode == 200 && 
                  refreshResponse.data['success'] == true) {
                final newAccessToken = refreshResponse.data['data']['accessToken'];
                final newRefreshToken = refreshResponse.data['data']['refreshToken'];
                
                // Save new tokens
                await secureStorage.saveToken(newAccessToken);
                await secureStorage.saveRefreshToken(newRefreshToken);
                
                print('✅ Token refreshed successfully, retrying original request...');
                
                // Retry original request with new token
                final options = Options(
                  method: error.requestOptions.method,
                  headers: {
                    ...error.requestOptions.headers,
                    'Authorization': 'Bearer $newAccessToken',
                  },
                );
                
                final response = await dio.request(
                  error.requestOptions.path,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                  options: options,
                );
                
                return handler.resolve(response);
              }
            }
            
            print('❌ Token refresh failed, returning error');
          } catch (e) {
            print('❌ Token refresh exception: $e');
          }
        }
        
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
}
