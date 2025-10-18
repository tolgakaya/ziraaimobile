import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/network_client.dart';
import '../models/message_model.dart';
import '../models/blocked_sponsor_model.dart';
import '../models/message_quota_model.dart';

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

  /// Get all messages for a specific plant analysis  
  /// GET /sponsorship/messages/conversation?farmerId={}&plantAnalysisId={}
  Future<List<MessageModel>> getMessages({
    required int plantAnalysisId,
    required int farmerId,
  }) async {
    final response = await _networkClient.get(
      ApiConfig.messagingGetConversation,
      queryParameters: {
        'plantAnalysisId': plantAnalysisId,
        'farmerId': farmerId,
      },
    );

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data['message'] ?? 'Failed to get messages',
      );
    }
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
}
