/// Sponsor profil güncelleme request modeli
/// Backend endpoint: PUT /api/sponsorship/update-profile
///
/// Bu model partial update'i destekler - sadece değişen alanlar gönderilir
/// Tüm alanlar opsiyoneldir, null olanlar JSON'a dahil edilmez
class UpdateSponsorProfileRequest {
  // Basic Information
  final String? companyName;
  final String? companyDescription;
  final String? contactEmail;
  final String? contactPhone;

  // Social Media URLs
  final String? linkedInUrl;
  final String? twitterUrl;
  final String? facebookUrl;
  final String? instagramUrl;

  // Business Information
  final String? taxNumber;
  final String? tradeRegistryNumber;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;

  // Password change (optional)
  final String? password;

  UpdateSponsorProfileRequest({
    this.companyName,
    this.companyDescription,
    this.contactEmail,
    this.contactPhone,
    this.linkedInUrl,
    this.twitterUrl,
    this.facebookUrl,
    this.instagramUrl,
    this.taxNumber,
    this.tradeRegistryNumber,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    this.password,
  });

  /// Convert to JSON - only includes non-null fields for partial updates
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (companyName != null) data['companyName'] = companyName;
    if (companyDescription != null) data['companyDescription'] = companyDescription;
    if (contactEmail != null) data['contactEmail'] = contactEmail;
    if (contactPhone != null) data['contactPhone'] = contactPhone;
    if (linkedInUrl != null) data['linkedInUrl'] = linkedInUrl;
    if (twitterUrl != null) data['twitterUrl'] = twitterUrl;
    if (facebookUrl != null) data['facebookUrl'] = facebookUrl;
    if (instagramUrl != null) data['instagramUrl'] = instagramUrl;
    if (taxNumber != null) data['taxNumber'] = taxNumber;
    if (tradeRegistryNumber != null) data['tradeRegistryNumber'] = tradeRegistryNumber;
    if (address != null) data['address'] = address;
    if (city != null) data['city'] = city;
    if (country != null) data['country'] = country;
    if (postalCode != null) data['postalCode'] = postalCode;
    if (password != null) data['password'] = password;

    return data;
  }

  /// Check if any fields are set
  bool get isEmpty => toJson().isEmpty;

  /// Check if only password is being updated
  bool get isPasswordOnly => password != null && toJson().length == 1;

  /// Check if social media fields are being updated
  bool get hasSocialMediaUpdate =>
      linkedInUrl != null ||
      twitterUrl != null ||
      facebookUrl != null ||
      instagramUrl != null;

  /// Check if business info fields are being updated
  bool get hasBusinessInfoUpdate =>
      taxNumber != null ||
      tradeRegistryNumber != null ||
      address != null ||
      city != null ||
      country != null ||
      postalCode != null;

  /// Check if basic info fields are being updated
  bool get hasBasicInfoUpdate =>
      companyName != null ||
      companyDescription != null ||
      contactEmail != null ||
      contactPhone != null;

  UpdateSponsorProfileRequest copyWith({
    String? companyName,
    String? companyDescription,
    String? contactEmail,
    String? contactPhone,
    String? linkedInUrl,
    String? twitterUrl,
    String? facebookUrl,
    String? instagramUrl,
    String? taxNumber,
    String? tradeRegistryNumber,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    String? password,
  }) {
    return UpdateSponsorProfileRequest(
      companyName: companyName ?? this.companyName,
      companyDescription: companyDescription ?? this.companyDescription,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      taxNumber: taxNumber ?? this.taxNumber,
      tradeRegistryNumber: tradeRegistryNumber ?? this.tradeRegistryNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      password: password ?? this.password,
    );
  }
}
