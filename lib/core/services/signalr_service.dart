import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/api_config.dart';
import '../models/plant_analysis_notification.dart';
import '../models/message_notification.dart';

class SignalRService {
  late HubConnection _hubConnection;
  bool _isConnected = false;
  String? _currentToken;

  // Event callbacks (CHANGED TO LISTS to support multiple listeners)
  Function(PlantAnalysisNotification)? onAnalysisCompleted;
  Function(int analysisId, String error)? onAnalysisFailed;

  // ✅ CRITICAL FIX: Support multiple listeners for real-time messaging
  // - SignalRNotificationIntegration needs to show notifications
  // - Chat pages need to update UI in real-time
  final List<Function(MessageNotification)> _onNewMessageListeners = [];

  // ✅ NEW: Messaging enhancement callbacks
  Function(int userId, String userName, int plantAnalysisId, bool isTyping)? onUserTyping;
  Function(int messageId, int readByUserId, DateTime readAt)? onMessageRead;

  // ✅ Methods to manage message listeners
  void addNewMessageListener(Function(MessageNotification) listener) {
    if (!_onNewMessageListeners.contains(listener)) {
      _onNewMessageListeners.add(listener);
      print('✅ SignalR: Added new message listener (total: ${_onNewMessageListeners.length})');
    }
  }

  void removeNewMessageListener(Function(MessageNotification) listener) {
    _onNewMessageListeners.remove(listener);
    print('✅ SignalR: Removed message listener (remaining: ${_onNewMessageListeners.length})');
  }

  // Backward compatibility: Keep old setter for SignalRNotificationIntegration
  set onNewMessage(Function(MessageNotification)? callback) {
    if (callback != null) {
      addNewMessageListener(callback);
    }
  }

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
      final hubUrl = ApiConfig.signalRHubUrl;
      print('🔌 SignalR: Connecting to hub: $hubUrl');

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
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

      // CRITICAL: Join user-specific group after connection
      // Backend needs to know which user this connection belongs to
      try {
        print('🔑 SignalR: Joining user group...');
        // Extract userId from JWT token
        final parts = jwtToken.split('.');
        if (parts.length >= 2) {
          final payload = parts[1];
          // Decode base64 (handle padding)
          String normalized = base64.normalize(payload);
          final decoded = utf8.decode(base64.decode(normalized));
          final Map<String, dynamic> claims = jsonDecode(decoded);

          // Get userId from nameidentifier claim
          final userId = claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']?.toString();

          if (userId != null) {
            print('🔑 SignalR: Extracted userId from JWT: $userId');
            // Invoke server method to associate this connection with userId
            await _hubConnection.invoke('JoinUserGroup', args: [userId]);
            print('✅ SignalR: Successfully joined user group for userId: $userId');
          } else {
            print('⚠️ SignalR: Could not extract userId from JWT claims');
          }
        }
      } catch (e) {
        print('⚠️ SignalR: Failed to join user group (non-critical): $e');
        // Don't throw - this is optional optimization
      }

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

    // Try both possible event names backend might use
    print('📝 SignalR: Registering AnalysisCompleted (without Receive prefix)...');
    _hubConnection.on('AnalysisCompleted', (arguments) {
      print('📨 SignalR: AnalysisCompleted (no prefix) event triggered!');
      if (arguments != null && arguments.isNotEmpty) {
        final notificationData = arguments[0] as Map<String, dynamic>;
        print('📨 SignalR: Notification data: $notificationData');

        try {
          final notification = PlantAnalysisNotification.fromJson(notificationData);
          print('✅ SignalR: Notification parsed from AnalysisCompleted');
          onAnalysisCompleted?.call(notification);
        } catch (e) {
          print('❌ SignalR: Error parsing AnalysisCompleted: $e');
        }
      }
    });

