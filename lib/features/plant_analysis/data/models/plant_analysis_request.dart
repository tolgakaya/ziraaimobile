import 'package:json_annotation/json_annotation.dart';

part 'plant_analysis_request.g.dart';

@JsonSerializable()
class PlantAnalysisRequest {
  final String image; // Base64 encoded image
  final String? cropType; // Optional, will be auto-detected
  final String? location;
  final String? notes;

  PlantAnalysisRequest({
    required this.image,
    this.cropType,
    this.location,
    this.notes,
  });

  factory PlantAnalysisRequest.fromJson(Map<String, dynamic> json) =>
      _$PlantAnalysisRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PlantAnalysisRequestToJson(this);
}