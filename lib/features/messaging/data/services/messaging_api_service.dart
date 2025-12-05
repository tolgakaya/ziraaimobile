import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/network_client.dart';
import '../models/message_model.dart';
import '../models/paginated_conversation_response.dart';
import '../models/blocked_sponsor_model.dart';
import '../models/message_quota_model.dart';
import '../models/messaging_features_model.dart';

@lazySingleton
class MessagingApiService {
  final NetworkClient _networkClient;

  MessagingApiService(this._networkClient);

  /// Send a message for a specific plant analysis
  /// POST /Sponsorship/messages/send
  Future<MessageModel> sendMessage({
    required int plantAnalysisId,
    required int toUserId,
    required String message,
    String? messageType,
    String? subject,
  }) async {
    final response = await _networkClient.post(
      ApiConfig.messagingSend,
      data: {
        'plantAnalysisId': plantAnalysisId,
        'toUserId': toUserId,
        'message': message,
        if (messageType != null) 'messageType': messageType,
        if (subject != null) 'subject': subject,
      },
    );

    if (response.data['success'] == true) {
      return MessageModel.fromJson(response.data['data']);
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to send message',
      );
    }
  }

  /// Get paginated messages for a specific plant analysis
  /// GET /sponsorship/conversations?fromUserId={}&toUserId={}&plantAnalysisId={}&page={}&pageSize={}
  /// ✅ UPDATED: Backend now returns DESC order (newest first on page 1)
  /// ✅ Frontend should NOT reverse the array - backend sends correct order
  Future<PaginatedConversationResponse> getMessages({
    required int fromUserId,
    required int toUserId,
    required int plantAnalysisId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _networkClient.get(
      ApiConfig.messagingGetConversation,
      queryParameters: {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'plantAnalysisId': plantAnalysisId,
        'page': page,
        'pageSize': pageSize,
      },
    );

    return PaginatedConversationResponse.fromJson(response.data);
  }

  /// Block a sponsor (Farmer only)
  /// POST /Sponsorship/messages/block
  Future<void> blockSponsor({
    required int sponsorId,
    String? reason,
  }) async {
    final response = await _networkClient.post(
      ApiConfig.messagingBlock,
      data: {
        'sponsorId': sponsorId,
        if (reason != null) 'reason': reason,
      },
    );

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to block sponsor',
      );
    }
  }

  /// Unblock a sponsor (Farmer only)
  /// DELETE /Sponsorship/messages/block/{sponsorId}
  Future<void> unblockSponsor(int sponsorId) async {
    final response = await _networkClient.delete(
      ApiConfig.messagingUnblock(sponsorId),
    );

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to unblock sponsor',
      );
    }
  }

  /// Get list of blocked sponsors (Farmer only)
  /// GET /Sponsorship/messages/blocked
  Future<List<BlockedSponsorModel>> getBlockedSponsors() async {
    final response = await _networkClient.get(
      ApiConfig.messagingGetBlocked,
    );

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => BlockedSponsorModel.fromJson(json)).toList();
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to get blocked sponsors',
      );
    }
  }

  /// Get remaining message quota (Sponsor only)
  /// GET /Sponsorship/messages/remaining?farmerId={farmerId}
  Future<MessageQuotaModel> getRemainingQuota(int farmerId) async {
    final response = await _networkClient.get(
      ApiConfig.messagingGetQuota,
      queryParameters: {'farmerId': farmerId},
    );

    if (response.data['success'] == true) {
      return MessageQuotaModel.fromJson(response.data['data']);
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to get quota',
      );
    }
  }

  // ========================================
  // ✅ NEW: Feature Flags
  // ========================================

  /// Get user's available messaging features (tier-based)
  /// GET /sponsorship/messaging/features?plantAnalysisId={analysisId}
  /// ⚠️ BREAKING CHANGE: plantAnalysisId is now REQUIRED
  Future<MessagingFeaturesModel> getAvailableFeatures({required int plantAnalysisId}) async {
    final response = await _networkClient.get(
      '/sponsorship/messaging/features',
      queryParameters: {'plantAnalysisId': plantAnalysisId},
    );

    if (response.data['success'] == true) {
      return MessagingFeaturesModel.fromJson(response.data['data']);
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to get features',
      );
    }
  }

  // ========================================
  // ✅ NEW: Avatar Management
  // ========================================

  /// Upload user avatar
  /// POST /users/avatar
  Future<Map<String, String>> uploadAvatar(File imageFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: 'avatar.jpg'),
    });

    final response = await _networkClient.post('/users/avatar', data: formData);

    if (response.data['success'] == true) {
      return {
        'avatarUrl': response.data['data']['avatarUrl'] as String,
        'avatarThumbnailUrl': response.data['data']['avatarThumbnailUrl'] as String,
      };
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to upload avatar',
      );
    }
  }

  /// Get user's avatar URLs
  /// GET /users/avatar/{userId}
  Future<Map<String, String>> getAvatarUrl(int userId) async {
    final response = await _networkClient.get('/users/avatar/$userId');

    if (response.data['success'] == true) {
      return {
        'avatarUrl': response.data['data']['avatarUrl'] as String,
        'avatarThumbnailUrl': response.data['data']['avatarThumbnailUrl'] as String,
      };
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to get avatar',
      );
    }
  }

  /// Delete user's avatar
  /// DELETE /users/avatar
  Future<void> deleteAvatar() async {
    final response = await _networkClient.delete('/users/avatar');

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to delete avatar',
      );
    }
  }

  // ========================================
  // ✅ NEW: Message Status
  // ========================================

  /// Mark a single message as read
  /// PATCH /sponsorship/messages/{messageId}/read
  Future<void> markMessageAsRead(int messageId) async {
    final response = await _networkClient.patch('/sponsorship/messages/$messageId/read');

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to mark message as read',
      );
    }
  }

  /// Mark multiple messages as read (bulk)
  /// PATCH /sponsorship/messages/read
  /// Body: [123, 124, 125] - Array of message IDs
  Future<int> markMessagesAsRead(List<int> messageIds) async {
    if (messageIds.isEmpty) return 0;
    
    final response = await _networkClient.patch(
      '/sponsorship/messages/read',
      data: messageIds, // ✅ Send array directly, not wrapped in object
    );

    if (response.data['success'] == true) {
      // Backend returns count in 'data' field directly
      return response.data['data'] as int;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to mark messages as read',
      );
    }
  }

  // ========================================
  // ✅ NEW: Attachments
  // ========================================

  /// Send message with attachments (images, documents, videos)
  /// POST /sponsorship/messages/attachments
  /// NOTE: fromUserId is automatically extracted from JWT token by backend
  Future<MessageModel> sendMessageWithAttachments({
    required int toUserId,
    required int plantAnalysisId,
    required String message,
    required List<File> attachments,
  }) async {
    print('📤 Sending attachment - toUserId: $toUserId, plantAnalysisId: $plantAnalysisId');
    final formData = FormData.fromMap({
      'toUserId': toUserId,
      'plantAnalysisId': plantAnalysisId,
      'message': message,
      'messageType': 'Information',  // Required by backend
      'attachments': [
        for (var file in attachments)
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      ],
    });

    final response = await _networkClient.post('/sponsorship/messages/attachments', data: formData);

    if (response.data['success'] == true) {
      return MessageModel.fromJson(response.data['data']);
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to send attachments',
      );
    }
  }

  // ========================================
  // ✅ NEW: Voice Messages
  // ========================================

  /// Send voice message (XL tier only)
  /// POST /sponsorship/messages/voice
  Future<MessageModel> sendVoiceMessage({
    required int toUserId,
    required int plantAnalysisId,
    required File voiceFile,
    required int duration,
    String? waveform,
  }) async {
    final formData = FormData.fromMap({
      'toUserId': toUserId,
      'plantAnalysisId': plantAnalysisId,
      'voiceFile': await MultipartFile.fromFile(voiceFile.path, filename: 'voice.m4a'),
      'duration': duration,
      if (waveform != null) 'waveform': waveform,
    });

    final response = await _networkClient.post('/sponsorship/messages/voice', data: formData);

    if (response.data['success'] == true) {
      return MessageModel.fromJson(response.data['data']);
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to send voice message',
      );
    }
  }

  // ========================================
  // ✅ NEW: Edit/Delete/Forward
  // ========================================

  /// Edit message content (M tier+, within 1 hour)
  /// PUT /sponsorship/messages/{messageId}
  Future<MessageModel> editMessage({
    required int messageId,
    required String newContent,
  }) async {
    final response = await _networkClient.put(
      '/sponsorship/messages/$messageId',
      data: {'newContent': newContent},
    );

    if (response.data['success'] == true) {
      return MessageModel.fromJson(response.data['data']);
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to edit message',
      );
    }
  }

  /// Delete message (within 24 hours)
  /// DELETE /sponsorship/messages/{messageId}
  Future<void> deleteMessage(int messageId) async {
    final response = await _networkClient.delete('/sponsorship/messages/$messageId');

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to delete message',
      );
    }
  }

  /// Forward message to another conversation (M tier+)
  /// POST /sponsorship/messages/{messageId}/forward
  Future<MessageModel> forwardMessage({
    required int messageId,
    required int toUserId,
    required int plantAnalysisId,
  }) async {
    final response = await _networkClient.post(
      '/sponsorship/messages/$messageId/forward',
      data: {
        'toUserId': toUserId,
        'plantAnalysisId': plantAnalysisId,
      },
    );

    if (response.data['success'] == true) {
      return MessageModel.fromJson(response.data['data']);
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to forward message',
      );
    }
  }
}
