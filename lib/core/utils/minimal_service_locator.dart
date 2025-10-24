import 'package:dio/dio.dart';
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
import '../../features/authentication/data/services/phone_auth_api_service.dart';
import '../../features/referral/data/services/referral_api_service.dart';
import '../../features/referral/domain/repositories/referral_repository.dart';
import '../../features/referral/data/repositories/referral_repository_impl.dart';
import '../../features/referral/presentation/bloc/referral_bloc.dart';
import '../../features/sponsorship/data/services/sponsor_service.dart';
// import '../services/install_referrer_service.dart';  // TEMPORARILY DISABLED
import '../services/sms_referral_service.dart';
import '../../features/messaging/data/services/messaging_api_service.dart';
import '../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/domain/usecases/send_message_usecase.dart';
import '../../features/messaging/domain/usecases/get_messages_usecase.dart';
import '../../features/messaging/domain/usecases/send_message_with_attachments_usecase.dart';
import '../../features/messaging/domain/usecases/send_voice_message_usecase.dart';
import '../../features/messaging/domain/usecases/get_messaging_features_usecase.dart';
import '../../features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  // Deferred Deep Linking Services
  // Install Referrer TEMPORARILY DISABLED - using SMS solution instead
  // getIt.registerLazySingleton<InstallReferrerService>(
  //   () => InstallReferrerService(),
  // );

  getIt.registerLazySingleton<SmsReferralService>(
    () => SmsReferralService(),
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
    
    // Add TokenInterceptor for automatic authentication and token refresh
    // Pass dio instance for token refresh API calls
    dio.interceptors.add(_TokenInterceptor(getIt<TokenManager>(), dio));
    
    // Add LogInterceptor for debugging
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
    
    return dio;
  });
  
  getIt.registerLazySingleton<NetworkClient>(
    () => NetworkClient(getIt<Dio>()),
  );

  // API Services
  getIt.registerLazySingleton<PhoneAuthApiService>(
    () => PhoneAuthApiService(getIt<Dio>()),
  );

  getIt.registerLazySingleton<ReferralApiService>(
    () => ReferralApiService(getIt<Dio>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<NetworkClient>(),
      getIt<SecureStorageService>(),
      getIt<PhoneAuthApiService>(),
    ),
  );

  getIt.registerLazySingleton<ReferralRepository>(
    () => ReferralRepositoryImpl(
      getIt<ReferralApiService>(),
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

  // Sponsor service
  getIt.registerLazySingleton<SponsorService>(
    () => SponsorService(
      dio: getIt<Dio>(),
      authService: getIt<AuthService>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );

  getIt.registerFactory<ReferralBloc>(
    () => ReferralBloc(getIt<ReferralRepository>()),
  );

  // Notification bloc - Singleton
  getIt.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(),
  );

  // ✅ MESSAGING SERVICES - Required for sponsor-farmer messaging
  getIt.registerLazySingleton<MessagingApiService>(
    () => MessagingApiService(getIt<NetworkClient>()),
  );

  getIt.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(getIt<MessagingApiService>()),
  );

  getIt.registerLazySingleton<SendMessageUseCase>(
    () => SendMessageUseCase(getIt<MessagingRepository>()),
  );

  getIt.registerLazySingleton<GetMessagesUseCase>(
    () => GetMessagesUseCase(getIt<MessagingRepository>()),
  );

  getIt.registerLazySingleton<SendMessageWithAttachmentsUseCase>(
    () => SendMessageWithAttachmentsUseCase(getIt<MessagingRepository>()),
  );

  getIt.registerLazySingleton<SendVoiceMessageUseCase>(
    () => SendVoiceMessageUseCase(getIt<MessagingRepository>()),
  );

  getIt.registerLazySingleton<GetMessagingFeaturesUseCase>(
    () => GetMessagingFeaturesUseCase(getIt<MessagingRepository>()),
  );

  // ⚠️ TEMPORARY: Manual registration until app restart
  // Injectable auto-registration requires full app restart to load injection.config.dart
  // After restart, this can be removed as @injectable annotation will handle it
  getIt.registerFactory<MessagingBloc>(
    () => MessagingBloc(
      sendMessageUseCase: getIt<SendMessageUseCase>(),
      getMessagesUseCase: getIt<GetMessagesUseCase>(),
      sendMessageWithAttachmentsUseCase: getIt<SendMessageWithAttachmentsUseCase>(),
      sendVoiceMessageUseCase: getIt<SendVoiceMessageUseCase>(),
      getMessagingFeaturesUseCase: getIt<GetMessagingFeaturesUseCase>(),
    ),
  );

  print('✅ MESSAGING: All messaging services registered successfully!');

  // ✅ NOTIFICATIONS - FlutterLocalNotificationsPlugin for push notifications
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Android initialization settings
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  
  // iOS initialization settings
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  // Combined initialization settings
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  // Initialize the plugin
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('🔔 Notification tapped: ${response.payload}');
      // Handle notification tap - navigate to relevant screen
      // This will be implemented later for deep linking to message detail
    },
  );
  
  // Create notification channel for Android (required for Android 8.0+)
  const androidChannel = AndroidNotificationChannel(
    'sponsor_messages',
    'Sponsor Mesajları',
    description: 'Sponsorlardan gelen mesaj bildirimleri',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );
  
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);
  
  // Register as singleton
  getIt.registerSingleton<FlutterLocalNotificationsPlugin>(flutterLocalNotificationsPlugin);
  
  print('✅ NOTIFICATIONS: FlutterLocalNotificationsPlugin registered and initialized successfully!');
}

