import 'package:signalr_netcore/signalr_client.dart';
import 'dart:developer' as developer;
import '../models/plant_analysis_notification.dart';

class SignalRService {
  late HubConnection _hubConnection;
  bool _isConnected = false;
  String? _currentToken;

  // Event callbacks
  Function(PlantAnalysisNotification)? onAnalysisCompleted;
  Function(int analysisId, String error)? onAnalysisFailed;

  // Singleton pattern
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  /// Initialize SignalR connection with JWT token
  Future<void> initialize(String jwtToken) async {
    if (_isConnected && _currentToken == jwtToken) {
      developer.log('SignalR already connected with same token', name: 'SignalRService');
      return;
    }

    // Disconnect existing connection if token changed
    if (_isConnected && _currentToken != jwtToken) {
      developer.log('Token changed, reconnecting SignalR', name: 'SignalRService');
      await disconnect();
    }

    _currentToken = jwtToken;

    try {
      // Hub connection builder
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            'https://ziraai-api-sit.up.railway.app/hubs/plantanalysis',
            options: HttpConnectionOptions(
              accessTokenFactory: () async => jwtToken,
              logMessageContent: true,
              skipNegotiation: false,
              transport: HttpTransportType.WebSockets,
            ),
          )
          .withAutomaticReconnect(
            retryDelays: [0, 2000, 5000, 10000, 30000], // Reconnect intervals in ms
          )
          .configureLogging(LogLevel.information)
          .build();

      // Register event handlers
      _registerEventHandlers();

      // Connection lifecycle handlers
      _hubConnection.onclose((error) {
        _isConnected = false;
        developer.log(
          'SignalR connection closed: $error',
          name: 'SignalRService',
          error: error,
        );
      });

      _hubConnection.onreconnecting((error) {
        developer.log(
          'SignalR reconnecting...',
          name: 'SignalRService',
        );
      });

      _hubConnection.onreconnected((connectionId) {
        _isConnected = true;
        developer.log(
          'SignalR reconnected: $connectionId',
          name: 'SignalRService',
        );
      });

      // Start connection
      await _hubConnection.start();
      _isConnected = true;

      developer.log(
        '✅ SignalR connected successfully',
        name: 'SignalRService',
      );

      // Test ping
      await ping();
    } catch (e) {
      developer.log(
        '❌ SignalR connection failed: $e',
        name: 'SignalRService',
        error: e,
      );
      rethrow;
    }
  }

  /// Register server → client event handlers
  void _registerEventHandlers() {
    // Analysis completed event
    _hubConnection.on('ReceiveAnalysisCompleted', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final notificationData = arguments[0] as Map<String, dynamic>;
        developer.log(
          '📨 Analysis completed notification received: ${notificationData['analysisId']}',
          name: 'SignalRService',
        );

        try {
          final notification = PlantAnalysisNotification.fromJson(notificationData);
          onAnalysisCompleted?.call(notification);
        } catch (e) {
          developer.log(
            'Error parsing notification: $e',
            name: 'SignalRService',
            error: e,
          );
        }
      }
    });

    // Analysis failed event
    _hubConnection.on('ReceiveAnalysisFailed', (arguments) {
      if (arguments != null && arguments.length >= 2) {
        final analysisId = arguments[0] as int;
        final errorMessage = arguments[1] as String;

        developer.log(
          '❌ Analysis failed notification: $analysisId - $errorMessage',
          name: 'SignalRService',
        );

        onAnalysisFailed?.call(analysisId, errorMessage);
      }
    });

    // Pong response
    _hubConnection.on('Pong', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final timestamp = arguments[0];
        developer.log('🏓 Pong received: $timestamp', name: 'SignalRService');
      }
    });
  }

  /// Test connection with ping
  Future<void> ping() async {
    if (!_isConnected) {
      throw Exception('SignalR not connected');
    }

    try {
      await _hubConnection.invoke('Ping');
      developer.log('Ping sent successfully', name: 'SignalRService');
    } catch (e) {
      developer.log('Ping failed: $e', name: 'SignalRService', error: e);
      rethrow;
    }
  }

  /// Subscribe to specific analysis updates
  Future<void> subscribeToAnalysis(int analysisId) async {
    if (!_isConnected) {
      throw Exception('SignalR not connected');
    }

    try {
      await _hubConnection.invoke('SubscribeToAnalysis', args: [analysisId]);
      developer.log(
        'Subscribed to analysis: $analysisId',
        name: 'SignalRService',
      );
    } catch (e) {
      developer.log(
        'Failed to subscribe to analysis $analysisId: $e',
        name: 'SignalRService',
        error: e,
      );
      rethrow;
    }
  }

  /// Unsubscribe from analysis
  Future<void> unsubscribeFromAnalysis(int analysisId) async {
    if (!_isConnected) {
      throw Exception('SignalR not connected');
    }

    try {
      await _hubConnection.invoke('UnsubscribeFromAnalysis', args: [analysisId]);
      developer.log(
        'Unsubscribed from analysis: $analysisId',
        name: 'SignalRService',
      );
    } catch (e) {
      developer.log(
        'Failed to unsubscribe from analysis $analysisId: $e',
        name: 'SignalRService',
        error: e,
      );
      rethrow;
    }
  }

  /// Disconnect from SignalR
  Future<void> disconnect() async {
    if (!_isConnected) return;

    try {
      await _hubConnection.stop();
      _isConnected = false;
      _currentToken = null;
      developer.log('SignalR disconnected', name: 'SignalRService');
    } catch (e) {
      developer.log(
        'Error disconnecting SignalR: $e',
        name: 'SignalRService',
        error: e,
      );
    }
  }

  /// Connection status
  bool get isConnected => _isConnected;

  /// Clear event handlers
  void clearHandlers() {
    onAnalysisCompleted = null;
    onAnalysisFailed = null;
  }
}