    print('📝 SignalR: Registering ReceiveAnalysisCompleted...');
    _hubConnection.on('ReceiveAnalysisCompleted', (arguments) {
      print('📨 SignalR: ReceiveAnalysisCompleted event triggered!');
      if (arguments != null && arguments.isNotEmpty) {
        final notificationData = arguments[0] as Map<String, dynamic>;
        print('📨 SignalR: Analysis completed notification received: ${notificationData['analysisId']}');
        print('📨 SignalR: Full notification data: $notificationData');

        try {
          final notification = PlantAnalysisNotification.fromJson(notificationData);
          print('✅ SignalR: Notification parsed successfully');
          print('📋 SignalR: Notification details - ID: ${notification.analysisId}, User: ${notification.userId}, Status: ${notification.status}');

          if (onAnalysisCompleted != null) {
            print('🔔 SignalR: Calling onAnalysisCompleted callback...');
            onAnalysisCompleted?.call(notification);
            print('✅ SignalR: Callback executed');
          } else {
            print('⚠️ SignalR: WARNING - onAnalysisCompleted callback is NULL! No handler registered!');
          }
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

    // New message event - for sponsor→farmer messaging
    print('📝 SignalR: Registering NewMessage event...');
    _hubConnection.on('NewMessage', (arguments) {
      print('💬 SignalR: NewMessage event triggered!');
      if (arguments != null && arguments.isNotEmpty) {
        final messageData = arguments[0] as Map<String, dynamic>;
        print('💬 SignalR: Message data: $messageData');

        try {
          final notification = MessageNotification.fromJson(messageData);
          print('✅ SignalR: Message notification parsed successfully');
          print('📋 SignalR: Message from ${notification.senderRole}: ${notification.fromUserName}');

          // ✅ CRITICAL FIX: Notify ALL listeners (both notification system AND chat pages)
          // Previously only called single onNewMessage callback, now calls all registered listeners
          if (_onNewMessageListeners.isNotEmpty) {
            print('🔔 SignalR: Notifying ${_onNewMessageListeners.length} listener(s)...');
            for (final listener in _onNewMessageListeners) {
              try {
                listener(notification);
              } catch (e) {
                print('❌ SignalR: Error in message listener: $e');
              }
            }
            print('✅ SignalR: All listeners notified');
          } else {
            print('⚠️ SignalR: WARNING - No message listeners registered!');
          }
        } catch (e, stackTrace) {
          print('❌ SignalR: Error parsing message notification: $e');
          print('❌ SignalR: Stack trace: $stackTrace');
        }
      }
    });

    // ✅ NEW: User typing indicator event
    print('📝 SignalR: Registering UserTyping event...');
    _hubConnection.on('UserTyping', (arguments) {
      print('⌨️ SignalR: UserTyping event triggered!');
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final typingData = arguments[0] as Map<String, dynamic>;
          final userId = typingData['userId'] as int;
          final userName = typingData['userName'] as String;
          final plantAnalysisId = typingData['plantAnalysisId'] as int;
          final isTyping = typingData['isTyping'] as bool;

          print('⌨️ SignalR: ${isTyping ? "Started" : "Stopped"} typing - User: $userName (ID: $userId), Analysis: $plantAnalysisId');

          onUserTyping?.call(userId, userName, plantAnalysisId, isTyping);
        } catch (e, stackTrace) {
          print('❌ SignalR: Error parsing typing event: $e');
          print('❌ SignalR: Stack trace: $stackTrace');
        }
      }
    });

    // ✅ NEW: Message read event
    print('📝 SignalR: Registering MessageRead event...');
    _hubConnection.on('MessageRead', (arguments) {
      print('✅ SignalR: MessageRead event triggered!');
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final readData = arguments[0] as Map<String, dynamic>;
          final messageId = readData['messageId'] as int;
          final readByUserId = readData['readByUserId'] as int;
          final readAt = DateTime.parse(readData['readAt'] as String);

          print('✅ SignalR: Message $messageId read by user $readByUserId at $readAt');

          onMessageRead?.call(messageId, readByUserId, readAt);
        } catch (e, stackTrace) {
          print('❌ SignalR: Error parsing message read event: $e');
          print('❌ SignalR: Stack trace: $stackTrace');
        }
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

  // ========================================
  // ✅ NEW: Messaging Enhancement Methods
  // ========================================

  /// Send typing start event to other user
  /// Backend method: StartTyping(int conversationUserId, int plantAnalysisId)
  Future<void> sendTypingStart(int conversationUserId, int plantAnalysisId) async {
    if (!_isConnected) {
      print('⚠️ SignalR: Not connected, cannot send typing start');
      return;
    }

    try {
      await _hubConnection.invoke('StartTyping', args: [conversationUserId, plantAnalysisId]);
      print('⌨️ SignalR: Typing start sent for analysis $plantAnalysisId');
    } catch (e) {
      print('❌ SignalR: Failed to send typing start: $e');
    }
  }

  /// Send typing stop event to other user
  /// Backend method: StopTyping(int conversationUserId, int plantAnalysisId)
  Future<void> sendTypingStop(int conversationUserId, int plantAnalysisId) async {
    if (!_isConnected) {
      print('⚠️ SignalR: Not connected, cannot send typing stop');
      return;
    }

    try {
      await _hubConnection.invoke('StopTyping', args: [conversationUserId, plantAnalysisId]);
      print('⌨️ SignalR: Typing stop sent for analysis $plantAnalysisId');
    } catch (e) {
      print('❌ SignalR: Failed to send typing stop: $e');
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
    onNewMessage = null;
    onUserTyping = null;
    onMessageRead = null;
  }
}