/// Token interceptor for automatic authentication and token refresh
class _TokenInterceptor extends Interceptor {
  final TokenManager _tokenManager;
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_RequestRetry> _retryQueue = [];

  _TokenInterceptor(this._tokenManager, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login/register/refresh endpoints
    if (_isAuthEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    // Get valid access token
    final token = await _tokenManager.getValidAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print('🔑 TokenInterceptor: Added auth token to ${options.path}');
      handler.next(options);
    } else {
      print('⚠️ TokenInterceptor: No valid token, skipping auth header for ${options.path}');
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if error is 401 Unauthorized
    if (err.response?.statusCode == 401) {
      print('🔑 TokenInterceptor: 401 Unauthorized - attempting token refresh');

      // Don't retry auth endpoints
      if (_isAuthEndpoint(err.requestOptions.path)) {
        print('⚠️ TokenInterceptor: Auth endpoint failed, not retrying');
        handler.next(err);
        return;
      }

      // If already refreshing, queue this request
      if (_isRefreshing) {
        print('🔄 TokenInterceptor: Token refresh in progress, queueing request');
        _retryQueue.add(_RequestRetry(
          requestOptions: err.requestOptions,
          handler: handler,
        ));
        return;
      }

      // Start token refresh
      _isRefreshing = true;

      try {
        // Get refresh token
        final refreshToken = await _tokenManager.getRefreshToken();
        
        if (refreshToken == null) {
          print('❌ TokenInterceptor: No refresh token available');
          _isRefreshing = false;
          _clearRetryQueue(err);
          handler.next(err);
          return;
        }

        print('🔄 TokenInterceptor: Refreshing token...');

        // Call refresh token endpoint
        final response = await _dio.post(
          ApiConfig.refreshToken,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final newAccessToken = response.data['data']['accessToken'];
          final newRefreshToken = response.data['data']['refreshToken'];

          // Save new tokens
          await _tokenManager.saveToken(newAccessToken);
          await _tokenManager.saveRefreshToken(newRefreshToken);

          print('✅ TokenInterceptor: Token refreshed successfully');

          // Retry the original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          
          final retryResponse = await _dio.fetch(err.requestOptions);
          
          _isRefreshing = false;
          
          // Process retry queue
          _processRetryQueue(newAccessToken);
          
          handler.resolve(retryResponse);
        } else {
          print('❌ TokenInterceptor: Token refresh failed');
          _isRefreshing = false;
          _clearRetryQueue(err);
          handler.next(err);
        }
      } catch (refreshError) {
        print('❌ TokenInterceptor: Token refresh error: $refreshError');
        _isRefreshing = false;
        _clearRetryQueue(err);
        
        // Clear tokens on refresh failure (user needs to login again)
        await _tokenManager.clearTokens();
        
        handler.next(err);
      }
    } else {
      // Not a 401 error, pass through
      handler.next(err);
    }
  }

  /// Process queued requests after successful token refresh
  void _processRetryQueue(String newAccessToken) async {
    print('🔄 TokenInterceptor: Processing ${_retryQueue.length} queued requests');
    
    for (final retry in _retryQueue) {
      try {
        retry.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final response = await _dio.fetch(retry.requestOptions);
        retry.handler.resolve(response);
      } catch (e) {
        retry.handler.reject(
          DioException(
            requestOptions: retry.requestOptions,
            error: e,
          ),
        );
      }
    }
    
    _retryQueue.clear();
  }

  /// Clear retry queue on refresh failure
  void _clearRetryQueue(DioException error) {
    print('❌ TokenInterceptor: Clearing ${_retryQueue.length} queued requests');
    
    for (final retry in _retryQueue) {
      retry.handler.reject(error);
    }
    
    _retryQueue.clear();
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
           path.contains('/auth/register') ||
           path.contains('/auth/refresh-token') ||
           path.contains('/auth/forgot-password');
  }
}

/// Helper class to store retry request info
class _RequestRetry {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _RequestRetry({
    required this.requestOptions,
    required this.handler,
  });
}