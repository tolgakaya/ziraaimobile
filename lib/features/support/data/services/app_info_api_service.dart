import '../../../../core/network/network_client.dart';
import '../models/app_info_dto.dart';

/// API Service for App Info operations
class AppInfoApiService {
  final NetworkClient _networkClient;

  static const String _baseUrl = '/appinfo';

  AppInfoApiService(this._networkClient);

  /// Get app info (About Us page data)
  Future<AppInfoDto> getAppInfo() async {
    final response = await _networkClient.get(_baseUrl);

    final data = response.data;
    if (data['success'] == true && data['data'] != null) {
      return AppInfoDto.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to load app info');
  }
}
