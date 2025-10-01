import 'package:signalr_netcore/signalr_client.dart';
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
    print('🔌 SignalR: Starting initialization...');
    if (_isConnected && _currentToken == jwtToken) {
      print('✅ SignalR: Already connected with same token');
      return;
    }

    // Disconnect existing connection if token changed
    if (_isConnected && _currentToken != jwtToken) {
      print('🔄 SignalR: Token changed, reconnecting...');
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
          .build();

      // Register event handlers
      _registerEventHandlers();

      // Connection lifecycle handlers
      _hubConnection.onclose(({Exception? error}) {
        _isConnected = false;
        print('❌ SignalR: Connection closed: $error');
      });

      _hubConnection.onreconnecting(({Exception? error}) {
        print('🔄 SignalR: Reconnecting...');
      });

      _hubConnection.onreconnected(({String? connectionId}) {
        _isConnected = true;
        print('✅ SignalR: Reconnected: $connectionId');
      });

      print('🔌 SignalR: Starting connection...');
      // Start connection
      await _hubConnection.start();
      _isConnected = true;

      print('✅ SignalR: Connected successfully!');

      // Test ping
      print('🏓 SignalR: Sending test ping...');
      await ping();
    } catch (e, stackTrace) {
      print('❌ SignalR: Connection failed: $e');
      print('❌ SignalR: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Register server → client event handlers
  void _registerEventHandlers() {
    print('📡 SignalR: Registering event handlers...');
    
    // Analysis completed event
    _hubConnection.on('ReceiveAnalysisCompleted', (arguments) {
      print('📨 SignalR: ReceiveAnalysisCompleted event triggered!');
      if (arguments != null && arguments.isNotEmpty) {
        final notificationData = arguments[0] as Map<String, dynamic>;
        print('📨 SignalR: Analysis completed notification received: ${notificationData['analysisId']}');
        print('📨 SignalR: Full notification data: $notificationData');

        try {
          final notification = PlantAnalysisNotification.fromJson(notificationData);
          print('✅ SignalR: Notification parsed successfully, calling callback...');
          onAnalysisCompleted?.call(notification);
        } catch (e, stackTrace) {
          print('❌ SignalR: Error parsing notification: $e');
          print('❌ SignalR: Stack trace: $stackTrace');
        }
      }
    });

    // Analysis failed event
    _hubConnection.on('ReceiveAnalysisFailed', (arguments) {
      print('❌ SignalR: ReceiveAnalysisFailed event triggered!');
      if (arguments != null && arguments.length >= 2) {
        final analysisId = arguments[0] as int;
        final errorMessage = arguments[1] as String;

        print('❌ SignalR: Analysis failed notification: $analysisId - $errorMessage');

        onAnalysisFailed?.call(analysisId, errorMessage);
      }
    });

    // Pong response
    _hubConnection.on('Pong', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final timestamp = arguments[0];
        print('🏓 SignalR: Pong received: $timestamp');
      } else {
        print('🏓 SignalR: Pong received (no timestamp)');
      }
    });
    
    print('✅ SignalR: Event handlers registered successfully!');
  }

  /// Test connection with ping
  Future<void> ping() async {
    if (!_isConnected) {
      throw Exception('SignalR not connected');
    }

    try {
      await _hubConnection.invoke('Ping');
      print('✅ SignalR: Ping sent successfully');
    } catch (e) {
      print('❌ SignalR: Ping failed: $e');
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
      print('✅ SignalR: Subscribed to analysis: $analysisId');
    } catch (e) {
      print('❌ SignalR: Failed to subscribe to analysis $analysisId: $e');
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
      print('✅ SignalR: Unsubscribed from analysis: $analysisId');
    } catch (e) {
      print('❌ SignalR: Failed to unsubscribe from analysis $analysisId: $e');
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
      print('🔌 SignalR: Disconnected');
    } catch (e) {
      print('❌ SignalR: Error disconnecting: $e');
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