import 'dart:async';

/// Mock sponsorship service for testing sponsorship flow
class MockSponsorshipService {
  /// Request sponsorship from companies
  static Future<SponsorshipRequestResult> requestSponsorship({
    required String farmerName,
    required String phone,
    required String email,
    required String farmSize,
    required List<String> cropTypes,
    required String location,
    required String reason,
  }) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock validation
    if (phone.length < 10) {
      return SponsorshipRequestResult(
        success: false,
        message: 'Geçersiz telefon numarası',
      );
    }
    
    // Mock success
    return SponsorshipRequestResult(
      success: true,
      message: 'Sponsorluk talebiniz başarıyla gönderildi. En kısa sürede size dönüş yapılacaktır.',
      requestId: 'REQ${DateTime.now().millisecondsSinceEpoch}',
      estimatedResponseTime: '2-3 iş günü',
    );
  }
  
  /// Get available sponsor companies
  static Future<List<SponsorCompany>> getSponsorCompanies() async {
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      SponsorCompany(
        id: '1',
        name: 'Tarım Kredi Kooperatifi',
        logo: 'assets/logos/tarim_kredi.png',
        description: 'Türkiye\'nin en büyük tarım kooperatifi',
        sectors: ['Tahıl', 'Sebze', 'Meyve'],
        tierOffered: 'Premium',
        activeSponsors: 1250,
      ),
      SponsorCompany(
        id: '2',
        name: 'Çukobirlik',
        logo: 'assets/logos/cukobirlik.png',
        description: 'Pamuk ve yağlı tohumlar birliği',
        sectors: ['Pamuk', 'Ayçiçeği', 'Soya'],
        tierOffered: 'Pro',
        activeSponsors: 850,
      ),
      SponsorCompany(
        id: '3',
        name: 'Migros Tarım',
        logo: 'assets/logos/migros.png',
        description: 'Sözleşmeli tarım programı',
        sectors: ['Organik Tarım', 'Sebze', 'Meyve'],
        tierOffered: 'Premium',
        activeSponsors: 450,
      ),
      SponsorCompany(
        id: '4',
        name: 'Ülker Tarım',
        logo: 'assets/logos/ulker.png',
        description: 'Tahıl ve yağlı tohum alımı',
        sectors: ['Buğday', 'Arpa', 'Ayçiçeği'],
        tierOffered: 'Enterprise',
        activeSponsors: 2100,
      ),
    ];
  }
  
  /// Track sponsorship request status
  static Future<SponsorshipStatus> trackRequest(String requestId) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock different statuses based on request ID
    final mockStatus = DateTime.now().millisecondsSinceEpoch % 3;
    
    switch (mockStatus) {
      case 0:
        return SponsorshipStatus(
          requestId: requestId,
          status: 'pending',
          statusText: 'İnceleniyor',
          lastUpdate: DateTime.now().subtract(const Duration(hours: 2)),
          message: 'Talebiniz inceleme aşamasında.',
        );
      case 1:
        return SponsorshipStatus(
          requestId: requestId,
          status: 'approved',
          statusText: 'Onaylandı',
          lastUpdate: DateTime.now().subtract(const Duration(hours: 1)),
          message: 'Tebrikler! Sponsorluk talebiniz onaylandı.',
          sponsorCode: 'DEMO2025',
        );
      default:
        return SponsorshipStatus(
          requestId: requestId,
          status: 'reviewing',
          statusText: 'Değerlendiriliyor',
          lastUpdate: DateTime.now().subtract(const Duration(minutes: 30)),
          message: 'Talebiniz sponsor firma tarafından değerlendiriliyor.',
        );
    }
  }
  
  /// Get sponsorship history
  static Future<List<SponsorshipHistory>> getSponsorshipHistory() async {
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      SponsorshipHistory(
        requestId: 'REQ001',
        requestDate: DateTime.now().subtract(const Duration(days: 30)),
        companyName: 'Tarım Kredi Kooperatifi',
        status: 'approved',
        tierProvided: 'Premium',
        validUntil: DateTime.now().add(const Duration(days: 335)),
      ),
      SponsorshipHistory(
        requestId: 'REQ002',
        requestDate: DateTime.now().subtract(const Duration(days: 60)),
        companyName: 'Çukobirlik',
        status: 'rejected',
        rejectionReason: 'Bölge dışı',
      ),
    ];
  }
}

/// Sponsorship request result
class SponsorshipRequestResult {
  final bool success;
  final String message;
  final String? requestId;
  final String? estimatedResponseTime;
  
  SponsorshipRequestResult({
    required this.success,
    required this.message,
    this.requestId,
    this.estimatedResponseTime,
  });
}

/// Sponsor company model
class SponsorCompany {
  final String id;
  final String name;
  final String logo;
  final String description;
  final List<String> sectors;
  final String tierOffered;
  final int activeSponsors;
  
  SponsorCompany({
    required this.id,
    required this.name,
    required this.logo,
    required this.description,
    required this.sectors,
    required this.tierOffered,
    required this.activeSponsors,
  });
}

/// Sponsorship status model
class SponsorshipStatus {
  final String requestId;
  final String status;
  final String statusText;
  final DateTime lastUpdate;
  final String message;
  final String? sponsorCode;
  
  SponsorshipStatus({
    required this.requestId,
    required this.status,
    required this.statusText,
    required this.lastUpdate,
    required this.message,
    this.sponsorCode,
  });
}

/// Sponsorship history model
class SponsorshipHistory {
  final String requestId;
  final DateTime requestDate;
  final String companyName;
  final String status;
  final String? tierProvided;
  final DateTime? validUntil;
  final String? rejectionReason;
  
  SponsorshipHistory({
    required this.requestId,
    required this.requestDate,
    required this.companyName,
    required this.status,
    this.tierProvided,
    this.validUntil,
    this.rejectionReason,
  });
}