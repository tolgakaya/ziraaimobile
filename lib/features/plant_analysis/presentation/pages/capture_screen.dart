import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'analysis_options_screen.dart';
import '../../../../core/widgets/farmer_bottom_nav.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/utils/minimal_service_locator.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final PermissionService _permissionService = getIt<PermissionService>();

  Future<void> _selectFromCamera() async {
    try {
      // Check if already granted to skip dialog entirely
      final alreadyGranted = await _permissionService.isCameraGranted();

      if (alreadyGranted) {
        // Permission already granted, directly open camera
        print('✅ Camera permission already granted, opening camera directly');
        await _openCamera();
        return;
      }

      // Request permission if not granted
      print('🔐 Requesting camera permission...');
      final granted = await _permissionService.requestCameraPermission();

      if (!granted) {
        print('❌ Camera permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kamera izni gerekli'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      print('✅ Camera permission granted, waiting for app to stabilize...');

      // CRITICAL FIX: Longer delay after permission grant (increased from 300ms to 1000ms)
      // This prevents crash when permission dialog closes and activity resumes
      await Future.delayed(const Duration(milliseconds: 1000));

      // Verify widget is still mounted before proceeding
      if (!mounted) {
        print('⚠️ Widget disposed during permission request');
        return;
      }

      // Double-check permission is still granted before using camera
      final isStillGranted = await _permissionService.isCameraGranted();
      if (!isStillGranted) {
        print('❌ Camera permission lost after grant');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kamera izni alınamadı'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      print('🎥 Opening camera...');
      await _openCamera();
    } catch (e, stackTrace) {
      print('❌ Camera error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera hatası: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _openCamera() async {
    try {
      // Use image_picker only after permission is granted and verified
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _navigateToAnalysisOptions();
      }
    } catch (e, stackTrace) {
      print('❌ ImagePicker error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      // Check if already granted to skip dialog entirely
      final alreadyGranted = await _permissionService.isStorageGranted();

      if (alreadyGranted) {
        // Permission already granted, directly open gallery
        print('✅ Gallery permission already granted, opening gallery directly');
        await _openGallery();
        return;
      }

      // Request permission if not granted
      print('🔐 Requesting gallery permission...');
      final granted = await _permissionService.requestStoragePermission();

      if (!granted) {
        print('❌ Gallery permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Galeri izni gerekli'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      print('✅ Gallery permission granted, waiting for app to stabilize...');

      // CRITICAL FIX: Longer delay after permission grant (increased from 300ms to 1000ms)
      await Future.delayed(const Duration(milliseconds: 1000));

      // Verify widget is still mounted before proceeding
      if (!mounted) {
        print('⚠️ Widget disposed during permission request');
        return;
      }

      // Double-check permission is still granted
      final isStillGranted = await _permissionService.isStorageGranted();
      if (!isStillGranted) {
        print('❌ Gallery permission lost after grant');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Galeri izni alınamadı'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      print('📸 Opening gallery...');
      await _openGallery();
    } catch (e, stackTrace) {
      print('❌ Gallery error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Galeri hatası: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _openGallery() async {
    try {
      // Use image_picker only after permission is granted and verified
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _navigateToAnalysisOptions();
      }
    } catch (e, stackTrace) {
      print('❌ ImagePicker gallery error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _navigateToAnalysisOptions() {
    if (_selectedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisOptionsScreen(
            selectedImage: _selectedImage!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Fotoğraf Çek/Seç',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Camera Preview Area
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 64,
                          color: Color(0xFF9CA3AF),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Bitki Fotoğrafı',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Kamera veya galeri kullanarak\\nbitki fotoğrafı ekleyin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FarmerBottomNav(currentIndex: 3),
    );
  }
}