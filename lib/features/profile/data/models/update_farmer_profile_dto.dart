import 'package:json_annotation/json_annotation.dart';

part 'update_farmer_profile_dto.g.dart';

/// Data transfer object for updating farmer profile
/// Maps to backend UpdateFarmerProfileDto
/// UserId is NOT included (comes from JWT token on backend)
@JsonSerializable()
class UpdateFarmerProfileDto {
  @JsonKey(name: 'fullName')
  final String fullName;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'mobilePhones')
  final String mobilePhones;

  @JsonKey(name: 'birthDate')
  final String? birthDate; // ISO 8601 format: "1990-05-20"

  @JsonKey(name: 'gender')
  final int? gender; // 0=Unspecified, 1=Male, 2=Female

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'notes')
  final String? notes;

  UpdateFarmerProfileDto({
    required this.fullName,
    required this.email,
    required this.mobilePhones,
    this.birthDate,
    this.gender,
    this.address,
    this.notes,
  });

  factory UpdateFarmerProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateFarmerProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateFarmerProfileDtoToJson(this);
}
