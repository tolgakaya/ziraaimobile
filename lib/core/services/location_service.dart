import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

/// ✅ Location Service with safe permission handling
/// Provides automatic location fetching for plant analysis
/// Handles all permission states gracefully without throwing errors
@lazySingleton
class LocationService {
  /// Get current location coordinates as string
  /// Returns null if location unavailable or permission denied
  /// Format: "Latitude: X.XXXX, Longitude: Y.YYYY"
  Future<String?> getCurrentLocationString() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      return 'Latitude: ${position.latitude.toStringAsFixed(4)}, Longitude: ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      print('⚠️ LocationService: Error getting location string: $e');
      return null;
    }
  }

  /// Get current location coordinates as formatted city/region string
  /// Returns null if reverse geocoding unavailable
  /// Note: For city name, you'll need geocoding package (not included to keep dependencies minimal)
  Future<String?> getCurrentLocationCity() async {
    // TODO: Add geocoding package if you need city names
    // For now, just returns coordinates
    return getCurrentLocationString();
  }

  /// Get current GPS position
  /// Returns null if:
  /// - Location services disabled
  /// - Permission denied or permanently denied
  /// - Timeout occurs
  /// Does NOT throw exceptions - returns null on any error
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ LocationService: Location services are disabled');
        return null;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // If denied, try to request permission (won't show dialog if permanently denied)
      if (permission == LocationPermission.denied) {
        print('📍 LocationService: Requesting location permission...');
        permission = await Geolocator.requestPermission();
      }

      // Handle all permission states
      if (permission == LocationPermission.denied) {
        print('⚠️ LocationService: Location permission denied by user');
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ LocationService: Location permission permanently denied');
        return null;
      }

      // Permission granted - get current position with timeout
      print('✅ LocationService: Permission granted, getting position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // 10 second timeout
      );

      print('✅ LocationService: Got position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      // Catch any errors (timeout, network issues, etc.)
      print('⚠️ LocationService: Error getting position: $e');
      return null;
    }
  }

  /// Check if location services are available
  /// Returns true only if services enabled AND permission granted
  Future<bool> isLocationAvailable() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('⚠️ LocationService: Error checking availability: $e');
      return false;
    }
  }

  /// Open app settings for user to enable location permission
  /// Call this when permission is permanently denied
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      print('⚠️ LocationService: Error opening settings: $e');
      return false;
    }
  }

  /// Open location services settings (system settings)
  Future<bool> openLocationServicesSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      print('⚠️ LocationService: Error opening location settings: $e');
      return false;
    }
  }
}
