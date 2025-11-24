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
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestStoragePermission() async {
    try {
      developer.log('Requesting storage permission...', name: 'PermissionService');
      
      final status = await Permission.photos.request();
      _permissionCache[Permission.photos] = status;
      
      developer.log('Storage permission status: $status', name: 'PermissionService');
      return status.isGranted;
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
      return await openAppSettings();
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

  /// Check if storage permission is granted (cached)
  Future<bool> isStorageGranted() async {
    final status = await checkPermissionStatus(Permission.photos);
    return status.isGranted;
  }
}
