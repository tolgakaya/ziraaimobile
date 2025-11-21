import 'package:equatable/equatable.dart';

/// Farmer profile entity representing user profile data
/// Matches backend FarmerProfileDto structure
class FarmerProfile extends Equatable {
  final int userId;
  final int? citizenId;
  final String fullName;
  final String? email;
  final String mobilePhones;
  final DateTime? birthDate;
  final int? gender; // 0=Unspecified, 1=Male, 2=Female
  final String? address;
  final String? notes;
  final bool status;
  final bool isActive;
  final DateTime recordDate;
  final DateTime? updateContactDate;
  final String? avatarUrl;
  final String? avatarThumbnailUrl;
  final DateTime? avatarUpdatedDate;
  final String? registrationReferralCode;
  final DateTime? deactivatedDate;
  final String? deactivationReason;

  const FarmerProfile({
    required this.userId,
    this.citizenId,
    required this.fullName,
    this.email,
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

  /// Helper to get gender display name in Turkish
  String get genderDisplayName {
    switch (gender) {
      case 1:
        return 'Erkek';
      case 2:
        return 'Kadın';
      default:
        return 'Belirtilmemiş';
    }
  }

  /// Helper to check if profile has avatar
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  @override
  List<Object?> get props => [
        userId,
        citizenId,
        fullName,
        email,
        mobilePhones,
        birthDate,
        gender,
        address,
        notes,
        status,
        isActive,
        recordDate,
        updateContactDate,
        avatarUrl,
        avatarThumbnailUrl,
        avatarUpdatedDate,
        registrationReferralCode,
        deactivatedDate,
        deactivationReason,
      ];
}
