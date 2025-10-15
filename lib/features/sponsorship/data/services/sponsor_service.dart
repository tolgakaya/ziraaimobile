import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../models/sponsor_dashboard_summary.dart';
import '../models/sponsorship_code.dart';
import '../models/code_recipient.dart';
import '../models/send_link_response.dart';
import '../models/paginated_sponsorship_codes.dart';
import '../models/sponsorship_tier_comparison.dart';
import 'dart:developer' as developer;

@lazySingleton
class SponsorService {
  final Dio _dio;
  final AuthService _authService;

  SponsorService({
    required Dio dio,
    required AuthService authService,
  })  : _dio = dio,
        _authService = authService;

  /// Create sponsor profile for phone-registered user
  /// This upgrades a Farmer to dual-role (Farmer + Sponsor)
  /// Tier will be assigned after purchasing a package
  Future<Map<String, dynamic>> createSponsorProfile({
    required String companyName,
    required String businessEmail,
    required String password,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      developer.log(
        'Creating sponsor profile: $companyName',
        name: 'SponsorService',
      );

      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}${ApiConfig.createSponsorProfile}',
        data: {
          'companyName': companyName,
          'businessEmail': businessEmail,
          'password': password,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      developer.log(
        'Sponsor profile created successfully',
        name: 'SponsorService',
      );

      return response.data;
    } on DioException catch (e) {
      developer.log(
        'Failed to create sponsor profile',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ??
                           e.response?.data['title'] ??
                           'Failed to create sponsor profile';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error creating sponsor profile',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get sponsor profile details
  Future<Map<String, dynamic>> getSponsorProfile() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}${ApiConfig.getSponsorProfile}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      developer.log(
        'Failed to get sponsor profile',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ??
                           'Failed to load sponsor profile';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get sponsor dashboard summary
  /// Endpoint: GET /api/v1/sponsorship/dashboard-summary
  Future<SponsorDashboardSummary> getDashboardSummary() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      developer.log(
        'Fetching sponsor dashboard summary',
        name: 'SponsorService',
      );

      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}${ApiConfig.sponsorDashboardSummary}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      developer.log(
        'Dashboard summary fetched successfully',
        name: 'SponsorService',
      );

      // API returns: { "success": true, "message": "...", "data": {...} }
      final responseData = response.data;
      if (responseData['success'] == true && responseData['data'] != null) {
        return SponsorDashboardSummary.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load dashboard');
      }
    } on DioException catch (e) {
      developer.log(
        'Failed to get dashboard summary',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? (errorData['message'] ?? 'Failed to load dashboard')
            : 'Failed to load dashboard';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error getting dashboard summary',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get unused sponsorship codes (includes both sent and unsent)
  /// Endpoint: GET /api/v1/sponsorship/codes?onlyUnused=true
  /// Use this for statistics only, NOT for distribution
  Future<List<SponsorshipCode>> getUnusedCodes() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      developer.log(
        'Fetching unused sponsorship codes',
        name: 'SponsorService',
      );

      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}${ApiConfig.sponsorshipCodes}',
        queryParameters: {'onlyUnused': true},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      developer.log(
        'Unused codes fetched successfully',
        name: 'SponsorService',
      );

      // API returns: { "success": true, "data": [...] }
      final responseData = response.data;
      if (responseData['success'] == true && responseData['data'] != null) {
        final codes = (responseData['data'] as List)
            .map((json) => SponsorshipCode.fromJson(json))
            .toList();

        developer.log(
          'Found ${codes.length} unused codes',
          name: 'SponsorService',
        );

        return codes;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load codes');
      }
    } on DioException catch (e) {
      developer.log(
        'Failed to get unused codes',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? (errorData['message'] ?? 'Failed to load codes')
            : 'Failed to load codes';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error getting unused codes',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get SENT + EXPIRED + UNUSED sponsorship codes with pagination
  /// Endpoint: GET /api/v1/sponsorship/codes?onlySentExpired=true&page=1&pageSize=50
  /// Use this for resending expired codes to farmers
  ///
  /// Filters:
  /// - DistributionDate IS NOT NULL (sent to farmers)
  /// - ExpiryDate < NOW (expired)
  /// - IsUsed = false (not redeemed)
  ///
  /// Backend returns paginated format:
  /// { "success": true, "data": { "items": [...], "totalCount": 100, "page": 1, ... } }
  Future<PaginatedSponsorshipCodes> getSentExpiredCodes({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      developer.log(
        'Fetching SENT EXPIRED sponsorship codes - Page $page (size: $pageSize)',
        name: 'SponsorService',
      );

      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}${ApiConfig.sponsorshipCodes}',
        queryParameters: {
          'onlySentExpired': true,
          'page': page,
          'pageSize': pageSize,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      developer.log(
        'Sent expired codes fetched successfully',
        name: 'SponsorService',
      );

      // API returns paginated format: { "success": true, "data": { "items": [...], ... } }
      final responseData = response.data;
      if (responseData['success'] == true && responseData['data'] != null) {
        final paginatedData = responseData['data'];

        // Check if this is the new paginated format (has 'items' field)
        if (paginatedData is Map<String, dynamic> && paginatedData.containsKey('items')) {
          // NEW FORMAT: Paginated response
          final result = PaginatedSponsorshipCodes.fromJson(paginatedData);

          developer.log(
            'Found ${result.itemCount} expired codes on page ${result.page}/${result.totalPages} (total: ${result.totalCount})',
            name: 'SponsorService',
          );

          return result;
        } else if (paginatedData is List) {
          // OLD FORMAT: Direct array (backward compatibility)
          developer.log(
            'WARNING: Backend returned old format (direct array). Converting to paginated format.',
            name: 'SponsorService',
          );

          final codes = (paginatedData as List)
              .map((json) => SponsorshipCode.fromJson(json))
              .toList();

          // Wrap in paginated structure for backward compatibility
          return PaginatedSponsorshipCodes(
            items: codes,
            totalCount: codes.length,
            page: page,
            pageSize: pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load codes');
      }
    } on DioException catch (e) {
      developer.log(
        'Failed to get sent expired codes',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? (errorData['message'] ?? 'Failed to load codes')
            : 'Failed to load codes';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error getting sent expired codes',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get UNSENT sponsorship codes with pagination (DistributionDate = NULL)
  /// Endpoint: GET /api/v1/sponsorship/codes?onlyUnsent=true&page=1&pageSize=50
  /// RECOMMENDED: Use this for code distribution to prevent duplicate sends
  ///
  /// Backend returns paginated format:
  /// { "success": true, "data": { "items": [...], "totalCount": 100, "page": 1, ... } }
  Future<PaginatedSponsorshipCodes> getUnsentCodes({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      developer.log(
        'Fetching UNSENT sponsorship codes - Page $page (size: $pageSize)',
        name: 'SponsorService',
      );

      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}${ApiConfig.sponsorshipCodes}',
        queryParameters: {
          'onlyUnsent': true,
          'page': page,
          'pageSize': pageSize,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      developer.log(
        'Unsent codes fetched successfully',
        name: 'SponsorService',
      );

      // API returns NEW PAGINATED FORMAT: { "success": true, "data": { "items": [...], ... } }
      final responseData = response.data;
      if (responseData['success'] == true && responseData['data'] != null) {
        final paginatedData = responseData['data'];

        // Check if this is the new paginated format (has 'items' field)
        if (paginatedData is Map<String, dynamic> && paginatedData.containsKey('items')) {
          // NEW FORMAT: Paginated response
          final result = PaginatedSponsorshipCodes.fromJson(paginatedData);

          developer.log(
            'Found ${result.itemCount} codes on page ${result.page}/${result.totalPages} (total: ${result.totalCount})',
            name: 'SponsorService',
          );

          return result;
        } else if (paginatedData is List) {
          // OLD FORMAT: Direct array (backward compatibility)
          developer.log(
            'WARNING: Backend returned old format (direct array). Converting to paginated format.',
            name: 'SponsorService',
          );

          final codes = (paginatedData as List)
              .map((json) => SponsorshipCode.fromJson(json))
              .toList();

          // Wrap in paginated structure for backward compatibility
          return PaginatedSponsorshipCodes(
            items: codes,
            totalCount: codes.length,
            page: page,
            pageSize: pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load codes');
      }
    } on DioException catch (e) {
      developer.log(
        'Failed to get unsent codes',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? (errorData['message'] ?? 'Failed to load codes')
            : 'Failed to load codes';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error getting unsent codes',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get sponsorship tiers for package purchase selection
  /// Endpoint: GET /api/v1/sponsorship/tiers-for-purchase
  /// No authentication required (AllowAnonymous)
  Future<List<SponsorshipTierComparison>> getTiersForPurchase() async {
    try {
      developer.log(
        'Fetching sponsorship tiers for purchase',
        name: 'SponsorService',
      );

      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}/sponsorship/tiers-for-purchase',
        options: Options(
          headers: {
            'x-dev-arch-version': '1.0',
            'Accept': 'application/json',
          },
        ),
      );

      developer.log(
        'Sponsorship tiers fetched successfully',
        name: 'SponsorService',
      );

      // API returns: { "success": true, "message": "...", "data": [...] }
      final responseData = response.data;
      if (responseData['success'] == true && responseData['data'] != null) {
        final allTiers = (responseData['data'] as List)
            .map((json) => SponsorshipTierComparison.fromJson(json))
            .toList();

        // Filter out Trial tier - it's for farmers only, not sponsors
        final tiers = allTiers
            .where((tier) => tier.tierName.toUpperCase() != 'TRIAL')
            .toList();

        developer.log(
          'Found ${tiers.length} sponsorship tiers (filtered from ${allTiers.length})',
          name: 'SponsorService',
        );

        return tiers;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load tiers');
      }
    } on DioException catch (e) {
      developer.log(
        'Failed to get sponsorship tiers',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? (errorData['message'] ?? 'Failed to load tiers')
            : 'Failed to load tiers';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error getting sponsorship tiers',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }

  /// Purchase a sponsorship package
  /// Endpoint: POST /api/v1/sponsorship/purchase-package
  ///
  /// Creates a new sponsorship package purchase with specified tier and quantity.
  /// Payment is processed through mock gateway (test mode).
  ///
  /// Returns: { "success": true, "message": "...", "data": { "packageId": "...", "codes": [...], ... } }
  Future<Map<String, dynamic>> purchasePackage({
    required int tierId,
    required int quantity,
    required double totalAmount,
    required String paymentMethod,
    required String paymentReference,
    required String companyName,
    required String taxNumber,
    required String invoiceAddress,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      developer.log(
        'Purchasing package: Tier $tierId, Quantity $quantity, Amount $totalAmount',
        name: 'SponsorService',
      );

      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}${ApiConfig.purchasePackage}',
        data: {
          'subscriptionTierId': tierId,
          'quantity': quantity,
          'totalAmount': totalAmount,
          'paymentMethod': paymentMethod,
          'paymentReference': paymentReference,
          'companyName': companyName,
          'taxNumber': taxNumber,
          'invoiceAddress': invoiceAddress,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      developer.log(
        'Package purchased successfully',
        name: 'SponsorService',
      );

      return response.data;
    } on DioException catch (e) {
      developer.log(
        'Failed to purchase package',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? (errorData['message'] ?? 'Failed to purchase package')
            : 'Failed to purchase package';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error purchasing package',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }

  /// Send sponsorship links to recipients
  /// Endpoint: POST /api/v1/sponsorship/send-link
  ///
  /// [allowResendExpired] If true, allows resending expired codes with renewed expiry date (+30 days)
  Future<SendLinkResponse> sendSponsorshipLinks({
    required List<CodeRecipient> recipients,
    required String channel, // "SMS" or "WhatsApp"
    required List<String> selectedCodes,
    bool allowResendExpired = false,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      // Auto-assign codes to recipients
      final recipientsWithCodes = <Map<String, dynamic>>[];
      for (int i = 0; i < recipients.length; i++) {
        final recipient = recipients[i];
        final code = selectedCodes[i];

        recipientsWithCodes.add({
          'code': code,
          'phone': CodeRecipient.normalizePhone(recipient.phone),
          'name': recipient.name,
        });
      }

      developer.log(
        'Sending ${recipientsWithCodes.length} links via $channel',
        name: 'SponsorService',
      );

      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}${ApiConfig.sendSponsorshipLink}',
        data: {
          'recipients': recipientsWithCodes,
          'channel': channel,
          'customMessage': null,
          'allowResendExpired': allowResendExpired,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      developer.log(
        'Links sent successfully',
        name: 'SponsorService',
      );

      return SendLinkResponse.fromJson(response.data);
    } on DioException catch (e) {
      developer.log(
        'Failed to send links',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? (errorData['message'] ?? 'Failed to send links')
            : 'Failed to send links';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error sending links',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }

  /// Redeem sponsorship code (Farmer endpoint)
  /// Endpoint: POST /api/v1/sponsorship/redeem
  ///
  /// Validates and activates a sponsorship subscription for the authenticated farmer.
  /// If farmer already has active sponsored subscription, code will be queued.
  ///
  /// Returns: { "success": true, "message": "...", "data": { subscription details } }
  Future<Map<String, dynamic>> redeemSponsorshipCode(String code) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      developer.log(
        'Redeeming sponsorship code: $code',
        name: 'SponsorService',
      );

      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}/sponsorship/redeem',
        data: {
          'code': code,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      developer.log(
        'Code redeemed successfully',
        name: 'SponsorService',
      );

      return response.data;
    } on DioException catch (e) {
      developer.log(
        'Failed to redeem code',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? (errorData['message'] ?? 'Failed to redeem code')
            : 'Failed to redeem code';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error redeeming code',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }

  /// Validate sponsorship code (Optional pre-check)
  /// Endpoint: GET /api/v1/sponsorship/validate/{code}
  ///
  /// Checks if code is valid before attempting redemption.
  /// Useful for showing tier information to user before redeeming.
  ///
  /// Returns: { "success": true, "data": { "code": "...", "subscriptionTier": "...", "isValid": true, ... } }
  Future<Map<String, dynamic>> validateSponsorshipCode(String code) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      developer.log(
        'Validating sponsorship code: $code',
        name: 'SponsorService',
      );

      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}/sponsorship/validate/$code',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      developer.log(
        'Code validation completed',
        name: 'SponsorService',
      );

      return response.data;
    } on DioException catch (e) {
      developer.log(
        'Failed to validate code',
        name: 'SponsorService',
        error: e,
      );

      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? (errorData['message'] ?? 'Failed to validate code')
            : 'Failed to validate code';
        throw Exception(errorMessage);
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      developer.log(
        'Unexpected error validating code',
        name: 'SponsorService',
        error: e,
      );
      throw Exception('Unexpected error: $e');
    }
  }
}
