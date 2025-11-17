import 'package:json_annotation/json_annotation.dart';
import 'farmer_profile_dto.dart';

part 'farmer_profile_response.g.dart';

/// Response wrapper for farmer profile API endpoints
@JsonSerializable()
class FarmerProfileResponse {
  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'data')
  final FarmerProfileDto? data;

  @JsonKey(name: 'message')
  final String? message;

  FarmerProfileResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory FarmerProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$FarmerProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FarmerProfileResponseToJson(this);
}

/// Response wrapper for profile update operations
@JsonSerializable()
class ProfileUpdateResponse {
  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'data')
  final Map<String, dynamic>? data;

  ProfileUpdateResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ProfileUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileUpdateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileUpdateResponseToJson(this);
}
