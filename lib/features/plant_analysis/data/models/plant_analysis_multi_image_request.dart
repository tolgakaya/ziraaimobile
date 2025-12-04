import 'package:json_annotation/json_annotation.dart';

part 'plant_analysis_multi_image_request.g.dart';

/// Multi-image plant analysis request DTO
/// Supports up to 5 images: 1 main (required) + 4 optional detail images
@JsonSerializable()
class PlantAnalysisMultiImageRequest {
  /// Required: Main image (Base64 data URI format)
  final String image;

  /// Optional: Leaf top view image (Base64 data URI format)
  @JsonKey(includeIfNull: false)
  final String? leafTopImage;

  /// Optional: Leaf bottom view image (Base64 data URI format)
  @JsonKey(includeIfNull: false)
  final String? leafBottomImage;

  /// Optional: Plant overview image (Base64 data URI format)
  @JsonKey(includeIfNull: false)
  final String? plantOverviewImage;

  /// Optional: Root system image (Base64 data URI format)
  @JsonKey(includeIfNull: false)
  final String? rootImage;

  /// Optional: Crop type (e.g., "Domates", "Biber")
  @JsonKey(includeIfNull: false)
  final String? cropType;

  /// Optional: Location information
  @JsonKey(includeIfNull: false)
  final String? location;

  /// Optional: Additional notes
  @JsonKey(includeIfNull: false)
  final String? notes;

  PlantAnalysisMultiImageRequest({
    required this.image,
    this.leafTopImage,
    this.leafBottomImage,
    this.plantOverviewImage,
    this.rootImage,
    this.cropType,
    this.location,
    this.notes,
  });

  factory PlantAnalysisMultiImageRequest.fromJson(Map<String, dynamic> json) =>
      _$PlantAnalysisMultiImageRequestFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PlantAnalysisMultiImageRequestToJson(this);

  /// Get total count of images (including main image)
  int get imageCount {
    int count = 1; // Main image always present
    if (leafTopImage != null) count++;
    if (leafBottomImage != null) count++;
    if (plantOverviewImage != null) count++;
    if (rootImage != null) count++;
    return count;
  }

  /// Check if this is actually a multi-image request (has additional images)
  bool get hasAdditionalImages {
    return leafTopImage != null ||
        leafBottomImage != null ||
        plantOverviewImage != null ||
        rootImage != null;
  }
}
