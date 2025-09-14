import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:json_annotation/json_annotation.dart';
import '../models/user_model.dart';
import '../models/auth_tokens_model.dart';

part 'auth_remote_datasource.g.dart';

@RestApi(baseUrl: 'https://api.ziraai.com/api/v1')
abstract class AuthRemoteDataSource {
  factory AuthRemoteDataSource(Dio dio, {String baseUrl}) = _AuthRemoteDataSource;

  @POST('/auth/login')
  Future<LoginResponse> login(@Body() LoginRequest request);

  @POST('/auth/register')
  Future<RegisterResponse> register(@Body() RegisterRequest request);

  @POST('/auth/logout')
  Future<void> logout();

  @POST('/auth/logout-all')
  Future<void> logoutFromAllDevices();

  @POST('/auth/refresh-token')
  Future<RefreshTokenResponse> refreshToken(@Body() RefreshTokenRequest request);

  @GET('/auth/validate-session')
  Future<SessionValidationResponse> validateSession();

  @GET('/auth/profile')
  Future<UserModel> getCurrentUser();

  @PUT('/auth/profile')
  Future<UserModel> updateProfile(@Body() UpdateProfileRequest request);

  @POST('/auth/change-password')
  Future<void> changePassword(@Body() ChangePasswordRequest request);

  @POST('/auth/request-password-reset')
  Future<void> requestPasswordReset(@Body() PasswordResetRequest request);

  @POST('/auth/confirm-password-reset')
  Future<void> confirmPasswordReset(@Body() ConfirmPasswordResetRequest request);

  @POST('/auth/verify-email')
  Future<void> verifyEmail(@Body() VerifyEmailRequest request);

  @POST('/auth/resend-email-verification')
  Future<void> resendEmailVerification();

  @POST('/auth/verify-phone')
  Future<void> verifyPhone(@Body() VerifyPhoneRequest request);

  @POST('/auth/resend-phone-verification')
  Future<void> resendPhoneVerification();

  @POST('/auth/setup-two-factor')
  Future<TwoFactorSetupResponse> setupTwoFactor();

  @POST('/auth/confirm-two-factor')
  Future<void> confirmTwoFactor(@Body() ConfirmTwoFactorRequest request);

  @POST('/auth/disable-two-factor')
  Future<void> disableTwoFactor(@Body() DisableTwoFactorRequest request);

  @GET('/auth/permissions')
  Future<List<String>> getUserPermissions();

  @POST('/auth/deactivate-account')
  Future<void> deactivateAccount(@Body() DeactivateAccountRequest request);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;
  final bool rememberMe;
  final String? deviceId;
  final String? deviceName;

  LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
    this.deviceId,
    this.deviceName,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final UserModel user;
  final AuthTokensModel tokens;
  final String message;

  LoginResponse({
    required this.user,
    required this.tokens,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String role;
  final String? phoneNumber;
  final Map<String, dynamic>? metadata;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.role,
    this.phoneNumber,
    this.metadata,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class RegisterResponse {
  final UserModel user;
  final AuthTokensModel tokens;
  final String message;
  final bool requiresEmailVerification;
  final bool requiresPhoneVerification;

  RegisterResponse({
    required this.user,
    required this.tokens,
    required this.message,
    required this.requiresEmailVerification,
    required this.requiresPhoneVerification,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) => _$RegisterResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
}

@JsonSerializable()
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) => _$RefreshTokenRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);
}

@JsonSerializable()
class RefreshTokenResponse {
  final AuthTokensModel tokens;

  RefreshTokenResponse({required this.tokens});

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) => _$RefreshTokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenResponseToJson(this);
}

@JsonSerializable()
class SessionValidationResponse {
  final bool isValid;
  final UserModel? user;
  final AuthTokensModel? tokens;
  final String? message;

  SessionValidationResponse({
    required this.isValid,
    this.user,
    this.tokens,
    this.message,
  });

  factory SessionValidationResponse.fromJson(Map<String, dynamic> json) => _$SessionValidationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SessionValidationResponseToJson(this);
}

@JsonSerializable()
class UpdateProfileRequest {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImage;
  final Map<String, dynamic>? metadata;

  UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImage,
    this.metadata,
  });

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) => _$UpdateProfileRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}

@JsonSerializable()
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final bool logoutFromOtherDevices;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    this.logoutFromOtherDevices = false,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) => _$ChangePasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}

@JsonSerializable()
class PasswordResetRequest {
  final String email;

  PasswordResetRequest({required this.email});

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) => _$PasswordResetRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PasswordResetRequestToJson(this);
}

@JsonSerializable()
class ConfirmPasswordResetRequest {
  final String email;
  final String token;
  final String newPassword;

  ConfirmPasswordResetRequest({
    required this.email,
    required this.token,
    required this.newPassword,
  });

  factory ConfirmPasswordResetRequest.fromJson(Map<String, dynamic> json) => _$ConfirmPasswordResetRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ConfirmPasswordResetRequestToJson(this);
}

@JsonSerializable()
class VerifyEmailRequest {
  final String token;

  VerifyEmailRequest({required this.token});

  factory VerifyEmailRequest.fromJson(Map<String, dynamic> json) => _$VerifyEmailRequestFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyEmailRequestToJson(this);
}

@JsonSerializable()
class VerifyPhoneRequest {
  final String code;

  VerifyPhoneRequest({required this.code});

  factory VerifyPhoneRequest.fromJson(Map<String, dynamic> json) => _$VerifyPhoneRequestFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyPhoneRequestToJson(this);
}

@JsonSerializable()
class TwoFactorSetupResponse {
  final String secret;
  final String qrCodeUrl;
  final List<String> backupCodes;

  TwoFactorSetupResponse({
    required this.secret,
    required this.qrCodeUrl,
    required this.backupCodes,
  });

  factory TwoFactorSetupResponse.fromJson(Map<String, dynamic> json) => _$TwoFactorSetupResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TwoFactorSetupResponseToJson(this);
}

@JsonSerializable()
class ConfirmTwoFactorRequest {
  final String code;

  ConfirmTwoFactorRequest({required this.code});

  factory ConfirmTwoFactorRequest.fromJson(Map<String, dynamic> json) => _$ConfirmTwoFactorRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ConfirmTwoFactorRequestToJson(this);
}

@JsonSerializable()
class DisableTwoFactorRequest {
  final String password;

  DisableTwoFactorRequest({required this.password});

  factory DisableTwoFactorRequest.fromJson(Map<String, dynamic> json) => _$DisableTwoFactorRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DisableTwoFactorRequestToJson(this);
}

@JsonSerializable()
class DeactivateAccountRequest {
  final String password;
  final String reason;

  DeactivateAccountRequest({
    required this.password,
    required this.reason,
  });

  factory DeactivateAccountRequest.fromJson(Map<String, dynamic> json) => _$DeactivateAccountRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DeactivateAccountRequestToJson(this);
}