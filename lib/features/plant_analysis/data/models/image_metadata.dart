import 'package:json_annotation/json_annotation.dart';

part 'image_metadata.g.dart';

/// Image metadata for plant analysis
/// Supports both single-image and multi-image analyses
@JsonSerializable()
class ImageMetadata {
  /// Main image URL (always present)
  final String imageUrl;

  /// Total number of images (null for single-image analyses)
  @JsonKey(includeIfNull: false)
  final int? totalImages;

  /// List of image types provided (e.g., ["main", "leaf_top", "leaf_bottom"])
  @JsonKey(includeIfNull: false)
  final List<String>? imagesProvided;

  /// Whether leaf top image is available
  @JsonKey(includeIfNull: false)
  final bool? hasLeafTop;

  /// Whether leaf bottom image is available
  @JsonKey(includeIfNull: false)
  final bool? hasLeafBottom;

  /// Whether plant overview image is available
  @JsonKey(includeIfNull: false)
  final bool? hasPlantOverview;

  /// Whether root image is available
  @JsonKey(includeIfNull: false)
  final bool? hasRoot;

  /// Leaf top image URL (if available)
  @JsonKey(includeIfNull: false)
  final String? leafTopImageUrl;

  /// Leaf bottom image URL (if available)
  @JsonKey(includeIfNull: false)
  final String? leafBottomImageUrl;

  /// Plant overview image URL (if available)
  @JsonKey(includeIfNull: false)
  final String? plantOverviewImageUrl;

  /// Root system image URL (if available)
  @JsonKey(includeIfNull: false)
  final String? rootImageUrl;

  ImageMetadata({
    required this.imageUrl,
    this.totalImages,
    this.imagesProvided,
    this.hasLeafTop,
    this.hasLeafBottom,
    this.hasPlantOverview,
    this.hasRoot,
    this.leafTopImageUrl,
    this.leafBottomImageUrl,
    this.plantOverviewImageUrl,
    this.rootImageUrl,
  });

  factory ImageMetadata.fromJson(Map<String, dynamic> json) =>
      _$ImageMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ImageMetadataToJson(this);

  /// Check if this is a multi-image analysis
  bool get isMultiImage => totalImages != null && totalImages! > 1;

  /// Get list of all available images with their types and URLs
  List<ImageItem> getImageList() {
    final images = <ImageItem>[
      ImageItem(type: 'Ana Görsel', url: imageUrl),
    ];

    if (leafTopImageUrl != null) {
      images.add(ImageItem(type: 'Yaprak Üstü', url: leafTopImageUrl!));
    }
    if (leafBottomImageUrl != null) {
      images.add(ImageItem(type: 'Yaprak Altı', url: leafBottomImageUrl!));
    }
    if (plantOverviewImageUrl != null) {
      images.add(ImageItem(type: 'Bitki Genel', url: plantOverviewImageUrl!));
    }
    if (rootImageUrl != null) {
      images.add(ImageItem(type: 'Kök Sistemi', url: rootImageUrl!));
    }

    return images;
  }
}

/// Helper class to represent a single image in the gallery
class ImageItem {
  final String type;
  final String url;

  ImageItem({
    required this.type,
    required this.url,
  });
}
