import 'package:json_annotation/json_annotation.dart';
import 'sponsored_analysis_summary.dart';

part 'sponsored_analyses_list_response.g.dart';

/// Paginated response wrapper for sponsored analyses list
/// Matches backend response from GET /api/v1/sponsorship/analyses
@JsonSerializable()
class SponsoredAnalysesListResponse {
  final List<SponsoredAnalysisSummary> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final SponsoredAnalysesListSummary? summary;

  SponsoredAnalysesListResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.summary,
  });

  factory SponsoredAnalysesListResponse.fromJson(Map<String, dynamic> json) =>
      _$SponsoredAnalysesListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SponsoredAnalysesListResponseToJson(this);
}

/// Summary statistics for the analyses list
@JsonSerializable()
class SponsoredAnalysesListSummary {
  final int totalAnalyses;
  final double averageHealthScore;
  final List<String> topCropTypes;
  final int analysesThisMonth;
  final int? analysesWithUnread;

  SponsoredAnalysesListSummary({
    required this.totalAnalyses,
    required this.averageHealthScore,
    required this.topCropTypes,
    required this.analysesThisMonth,
    this.analysesWithUnread,
  });

  factory SponsoredAnalysesListSummary.fromJson(Map<String, dynamic> json) =>
      _$SponsoredAnalysesListSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$SponsoredAnalysesListSummaryToJson(this);
}
