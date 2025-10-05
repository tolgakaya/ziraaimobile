import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:injectable/injectable.dart';
import '../models/phone_login_request.dart';
import '../models/phone_login_response.dart';
import '../models/verify_phone_otp_request.dart';
import '../models/phone_register_request.dart';
import '../models/phone_register_response.dart';
import '../models/verify_phone_register_request.dart';
import '../models/auth_token_response.dart';

part 'phone_auth_api_service.g.dart';

/// Phone-based authentication API service
/// Handles OTP login and registration flows
@RestApi()
@injectable
abstract class PhoneAuthApiService {
  @factoryMethod
  factory PhoneAuthApiService(Dio dio, {String baseUrl}) = _PhoneAuthApiService;

  /// Request OTP for login
  /// API: POST /api/v1/auth/login-phone
  ///
  /// Returns message like "SendMobileCode123456" in development environment
  /// OTP code can be extracted from response message
  @POST('/auth/login-phone')
  Future<PhoneLoginResponse> requestLoginOtp(
    @Body() PhoneLoginRequest request,
  );

  /// Verify OTP and complete login
  /// API: POST /api/v1/auth/verify-phone-otp
  ///
  /// Returns JWT token with expiration and refresh token
  @POST('/auth/verify-phone-otp')
  Future<AuthTokenResponse> verifyLoginOtp(
    @Body() VerifyPhoneOtpRequest request,
  );

  /// Request OTP for registration
  /// API: POST /api/v1/auth/register-phone
  ///
  /// Optional referralCode can be provided for referral rewards
  /// Returns message like "Register SendMobileCode for Phone:+90XXXXXXXXXX, Code:123456"
  @POST('/auth/register-phone')
  Future<PhoneRegisterResponse> requestRegisterOtp(
    @Body() PhoneRegisterRequest request,
  );

  /// Verify OTP and complete registration
  /// API: POST /api/v1/auth/verify-phone-register
  ///
  /// Returns JWT token with claims and expiration
  /// If referralCode was provided during registration, user gets referral credits automatically
  @POST('/auth/verify-phone-register')
  Future<AuthTokenResponse> verifyRegisterOtp(
    @Body() VerifyPhoneRegisterRequest request,
  );
}
