import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/farmer_profile.dart';

part 'farmer_profile_dto.g.dart';

/// Data transfer object for farmer profile
/// Maps to backend FarmerProfileDto
@JsonSerializable()
class FarmerProfileDto {
  @JsonKey(name: 'userId')
  final int userId;

  @JsonKey(name: 'citizenId')
  final int? citizenId;

  @JsonKey(name: 'fullName')
  final String fullName;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'mobilePhones')
  final String mobilePhones;

  @JsonKey(name: 'birthDate')
  final String? birthDate;

  @JsonKey(name: 'gender')
  final int? gender;

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'notes')
  final String? notes;

  @JsonKey(name: 'status')
  final bool status;

  @JsonKey(name: 'isActive')
  final bool isActive;

  @JsonKey(name: 'recordDate')
  final String recordDate;

  @JsonKey(name: 'updateContactDate')
  final String? updateContactDate;

  @JsonKey(name: 'avatarUrl')
  final String? avatarUrl;

  @JsonKey(name: 'avatarThumbnailUrl')
  final String? avatarThumbnailUrl;

  @JsonKey(name: 'avatarUpdatedDate')
  final String? avatarUpdatedDate;

  @JsonKey(name: 'registrationReferralCode')
  final String? registrationReferralCode;

  @JsonKey(name: 'deactivatedDate')
  final String? deactivatedDate;

  @JsonKey(name: 'deactivationReason')
  final String? deactivationReason;

  FarmerProfileDto({
    required this.userId,
    this.citizenId,
    required this.fullName,
    required this.email,
    required this.mobilePhones,
    this.birthDate,
    this.gender,
    this.address,
    this.notes,
    required this.status,
    required this.isActive,
    required this.recordDate,
    this.updateContactDate,
    this.avatarUrl,
    this.avatarThumbnailUrl,
    this.avatarUpdatedDate,
    this.registrationReferralCode,
    this.deactivatedDate,
    this.deactivationReason,
  });

  factory FarmerProfileDto.fromJson(Map<String, dynamic> json) =>
      _$FarmerProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FarmerProfileDtoToJson(this);

  /// Convert DTO to domain entity
  FarmerProfile toEntity() {
    return FarmerProfile(
      userId: userId,
      citizenId: citizenId,
      fullName: fullName,
      email: email,
      mobilePhones: mobilePhones,
      birthDate: birthDate != null ? DateTime.tryParse(birthDate!) : null,
      gender: gender,
      address: address,
      notes: notes,
      status: status,
      isActive: isActive,
      recordDate: DateTime.parse(recordDate),
      updateContactDate: updateContactDate != null
          ? DateTime.tryParse(updateContactDate!)
          : null,
      avatarUrl: avatarUrl,
      avatarThumbnailUrl: avatarThumbnailUrl,
      avatarUpdatedDate: avatarUpdatedDate != null
          ? DateTime.tryParse(avatarUpdatedDate!)
          : null,
      registrationReferralCode: registrationReferralCode,
      deactivatedDate: deactivatedDate != null
          ? DateTime.tryParse(deactivatedDate!)
          : null,
      deactivationReason: deactivationReason,
    );
  }
}
