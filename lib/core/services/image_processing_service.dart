import "dart:io";
import "dart:typed_data";
import "dart:convert";
import "../error/plant_analysis_exceptions.dart";

/// Service for image processing and validation
class ImageProcessingService {
  /// Maximum allowed file size (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Allowed image formats
  static const List<String> allowedFormats = ["jpg", "jpeg", "png"];

  /// Validate image file
  static Future<Map<String, dynamic>> validateImage(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        throw ImageValidationException(
          "Seçilen dosya bulunamadı",
          validationType: "file_exists",
        );
      }

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        throw ImageValidationException(
          "Dosya boyutu çok büyük (maksimum 10MB)",
          validationType: "file_size",
        );
      }

      // Check file format
      final fileName = imageFile.path.toLowerCase();
      final hasValidExtension = allowedFormats.any((format) => fileName.endsWith(".$format"));
      
      if (!hasValidExtension) {
        throw ImageValidationException(
          "Desteklenmeyen dosya formatı (sadece JPG, PNG)",
          validationType: "file_format",
        );
      }

      return {
        "isValid": true,
        "fileSize": fileSize,
        "fileName": imageFile.path.split("/").last,
      };
    } catch (e) {
      if (e is ImageValidationException) {
        rethrow;
      }
      throw ImageProcessingException(
        "Dosya doğrulama hatası: ${e.toString()}",
        processingStage: "validation",
        originalError: e,
      );
    }
  }

  /// Convert image to base64 with compression
  static Future<String> convertToBase64(File imageFile) async {
    try {
      // Validate image first
      await validateImage(imageFile);

      // Read file as bytes
      final Uint8List bytes = await imageFile.readAsBytes();
      
      // Get MIME type based on file extension
      final String fileName = imageFile.path.toLowerCase();
      String mimeType = "image/jpeg"; // default
      
      if (fileName.endsWith(".png")) {
        mimeType = "image/png";
      } else if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg")) {
        mimeType = "image/jpeg";
      }

      // Convert to base64
      final base64String = base64Encode(bytes);
      
      // Return with data URL format
      return "data:$mimeType;base64,$base64String";
    } catch (e) {
      if (e is PlantAnalysisException) {
        rethrow;
      }
      throw ImageProcessingException(
        "Base64 dönüştürme hatası: ${e.toString()}",
        processingStage: "base64_conversion",
        originalError: e,
      );
    }
  }

  /// Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }
}
