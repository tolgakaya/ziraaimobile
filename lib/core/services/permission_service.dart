import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

/// Centralized Permission Management Service
/// Handles all app permissions in one place to prevent conflicts and crashes
/// 
/// This service provides:
/// - Single source of truth for permission requests
/// - Proper error handling to prevent crashes
/// - Permission status caching
/// - Consistent logging
class PermissionService {
  // Singleton instance
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Cache permission statuses to avoid excessive checks
  final Map<Permission, PermissionStatus> _permissionCache = {};

  /// Request camera permission with proper error handling
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestCameraPermission() async {
    try {
      developer.log('Requesting camera permission...', name: 'PermissionService');
      
      final status = await Permission.camera.request();
      _permissionCache[Permission.camera] = status;
      
      developer.log('Camera permission status: $status', name: 'PermissionService');
      return status.isGranted;
    } catch (e, stackTrace) {
      developer.log(
        'Error requesting camera permission: $e',
        name: 'PermissionService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Request storage/photos permission with proper error handling
  /// Android 13+ (API 33+): Uses Permission.photos (READ_MEDIA_IMAGES)
  /// Android 12 and below: Uses Permission.storage (READ_EXTERNAL_STORAGE)
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestStoragePermission() async {
    try {
      developer.log('Requesting storage/photos permission...', name: 'PermissionService');

      // Try photos permission first (Android 13+ / API 33+)
      developer.log('Checking photos permission status...', name: 'PermissionService');
      final photosStatus = await Permission.photos.status;

      if (photosStatus.isGranted) {
        developer.log('Photos permission already granted (Android 13+)', name: 'PermissionService');
        _permissionCache[Permission.photos] = photosStatus;
        return true;
      }

      // If photos permission is not granted, try requesting it (Android 13+)
      if (!photosStatus.isPermanentlyDenied) {
        developer.log('Requesting photos permission (Android 13+)...', name: 'PermissionService');
        final requestedPhotosStatus = await Permission.photos.request();
        _permissionCache[Permission.photos] = requestedPhotosStatus;

        if (requestedPhotosStatus.isGranted) {
          developer.log('Photos permission granted (Android 13+)', name: 'PermissionService');
          return true;
        }
      }

      // Fallback to storage permission (Android 12 and below / API 32 and below)
      developer.log('Checking storage permission status (Android 12 and below)...', name: 'PermissionService');
      final storageStatus = await Permission.storage.status;

      if (storageStatus.isGranted) {
        developer.log('Storage permission already granted (Android 12 and below)', name: 'PermissionService');
        _permissionCache[Permission.storage] = storageStatus;
        return true;
      }

      if (!storageStatus.isPermanentlyDenied) {
        developer.log('Requesting storage permission (Android 12 and below)...', name: 'PermissionService');
        final requestedStorageStatus = await Permission.storage.request();
        _permissionCache[Permission.storage] = requestedStorageStatus;

        if (requestedStorageStatus.isGranted) {
          developer.log('Storage permission granted (Android 12 and below)', name: 'PermissionService');
          return true;
        }
      }

      developer.log('Gallery/storage permission not granted', name: 'PermissionService');
      return false;
    } catch (e, stackTrace) {
      developer.log(
        'Error requesting storage permission: $e',
        name: 'PermissionService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Request microphone permission with proper error handling
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestMicrophonePermission() async {
    try {
      developer.log('Requesting microphone permission...', name: 'PermissionService');
      
      final status = await Permission.microphone.request();
      _permissionCache[Permission.microphone] = status;
      
      developer.log('Microphone permission status: $status', name: 'PermissionService');
      return status.isGranted;
    } catch (e, stackTrace) {
      developer.log(
        'Error requesting microphone permission: $e',
        name: 'PermissionService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Request contacts permission with proper error handling
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestContactsPermission() async {
    try {
      developer.log('Requesting contacts permission...', name: 'PermissionService');
      
      final status = await Permission.contacts.request();
      _permissionCache[Permission.contacts] = status;
      
      developer.log('Contacts permission status: $status', name: 'PermissionService');
      return status.isGranted;
    } catch (e, stackTrace) {
      developer.log(
        'Error requesting contacts permission: $e',
        name: 'PermissionService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check permission status without requesting
  /// Returns current permission status
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    try {
      // Check cache first
      if (_permissionCache.containsKey(permission)) {
        return _permissionCache[permission]!;
      }
      
      // Query actual status
      final status = await permission.status;
      _permissionCache[permission] = status;
      return status;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking permission status: $e',
        name: 'PermissionService',
        error: e,
        stackTrace: stackTrace,
      );
      return PermissionStatus.denied;
    }
  }

  /// Open app settings for manual permission grant
  /// Returns true if settings were opened successfully
  Future<bool> openAppSettings() async {
    try {
      developer.log('Opening app settings...', name: 'PermissionService');
      return await permission_handler.openAppSettings();
    } catch (e, stackTrace) {
      developer.log(
        'Error opening app settings: $e',
        name: 'PermissionService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Clear permission cache (useful after returning from app settings)
  void clearCache() {
    developer.log('Clearing permission cache', name: 'PermissionService');
    _permissionCache.clear();
  }

  /// Check if camera permission is granted (cached)
  Future<bool> isCameraGranted() async {
    final status = await checkPermissionStatus(Permission.camera);
    return status.isGranted;
  }

  /// Check if microphone permission is granted (cached)
  Future<bool> isMicrophoneGranted() async {
    final status = await checkPermissionStatus(Permission.microphone);
    return status.isGranted;
  }

  /// Check if contacts permission is granted (cached)
  Future<bool> isContactsGranted() async {
    final status = await checkPermissionStatus(Permission.contacts);
    return status.isGranted;
  }

  /// Check if storage/photos permission is granted (cached)
  /// Checks both Permission.photos (Android 13+) and Permission.storage (Android 12 and below)
  Future<bool> isStorageGranted() async {
    // Try photos permission first (Android 13+)
    final photosStatus = await checkPermissionStatus(Permission.photos);
    if (photosStatus.isGranted) {
      return true;
    }

    // Fallback to storage permission (Android 12 and below)
    final storageStatus = await checkPermissionStatus(Permission.storage);
    return storageStatus.isGranted;
  }
}
