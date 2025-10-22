import 'package:json_annotation/json_annotation.dart';

part 'plant_analysis_response.g.dart';

@JsonSerializable()
class PlantAnalysisResponse {
  final bool success;
  final PlantAnalysisData? data;
  final String? message;
  final String? errorCode;

  PlantAnalysisResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });

  factory PlantAnalysisResponse.fromJson(Map<String, dynamic> json) =>
      _$PlantAnalysisResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlantAnalysisResponseToJson(this);
}

@JsonSerializable()
class PlantAnalysisData {
  final String analysisId;
  final String status;
  final DateTime? estimatedCompletionTime;
  final String? message;

  PlantAnalysisData({
    required this.analysisId,
    required this.status,
    this.estimatedCompletionTime,
    this.message,
  });

  factory PlantAnalysisData.fromJson(Map<String, dynamic> json) =>
      _$PlantAnalysisDataFromJson(json);

  Map<String, dynamic> toJson() => _$PlantAnalysisDataToJson(this);
}

@JsonSerializable()
class PlantAnalysisListResponse {
  final List<PlantAnalysisListItem> analyses;
  final dynamic pagination; // Optional, backend may not send

  PlantAnalysisListResponse({
    required this.analyses,
    this.pagination,
  });

  factory PlantAnalysisListResponse.fromJson(Map<String, dynamic> json) =>
      _$PlantAnalysisListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlantAnalysisListResponseToJson(this);
}

@JsonSerializable()
class PlantAnalysisListItem {
  final int? id; // Numeric ID from backend
  final String? analysisId;
  final String? plantSpecies;
  final String? status;
  final DateTime? createdDate;
  final String? thumbnailUrl;
  final String? primaryConcern;

  PlantAnalysisListItem({
    this.id,
    this.analysisId,
    this.plantSpecies,
    this.status,
    this.createdDate,
    this.thumbnailUrl,
    this.primaryConcern,
  });

  factory PlantAnalysisListItem.fromJson(Map<String, dynamic> json) =>
      _$PlantAnalysisListItemFromJson(json);

  Map<String, dynamic> toJson() => _$PlantAnalysisListItemToJson(this);
}