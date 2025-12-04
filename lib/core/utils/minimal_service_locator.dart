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
import '../../features/payment/services/payment_service.dart';
import '../../features/dashboard/presentation/bloc/notification_bloc.dart';
import '../../features/authentication/data/services/phone_auth_api_service.dart';
import '../../features/referral/data/services/referral_api_service.dart';
import '../../features/referral/domain/repositories/referral_repository.dart';
import '../../features/referral/data/repositories/referral_repository_impl.dart';
import '../../features/referral/presentation/bloc/referral_bloc.dart';
import '../../features/sponsorship/data/services/sponsor_service.dart';
// import '../services/install_referrer_service.dart';  // TEMPORARILY DISABLED
import '../services/sms_referral_service.dart';
import '../services/sponsorship_sms_listener.dart';
import '../../features/messaging/data/services/messaging_api_service.dart';
import '../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/domain/usecases/send_message_usecase.dart';
import '../../features/messaging/domain/usecases/get_messages_usecase.dart';
import '../../features/messaging/domain/usecases/send_message_with_attachments_usecase.dart';
import '../../features/messaging/domain/usecases/send_voice_message_usecase.dart';
import '../../features/messaging/domain/usecases/get_messaging_features_usecase.dart';
import '../../features/messaging/domain/usecases/mark_message_as_read_usecase.dart';
import '../../features/messaging/domain/usecases/mark_messages_as_read_usecase.dart';
import '../../features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../../features/dealer/data/dealer_api_service.dart';
import '../../features/dealer/presentation/screens/pending_invitations_screen.dart';
import '../services/notification_signalr_service.dart';
import '../services/navigation_service.dart';
import '../services/permission_service.dart';
import '../services/location_service.dart';
import '../../features/profile/data/services/farmer_profile_api_service.dart';
import '../../features/profile/data/repositories/farmer_profile_repository_impl.dart';
import '../../features/profile/domain/repositories/farmer_profile_repository.dart';
import '../../features/profile/presentation/bloc/farmer_profile_bloc.dart';
import '../../features/support/domain/repositories/support_ticket_repository.dart';
import '../../features/support/data/repositories/support_ticket_repository_impl.dart';
import '../../features/support/data/services/support_ticket_api_service.dart';
import '../../features/support/presentation/bloc/support_ticket_bloc.dart';
import '../../features/support/data/services/app_info_api_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupMinimalServiceLocator() async {

  // ✅ SIGNALR NOTIFICATION HUB - Singleton for /hubs/notification
  getIt.registerLazySingleton<NotificationSignalRService>(
    () => NotificationSignalRService(),
  );

  print('✅ SIGNALR: NotificationSignalRService registered successfully!');
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

  // ✅ PERMISSION SERVICE - Centralized permission management to prevent crashes
  getIt.registerLazySingleton<PermissionService>(
    () => PermissionService(),
  );

  print('✅ PERMISSIONS: PermissionService registered successfully!');

  // ✅ LOCATION SERVICE - GPS location detection for plant analysis
  getIt.registerLazySingleton<LocationService>(
    () => LocationService(),
  );

  print('✅ LOCATION: LocationService registered successfully!');

  // Deferred Deep Linking Services
  // Install Referrer TEMPORARILY DISABLED - using SMS solution instead
  // getIt.registerLazySingleton<InstallReferrerService>(
  //   () => InstallReferrerService(),
  // );

  getIt.registerLazySingleton<SmsReferralService>(
    () => SmsReferralService(),
  );

  // ✅ SPONSORSHIP SMS LISTENER - Real-time SMS code detection
  // Required for automatic sponsorship code extraction from SMS
  getIt.registerLazySingleton<SponsorshipSmsListener>(
    () => SponsorshipSmsListener(),
  );

  print('✅ SMS: SmsReferralService and SponsorshipSmsListener registered successfully!');

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
      // Allow 401 responses to pass through to TokenInterceptor
      // This prevents Dio from throwing an exception before the interceptor can handle token refresh
      validateStatus: (status) {
        return status != null && (status < 400 || status == 401);
      },
    ));
    
    // Add TokenInterceptor for automatic authentication and token refresh
    // Pass dio instance for token refresh API calls
    dio.interceptors.add(_TokenInterceptor(getIt<TokenManager>(), dio));

    // Add response transformer for empty/text responses
    dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        // Handle empty or non-JSON responses for update endpoints
        if (response.requestOptions.method == 'PUT' ||
            response.requestOptions.method == 'PATCH') {
          if (response.data == null || response.data == '') {
            // Empty response - treat as success
            response.data = {'success': true, 'message': 'Updated'};
          } else if (response.data is String && response.data.toString().trim() == 'Updated') {
            // Plain text "Updated" response
            response.data = {'success': true, 'message': 'Updated'};
          }
        }
        handler.next(response);
      },
    ));

    // Add LogInterceptor for debugging
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('🌐 DIO: $obj'),
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
      getIt<Dio>(),
    ),
  );

  // Subscription service - Real API implementation
  getIt.registerLazySingleton<SubscriptionService>(
    () => SubscriptionService(
      getIt<NetworkClient>(),
      getIt<SecureStorageService>(),
    ),
  );

  // Payment service - iyzico integration
  getIt.registerLazySingleton<PaymentService>(
    () => PaymentService(
      dio: getIt<Dio>(),
      secureStorage: getIt<SecureStorageService>(),
      baseUrl: ApiConfig.apiBaseUrl,
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

  getIt.registerLazySingleton<MarkMessageAsReadUseCase>(
    () => MarkMessageAsReadUseCase(getIt<MessagingRepository>()),
  );

  getIt.registerLazySingleton<MarkMessagesAsReadUseCase>(
    () => MarkMessagesAsReadUseCase(getIt<MessagingRepository>()),
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
      markMessageAsReadUseCase: getIt<MarkMessageAsReadUseCase>(),
      markMessagesAsReadUseCase: getIt<MarkMessagesAsReadUseCase>(),
    ),
  );

  print('✅ MESSAGING: All messaging services registered successfully!');

  // ✅ FARMER PROFILE - API Service, Repository, BLoC
  getIt.registerLazySingleton<FarmerProfileApiService>(
    () => FarmerProfileApiService(getIt<Dio>()),
  );

  getIt.registerLazySingleton<FarmerProfileRepository>(
    () => FarmerProfileRepositoryImpl(getIt<FarmerProfileApiService>()),
  );

  getIt.registerFactory<FarmerProfileBloc>(
    () => FarmerProfileBloc(repository: getIt<FarmerProfileRepository>()),
  );

  print('✅ FARMER PROFILE: All profile services registered successfully!');

  // ✅ SUPPORT TICKET - API Service, Repository, BLoC
  getIt.registerLazySingleton<SupportTicketApiService>(
    () => SupportTicketApiService(getIt<NetworkClient>()),
  );

  getIt.registerLazySingleton<SupportTicketRepository>(
    () => SupportTicketRepositoryImpl(getIt<SupportTicketApiService>()),
  );

  getIt.registerFactory<SupportTicketBloc>(
    () => SupportTicketBloc(repository: getIt<SupportTicketRepository>()),
  );

  print('✅ SUPPORT TICKET: All support services registered successfully!');

  // ✅ APP INFO - API Service for About Us page
  getIt.registerLazySingleton<AppInfoApiService>(
    () => AppInfoApiService(getIt<NetworkClient>()),
  );

  print('✅ APP INFO: App info service registered successfully!');

  // ✅ DEALER INVITATION API SERVICE
  getIt.registerLazySingleton<DealerApiService>(
    () => DealerApiService(getIt<NetworkClient>()),
  );

  print('✅ DEALER: Dealer API service registered successfully!');

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
      print('🔔 Notification tapped: \${response.payload}');
      
      // Handle different notification types based on payload
      final payload = response.payload;
      if (payload != null) {
        if (payload.startsWith('dealer_invitation_')) {
          // Dealer invitation notification tapped
          print('🔔 Dealer invitation notification tapped, navigating to PendingInvitationsScreen');
          // Navigation will be handled by main.dart's NavigatorKey
          _handleDealerInvitationTap(payload);
        } else if (payload.startsWith('message_')) {
          // Message notification tapped
          print('🔔 Message notification tapped: \$payload');
          // Handle message navigation (existing functionality)
        }
      }
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
  final List<_QueuedRequest> _requestQueue = [];

  _TokenInterceptor(this._tokenManager, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login/register/refresh endpoints
    if (_isAuthEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    // Get current token (even if expired)
    final currentToken = await _tokenManager.getToken();

    if (currentToken == null) {
      print('⚠️ TokenInterceptor: No token available for ${options.path}');
      handler.next(options);
      return;
    }

    // Check if token is expired
    if (_tokenManager.isTokenExpired(currentToken)) {
      print('🔑 TokenInterceptor: Token expired, need refresh for ${options.path}');

      // If already refreshing, queue this request
      if (_isRefreshing) {
        print('🔄 TokenInterceptor: Refresh in progress, queueing request to ${options.path}');
        _requestQueue.add(_QueuedRequest.fromRequest(
          requestOptions: options,
          requestHandler: handler,
        ));
        return; // Don't call handler.next() - will be handled after refresh
      }

      // Start token refresh
      _isRefreshing = true;

      try {
        final refreshToken = await _tokenManager.getRefreshToken();

        if (refreshToken == null || refreshToken.isEmpty) {
          print('❌ TokenInterceptor: No refresh token available');
          _isRefreshing = false;
          handler.next(options);
          return;
        }

        // Check if refresh token is expired
        final isRefreshTokenExpired = await _tokenManager.isRefreshTokenExpired();
        if (isRefreshTokenExpired) {
          print('❌ TokenInterceptor: Refresh token is expired - clearing tokens');
          _isRefreshing = false;
          await _tokenManager.clearTokens();
          handler.next(options);
          return;
        }

        print('🔄 TokenInterceptor: Refreshing token proactively...');

        // Call refresh token endpoint
        final response = await _dio.post(
          ApiConfig.refreshToken,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final newAccessToken = response.data['data']['token'];  // Backend returns 'token', not 'accessToken'
          final newRefreshToken = response.data['data']['refreshToken'];
          final refreshTokenExpiration = response.data['data']['refreshTokenExpiration'];

          // Save new tokens
          await _tokenManager.saveToken(newAccessToken);
          await _tokenManager.saveRefreshToken(newRefreshToken);

          // Save refresh token expiration if available
          if (refreshTokenExpiration != null) {
            await _tokenManager.saveRefreshTokenExpiration(refreshTokenExpiration);
          }

          print('✅ TokenInterceptor: Token refreshed proactively');

          // Add new token to current request
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          print('🔑 TokenInterceptor: Added new token to ${options.path}');

          _isRefreshing = false;

          // Process all queued requests before continuing with current one
          _processQueuedRequests(newAccessToken);

          handler.next(options);
        } else {
          print('❌ TokenInterceptor: Proactive token refresh failed');
          _isRefreshing = false;
          _clearRequestQueue(DioException(
            requestOptions: options,
            error: 'Token refresh failed',
          ));
          // Don't continue - refresh failed, user needs to login
          await _tokenManager.clearTokens();
          handler.reject(DioException(
            requestOptions: options,
            error: 'Authentication failed, please login again',
          ));
        }
      } catch (refreshError) {
        print('❌ TokenInterceptor: Proactive refresh error: $refreshError');
        _isRefreshing = false;
        _clearRequestQueue(DioException(
          requestOptions: options,
          error: refreshError,
        ));
        // Don't continue - refresh failed, user needs to login
        await _tokenManager.clearTokens();
        handler.reject(DioException(
          requestOptions: options,
          error: refreshError,
        ));
      }
    } else {
      // Token is valid, use it
      options.headers['Authorization'] = 'Bearer $currentToken';
      print('🔑 TokenInterceptor: Added valid token to ${options.path}');
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
        print('🔄 TokenInterceptor: Token refresh in progress, queueing 401 request');
        _requestQueue.add(_QueuedRequest.fromError(
          requestOptions: err.requestOptions,
          errorHandler: handler,
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
          await _tokenManager.clearTokens();
          _clearRequestQueue(err);
          handler.next(err);
          return;
        }

        // Check if refresh token is expired
        final isRefreshTokenExpired = await _tokenManager.isRefreshTokenExpired();
        if (isRefreshTokenExpired) {
          print('❌ TokenInterceptor: Refresh token is expired - clearing tokens');
          _isRefreshing = false;
          await _tokenManager.clearTokens();
          _clearRequestQueue(err);
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
          final newAccessToken = response.data['data']['token'];  // Backend returns 'token', not 'accessToken'
          final newRefreshToken = response.data['data']['refreshToken'];
          final refreshTokenExpiration = response.data['data']['refreshTokenExpiration'];

          // Save new tokens
          await _tokenManager.saveToken(newAccessToken);
          await _tokenManager.saveRefreshToken(newRefreshToken);

          // Save refresh token expiration if available
          if (refreshTokenExpiration != null) {
            await _tokenManager.saveRefreshTokenExpiration(refreshTokenExpiration);
          }

          print('✅ TokenInterceptor: Token refreshed successfully');

          // Retry the original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          
          final retryResponse = await _dio.fetch(err.requestOptions);
          
          _isRefreshing = false;

          // Process all queued requests
          _processQueuedRequests(newAccessToken);

          handler.resolve(retryResponse);
        } else {
          print('❌ TokenInterceptor: Token refresh failed');
          _isRefreshing = false;
          await _tokenManager.clearTokens();
          _clearRequestQueue(err);
          handler.next(err);
        }
      } catch (refreshError) {
        print('❌ TokenInterceptor: Token refresh error: $refreshError');
        _isRefreshing = false;

        // Clear tokens on refresh failure (user needs to login again)
        await _tokenManager.clearTokens();
        _clearRequestQueue(DioException(
          requestOptions: err.requestOptions,
          error: refreshError,
        ));

        handler.next(err);
      }
    } else {
      // Not a 401 error, pass through
      handler.next(err);
    }
  }

  /// Process all queued requests after successful token refresh
  void _processQueuedRequests(String newAccessToken) async {
    if (_requestQueue.isEmpty) {
      print('✅ TokenInterceptor: No queued requests to process');
      return;
    }

    print('🔄 TokenInterceptor: Processing ${_requestQueue.length} queued requests');

    // Create a copy of the queue and clear the original to prevent concurrent modification
    final queueCopy = List<_QueuedRequest>.from(_requestQueue);
    _requestQueue.clear();

    for (final queuedRequest in queueCopy) {
      try {
        // Add new token to request
        queuedRequest.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

        // Execute the request
        final response = await _dio.fetch(queuedRequest.requestOptions);

        // Resolve with success
        queuedRequest.resolve(response);

        print('✅ TokenInterceptor: Queued request succeeded: ${queuedRequest.requestOptions.path}');
      } catch (e) {
        // Reject with error
        queuedRequest.reject(
          DioException(
            requestOptions: queuedRequest.requestOptions,
            error: e,
          ),
        );

        print('❌ TokenInterceptor: Queued request failed: ${queuedRequest.requestOptions.path} - $e');
      }
    }

    print('✅ TokenInterceptor: All queued requests processed');
  }

  /// Clear request queue on refresh failure
  void _clearRequestQueue(DioException error) {
    if (_requestQueue.isEmpty) {
      return;
    }

    print('❌ TokenInterceptor: Clearing ${_requestQueue.length} queued requests due to refresh failure');

    for (final queuedRequest in _requestQueue) {
      queuedRequest.reject(error);
    }

    _requestQueue.clear();
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
           path.contains('/auth/register') ||
           path.contains('/auth/refresh-token') ||
           path.contains('/auth/forgot-password');
  }
}

/// Helper class to store queued request info
/// Supports both request and error handlers for unified queueing
class _QueuedRequest {
  final RequestOptions requestOptions;
  final RequestInterceptorHandler? requestHandler;
  final ErrorInterceptorHandler? errorHandler;

  _QueuedRequest.fromRequest({
    required this.requestOptions,
    required this.requestHandler,
  }) : errorHandler = null;

  _QueuedRequest.fromError({
    required this.requestOptions,
    required this.errorHandler,
  }) : requestHandler = null;

  /// Resolve the request with successful response
  void resolve(Response response) {
    if (requestHandler != null) {
      requestHandler!.resolve(response);
    } else if (errorHandler != null) {
      errorHandler!.resolve(response);
    }
  }

  /// Reject the request with error
  void reject(DioException error) {
    if (requestHandler != null) {
      requestHandler!.reject(error);
    } else if (errorHandler != null) {
      errorHandler!.reject(error);
    }
  }
}

/// Handle dealer invitation notification tap
void _handleDealerInvitationTap(String payload) {
  // Get navigator key from main.dart via NavigationService
  final navigationService = getIt<NavigationService>();
  final context = navigationService.navigatorKey.currentContext;
  
  if (context != null) {
    print('🔔 Navigating to PendingInvitationsScreen from notification tap');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PendingInvitationsScreen(),
      ),
    );
  } else {
    print('⚠️ Cannot navigate - no context available');
  }
}