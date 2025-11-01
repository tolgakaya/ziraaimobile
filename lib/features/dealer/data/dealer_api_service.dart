import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/network_client.dart';
import '../domain/models/dealer_invitation_details.dart';
import '../domain/models/dealer_invitation_accept_response.dart';
import '../domain/models/dealer_invitation_summary.dart';
import '../domain/models/dealer_dashboard_summary.dart';
import '../domain/models/paginated_dealer_codes.dart';

/// Dealer API service for invitation management
///
/// Handles all dealer-related API calls:
/// - Get invitation details
/// - Accept invitation
///
/// NOTE: Registered in minimal_service_locator.dart as lazySingleton
class DealerApiService {
  final NetworkClient _networkClient;

  DealerApiService(this._networkClient);

  /// Get dealer dashboard summary statistics
  ///
  /// Endpoint: GET /api/v1/sponsorship/dealer/my-dashboard
  ///
  /// Requires: JWT authentication (automatic via NetworkClient)
  ///
  /// Returns [DealerDashboardSummary] with code statistics:
  /// - totalCodesReceived: Total codes received from sponsors
  /// - codesSent: Codes sent to farmers
  /// - codesUsed: Codes that have been used
  /// - codesAvailable: Available codes ready to send
  /// - usageRate: Percentage of sent codes that were used
  /// - pendingInvitationsCount: Number of pending invitations
  ///
  /// Throws [DioException] on network or API errors.
  ///
  /// Used in:
  /// - Sponsor Dashboard: Display dealer code statistics
  Future<DealerDashboardSummary> getMyDashboard() async {
    try {
      print('[DealerApiService] 🔍 Fetching dealer dashboard summary...');

      final response = await _networkClient.get(
        '/sponsorship/dealer/my-dashboard',
      );

      print('[DealerApiService] Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final summary = DealerDashboardSummary.fromJson(response.data['data']);
        print('[DealerApiService] ✅ Dashboard summary loaded successfully');
        print('[DealerApiService] Total codes: ${summary.totalCodesReceived}, Used: ${summary.codesUsed}, Available: ${summary.codesAvailable}');
        return summary;
      } else {
        final errorMessage = response.data['message'] ?? 'Failed to fetch dashboard summary';
        print('[DealerApiService] ❌ API error: $errorMessage');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: errorMessage,
        );
      }
    } catch (e) {
      print('[DealerApiService] ❌ Error fetching dashboard summary: $e');
      if (e is DioException) {
        print('[DealerApiService] Status code: ${e.response?.statusCode}');
        print('[DealerApiService] Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Get authenticated user's pending dealer invitations
  ///
  /// Endpoint: GET /api/v1/sponsorship/dealer/invitations/my-pending
  ///
  /// Requires: JWT authentication (automatic via NetworkClient)
  ///
  /// Returns list of [DealerInvitationSummary] for the authenticated dealer.
  /// List is pre-sorted by backend (expiring soon first).
  ///
  /// Throws [DioException] on network or API errors.
  ///
  /// Used in:
  /// - Login flow: Check for pending invitations after successful login
  /// - Register flow: Check for pending invitations after registration
  /// - PendingInvitationsScreen: Display list of pending invitations
  Future<List<DealerInvitationSummary>> getMyPendingInvitations() async {
    try {
      print('[DealerApiService] 🔍 Fetching my pending invitations...');

      final response = await _networkClient.get(
        '/sponsorship/dealer/invitations/my-pending',
      );

      print('[DealerApiService] Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> invitationsJson = response.data['data']['invitations'];

        final List<DealerInvitationSummary> summaries = invitationsJson
            .map((json) => DealerInvitationSummary.fromJson(json))
            .toList();

        print('[DealerApiService] ✅ Found ${summaries.length} pending invitations');

        return summaries;
      } else {
        final errorMessage = response.data['message'] ?? 'Failed to fetch pending invitations';
        print('[DealerApiService] ❌ API error: $errorMessage');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: errorMessage,
        );
      }
    } catch (e) {
      print('[DealerApiService] ❌ Error fetching pending invitations: $e');
      if (e is DioException) {
        print('[DealerApiService] Status code: ${e.response?.statusCode}');
        print('[DealerApiService] Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Get invitation details by token
  ///
  /// Endpoint: GET /api/v1/sponsorship/dealer/invitation-details?token={token}
  ///
  /// Returns [DealerInvitationDetails] with sponsor info, code count, tier, etc.
  ///
  /// Throws [DioException] on network or API errors
  Future<DealerInvitationDetails> getInvitationDetails(String token) async {
    try {
      print('[DealerApiService] 🔍 Fetching invitation details for token: ${token.substring(0, 8)}...');

      final response = await _networkClient.get(
        ApiConfig.dealerInvitationDetails,
        queryParameters: {'token': token},
      );

      print('[DealerApiService] Response status: ${response.statusCode}');
      print('[DealerApiService] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final details = DealerInvitationDetails.fromJson(response.data['data']);
        print('[DealerApiService] ✅ Successfully fetched invitation details');
        print('[DealerApiService] Sponsor: ${details.sponsorCompanyName}, Codes: ${details.codeCount}, Tier: ${details.packageTier ?? "N/A"}');
        return details;
      } else {
        final errorMessage = response.data['message'] ?? 'Failed to fetch invitation details';
        print('[DealerApiService] ❌ API error: $errorMessage');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: errorMessage,
        );
      }
    } catch (e) {
      print('[DealerApiService] ❌ Error fetching invitation details: $e');
      if (e is DioException) {
        print('[DealerApiService] Status code: ${e.response?.statusCode}');
        print('[DealerApiService] Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Accept dealer invitation
  ///
  /// Endpoint: POST /api/v1/sponsorship/dealer/accept-invitation
  ///
  /// Request body:
  /// ```json
  /// {
  ///   "invitationToken": "abc123..."
  /// }
  /// ```
  ///
  /// Returns [DealerInvitationAcceptResponse] with transferred code details
  ///
  /// Throws [DioException] on network or API errors
  Future<DealerInvitationAcceptResponse> acceptInvitation(String token) async {
    try {
      print('[DealerApiService] 📨 Accepting invitation with token: ${token.substring(0, 8)}...');

      final response = await _networkClient.post(
        ApiConfig.dealerInvitationAccept,
        data: {'invitationToken': token},
      );

      print('[DealerApiService] Accept response status: ${response.statusCode}');
      print('[DealerApiService] Accept response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final acceptResponse = DealerInvitationAcceptResponse.fromJson(response.data['data']);
        print('[DealerApiService] ✅ Successfully accepted invitation');
        print('[DealerApiService] Transferred codes: ${acceptResponse.codesTransferred}');
        return acceptResponse;
      } else {
        final errorMessage = response.data['message'] ?? 'Failed to accept invitation';
        print('[DealerApiService] ❌ Accept API error: $errorMessage');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: errorMessage,
        );
      }
    } catch (e) {
      print('[DealerApiService] ❌ Error accepting invitation: $e');
      if (e is DioException) {
        print('[DealerApiService] Status code: ${e.response?.statusCode}');
        print('[DealerApiService] Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Get dealer's transferred codes with pagination
  ///
  /// Endpoint: GET /api/v1/sponsorship/dealer/my-codes
  ///
  /// Query Parameters:
  /// - page: Page number (default: 1)
  /// - pageSize: Items per page (default: 50, max: 200)
  /// - onlyUnsent: Filter only unsent codes (default: false)
  ///
  /// Returns [PaginatedDealerCodes] with transferred code list
  ///
  /// Throws [DioException] on network or API errors
  ///
  /// Used in:
  /// - Code Distribution Screen: Display dealer transferred codes for distribution
  Future<PaginatedDealerCodes> getMyCodes({
    int page = 1,
    int pageSize = 50,
    bool onlyUnsent = false,
  }) async {
    try {
      print('[DealerApiService] 🔍 Fetching dealer codes - Page $page (size: $pageSize, onlyUnsent: $onlyUnsent)');

      final response = await _networkClient.get(
        '/sponsorship/dealer/my-codes',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          'onlyUnsent': onlyUnsent,
        },
      );

      print('[DealerApiService] Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final paginatedCodes = PaginatedDealerCodes.fromJson(response.data);
        print('[DealerApiService] ✅ Dealer codes loaded successfully');
        print('[DealerApiService] Total: ${paginatedCodes.totalCount}, Page: ${paginatedCodes.page}/${paginatedCodes.totalPages}');
        return paginatedCodes;
      } else {
        final errorMessage = response.data['message'] ?? 'Failed to fetch dealer codes';
        print('[DealerApiService] ❌ API error: $errorMessage');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: errorMessage,
        );
      }
    } catch (e) {
      print('[DealerApiService] ❌ Error fetching dealer codes: $e');
      if (e is DioException) {
        print('[DealerApiService] Status code: ${e.response?.statusCode}');
        print('[DealerApiService] Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Handle specific API error messages
  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response!.data['message'] != null) {
        return error.response!.data['message'];
      }

      switch (error.response?.statusCode) {
        case 400:
          return 'Davetiye bulunamadı veya süresi dolmuş';
        case 410:
          return 'Bu davetiye zaten kabul edilmiş';
        case 401:
          return 'Yetkilendirme hatası. Lütfen giriş yapın';
        case 500:
          return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin';
        default:
          return 'Bir hata oluştu. Lütfen tekrar deneyin';
      }
    }
    return error.toString();
  }
}
