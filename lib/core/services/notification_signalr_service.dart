import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/api_config.dart';
import '../models/dealer_invitation_notification.dart';

/// NotificationSignalRService - Dedicated SignalR service for /hubs/notification
///
/// Handles real-time notifications for:
/// - Dealer invitations (NewDealerInvitation event)
///
/// Separate from SignalRService (/hubs/plantanalysis) which handles:
/// - Plant analysis completion events
/// - Chat messaging events
///
/// Why separate service?
/// - Backend has two distinct SignalR hubs with different purposes
/// - Separation of concerns - notification events vs analysis/messaging events
/// - Independent connection lifecycle management
class NotificationSignalRService {
  late HubConnection _hubConnection;
  bool _isConnected = false;
  String? _currentToken;

  // Dealer invitation callbacks - support multiple listeners
  final List<Function(DealerInvitationNotification)> _onNewDealerInvitationListeners = [];

  // Singleton pattern
  static final NotificationSignalRService _instance = NotificationSignalRService._internal();
  factory NotificationSignalRService() => _instance;
  NotificationSignalRService._internal();

  /// Add listener for dealer invitation events
  void addDealerInvitationListener(Function(DealerInvitationNotification) listener) {
    if (!_onNewDealerInvitationListeners.contains(listener)) {
      _onNewDealerInvitationListeners.add(listener);
      print('✅ NotificationHub: Added dealer invitation listener (total: ${_onNewDealerInvitationListeners.length})');
    }
  }

  /// Remove listener for dealer invitation events
  void removeDealerInvitationListener(Function(DealerInvitationNotification) listener) {
    _onNewDealerInvitationListeners.remove(listener);
    print('✅ NotificationHub: Removed dealer invitation listener (remaining: ${_onNewDealerInvitationListeners.length})');
  }

  /// Initialize NotificationHub connection with JWT token
  Future<void> initialize(String jwtToken) async {
    print('🔔 NotificationHub: Starting initialization...');
    if (_isConnected && _currentToken == jwtToken) {
      print('✅ NotificationHub: Already connected with same token');
      return;
    }

    // Disconnect existing connection if token changed
    if (_isConnected && _currentToken != jwtToken) {
      print('🔄 NotificationHub: Token changed, reconnecting...');
      await disconnect();
    }

    _currentToken = jwtToken;

    try {
      // Hub connection builder
      final hubUrl = ApiConfig.notificationHubUrl;
      print('🔔 NotificationHub: Connecting to hub: $hubUrl');

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
        print('❌ NotificationHub: Connection closed: $error');
      });

      _hubConnection.onreconnecting(({Exception? error}) {
        print('🔄 NotificationHub: Reconnecting...');
      });

      _hubConnection.onreconnected(({String? connectionId}) {
        _isConnected = true;
        print('✅ NotificationHub: Reconnected: $connectionId');
      });

      print('🔔 NotificationHub: Starting connection...');
      // Start connection
      await _hubConnection.start();
      _isConnected = true;

      print('✅ NotificationHub: Connected successfully!');

      // Backend NotificationHub automatically adds user to groups on connection:
      // - email_{email} group (if email claim exists)
      // - phone_{normalizedPhone} group (if phone claim exists)
      // No need for manual JoinUserGroup call - backend handles it via OnConnectedAsync

      // Test ping
      print('🏓 NotificationHub: Sending test ping...');
      await ping();
    } catch (e, stackTrace) {
      print('❌ NotificationHub: Connection failed: $e');
      print('❌ NotificationHub: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Register server → client event handlers
  void _registerEventHandlers() {
    print('📡 NotificationHub: Registering event handlers...');

    // Dealer invitation event
    print('📝 NotificationHub: Registering NewDealerInvitation event...');
    _hubConnection.on('NewDealerInvitation', (arguments) {
      print('🎉 NotificationHub: NewDealerInvitation event triggered!');
      if (arguments != null && arguments.isNotEmpty) {
        final invitationData = arguments[0] as Map<String, dynamic>;
        print('🎉 NotificationHub: Invitation data: $invitationData');

        try {
          final invitation = DealerInvitationNotification.fromJson(invitationData);
          print('✅ NotificationHub: Dealer invitation parsed successfully');
          print('📋 NotificationHub: Invitation from ${invitation.sponsorCompanyName}, ${invitation.codeCount} codes');

          // Notify ALL listeners
          if (_onNewDealerInvitationListeners.isNotEmpty) {
            print('🔔 NotificationHub: Notifying ${_onNewDealerInvitationListeners.length} dealer invitation listener(s)...');
            for (final listener in _onNewDealerInvitationListeners) {
              try {
                listener(invitation);
              } catch (e) {
                print('❌ NotificationHub: Error in dealer invitation listener: $e');
              }
            }
            print('✅ NotificationHub: All dealer invitation listeners notified');
          } else {
            print('⚠️ NotificationHub: WARNING - No dealer invitation listeners registered!');
          }
        } catch (e, stackTrace) {
          print('❌ NotificationHub: Error parsing dealer invitation: $e');
          print('❌ NotificationHub: Stack trace: $stackTrace');
        }
      }
    });

    // Pong response
    _hubConnection.on('Pong', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final timestamp = arguments[0];
        print('🏓 NotificationHub: Pong received: $timestamp');
      } else {
        print('🏓 NotificationHub: Pong received (no timestamp)');
      }
    });

    print('✅ NotificationHub: Event handlers registered successfully!');
  }

  /// Test connection with ping
  Future<void> ping() async {
    if (!_isConnected) {
      throw Exception('NotificationHub not connected');
    }

    try {
      await _hubConnection.invoke('Ping');
      print('✅ NotificationHub: Ping sent successfully');
    } catch (e) {
      print('❌ NotificationHub: Ping failed: $e');
      rethrow;
    }
  }

  /// Disconnect from NotificationHub
  Future<void> disconnect() async {
    if (!_isConnected) return;

    try {
      await _hubConnection.stop();
      _isConnected = false;
      _currentToken = null;
      print('🔔 NotificationHub: Disconnected');
    } catch (e) {
      print('❌ NotificationHub: Error disconnecting: $e');
    }
  }

  /// Connection status
  bool get isConnected => _isConnected;

  /// Clear all event handlers
  void clearHandlers() {
    _onNewDealerInvitationListeners.clear();
    print('🔔 NotificationHub: Cleared all handlers');
  }
}
