import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/farmer_invitation_details.dart';
import '../models/farmer_invitation_summary.dart';
import '../models/farmer_invitation_accept_request.dart';
import '../models/farmer_invitation_accept_response.dart';
import '../models/create_farmer_invitation_request.dart';
import '../models/create_farmer_invitation_response.dart';

part 'farmer_invitation_api_service.g.dart';

/// API service for farmer invitation operations
///
/// Implements 4 endpoints:
/// - GET /api/v1/sponsorship/farmer/invitation-details (public)
/// - GET /api/v1/sponsorship/farmer/my-invitations (authenticated)
/// - POST /api/v1/sponsorship/farmer/accept-invitation (authenticated)
/// - POST /api/v1/sponsorship/farmer/invite (authenticated - sponsor)
@RestApi()
abstract class FarmerInvitationApiService {
  factory FarmerInvitationApiService(Dio dio) = _FarmerInvitationApiService;

  /// Get invitation details by token (public endpoint, no auth required)
  ///
  /// Used when farmer opens deep link: https://ziraai.com/farmer-invite/{token}
  @GET('/sponsorship/farmer/invitation-details')
  Future<FarmerInvitationDetails> getInvitationDetails(
    @Query('token') String token,
  );

  /// Get farmer's invitation list (authenticated endpoint)
  ///
  /// Returns all invitations (pending, accepted, expired) for current farmer
  @GET('/sponsorship/farmer/my-invitations')
  Future<List<FarmerInvitationSummary>> getMyInvitations();

  /// Accept invitation by token (authenticated endpoint)
  ///
  /// Activates codes and extends farmer's subscription
  @POST('/sponsorship/farmer/accept-invitation')
  Future<FarmerInvitationAcceptResponse> acceptInvitation(
    @Body() FarmerInvitationAcceptRequest request,
  );

  /// Create farmer invitation (authenticated endpoint - sponsor only)
  ///
  /// Sends invitation via SMS with deep link
  @POST('/sponsorship/farmer/invite')
  Future<CreateFarmerInvitationResponse> createInvitation(
    @Body() CreateFarmerInvitationRequest request,
  );
}
