import 'sponsorship_code.dart';

/// Paginated response for sponsorship codes from backend API
///
/// Backend returns paginated data structure:
/// {
///   "success": true,
///   "data": {
///     "items": [...],
///     "totalCount": 100,
///     "page": 1,
///     "pageSize": 50,
///     "totalPages": 2,
///     "hasPreviousPage": false,
///     "hasNextPage": true
///   }
/// }
class PaginatedSponsorshipCodes {
  final List<SponsorshipCode> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  PaginatedSponsorshipCodes({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory PaginatedSponsorshipCodes.fromJson(Map<String, dynamic> json) {
    return PaginatedSponsorshipCodes(
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => SponsorshipCode.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 50,
      totalPages: json['totalPages'] as int? ?? 0,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'totalCount': totalCount,
      'page': page,
      'pageSize': pageSize,
      'totalPages': totalPages,
      'hasPreviousPage': hasPreviousPage,
      'hasNextPage': hasNextPage,
    };
  }

  /// Check if there are no codes at all
  bool get isEmpty => items.isEmpty;

  /// Get count of items in current page
  int get itemCount => items.length;

  /// Create an empty paginated result
  factory PaginatedSponsorshipCodes.empty() {
    return PaginatedSponsorshipCodes(
      items: [],
      totalCount: 0,
      page: 1,
      pageSize: 50,
      totalPages: 0,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }
}
