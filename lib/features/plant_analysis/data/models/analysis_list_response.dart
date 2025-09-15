import 'package:json_annotation/json_annotation.dart';

part 'analysis_list_response.g.dart';

@JsonSerializable()
class AnalysisListResponse {
  final bool success;
  final AnalysisListData? data;
  final String? message;

  AnalysisListResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory AnalysisListResponse.fromJson(Map<String, dynamic> json) =>
      _$AnalysisListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisListResponseToJson(this);
}

@JsonSerializable()
class AnalysisListData {
  final List<AnalysisSummary> analyses;
  final PaginationInfo pagination;

  AnalysisListData({
    required this.analyses,
    required this.pagination,
  });

  factory AnalysisListData.fromJson(Map<String, dynamic> json) =>
      _$AnalysisListDataFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisListDataToJson(this);
}

@JsonSerializable()
class AnalysisSummary {
  final String id;
  final String? plantType;
  final String? healthStatus;
  final DateTime date;
  final String? thumbnailUrl;

  AnalysisSummary({
    required this.id,
    this.plantType,
    this.healthStatus,
    required this.date,
    this.thumbnailUrl,
  });

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) =>
      _$AnalysisSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisSummaryToJson(this);
}

@JsonSerializable()
class PaginationInfo {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) =>
      _$PaginationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationInfoToJson(this);
}