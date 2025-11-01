import 'dealer_code.dart';

/// Paginated response for dealer codes
///
/// Backend returns:
/// {
///   "data": {
///     "codes": [...],
///     "totalCount": 100,
///     "page": 1,
///     "pageSize": 50,
///     ...
///   }
/// }
class PaginatedDealerCodes {
  final List<DealerCode> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  PaginatedDealerCodes({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory PaginatedDealerCodes.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final codesJson = data['codes'] as List<dynamic>;

    return PaginatedDealerCodes(
      items: codesJson.map((json) => DealerCode.fromJson(json)).toList(),
      totalCount: data['totalCount'] as int,
      page: data['page'] as int,
      pageSize: data['pageSize'] as int,
      totalPages: data['totalPages'] as int,
      hasPreviousPage: data['hasPreviousPage'] as bool,
      hasNextPage: data['hasNextPage'] as bool,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  @override
  String toString() {
    return 'PaginatedDealerCodes(items: ${items.length}, totalCount: $totalCount, '
        'page: $page/$totalPages, hasNext: $hasNextPage)';
  }
}
