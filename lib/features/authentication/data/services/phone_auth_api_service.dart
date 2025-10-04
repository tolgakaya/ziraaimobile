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
  /// API: POST /api/v1/mobileauth/login
  ///
  /// Returns message like "SendMobileCode123456" in development environment
  /// OTP code can be extracted from response message
  @POST('/mobileauth/login')
  Future<PhoneLoginResponse> requestLoginOtp(
    @Body() PhoneLoginRequest request,
  );

  /// Verify OTP and complete login
  /// API: POST /api/v1/mobileauth/verify-login-otp
  ///
  /// Returns JWT token with expiration and refresh token
  @POST('/mobileauth/verify-login-otp')
  Future<AuthTokenResponse> verifyLoginOtp(
    @Body() VerifyPhoneOtpRequest request,
  );

  /// Request OTP for registration
  /// API: POST /api/v1/mobileauth/register
  ///
  /// Optional referralCode can be provided for referral rewards
  /// Returns message like "Register SendMobileCode for Phone:+90XXXXXXXXXX, Code:123456"
  @POST('/mobileauth/register')
  Future<PhoneRegisterResponse> requestRegisterOtp(
    @Body() PhoneRegisterRequest request,
  );

  /// Verify OTP and complete registration
  /// API: POST /api/v1/mobileauth/verify-register-otp
  ///
  /// Returns JWT token with claims and expiration
  /// If referralCode was provided during registration, user gets referral credits automatically
  @POST('/mobileauth/verify-register-otp')
  Future<AuthTokenResponse> verifyRegisterOtp(
    @Body() VerifyPhoneRegisterRequest request,
  );
}
