import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'analysis_options_screen.dart';
import '../../../../core/widgets/farmer_bottom_nav.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../subscription/services/subscription_service.dart';
import '../../../referral/presentation/screens/referral_link_generation_screen.dart';
import '../../../referral/presentation/bloc/referral_bloc.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final PermissionService _permissionService = getIt<PermissionService>();
  final SubscriptionService _subscriptionService = getIt<SubscriptionService>();

  bool _isCheckingQuota = true;
  bool _quotaExceeded = false;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionQuota();
  }

  /// Check subscription quota on screen load
  Future<void> _checkSubscriptionQuota() async {
    try {
      print('🔍 Checking subscription quota...');
      final usageStatus = await _subscriptionService.getUsageStatus();

      if (usageStatus != null && usageStatus.isQuotaExceeded) {
        print('⚠️ Quota exceeded! Showing referral screen...');
        setState(() {
          _quotaExceeded = true;
          _isCheckingQuota = false;
        });

        // Show referral dialog after a brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showQuotaExceededDialog(usageStatus);
          }
        });
      } else {
        print('✅ Quota available, proceeding normally');
        setState(() {
          _quotaExceeded = false;
          _isCheckingQuota = false;
        });
      }
    } catch (e) {
      print('❌ Error checking quota: $e');
      // On error, allow user to proceed (fail open)
      setState(() {
        _quotaExceeded = false;
        _isCheckingQuota = false;
      });
    }
  }

  /// Show dialog when quota is exceeded
  void _showQuotaExceededDialog(usageStatus) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 24),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Analiz Hakkınız Doldu',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usageStatus.getStatusMessage(),
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4), // green-50
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)), // green-300
                ),
                child: const Row(
                  children: [
                    Icon(Icons.card_giftcard, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Arkadaşlarınızı davet ederek ek kredi kazanabilirsiniz!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('Geri Dön'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate directly to referral link generation screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => getIt<ReferralBloc>(),
                    child: const ReferralLinkGenerationScreen(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.people, size: 16),
            label: const Text(
              'Arkadaş Davet Et',
              style: TextStyle(fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFromCamera() async {
    try {
      // Check if already granted
      final alreadyGranted = await _permissionService.isCameraGranted();

      if (alreadyGranted) {
        print('✅ Camera permission already granted');
        await _openCamera();
        return;
      }

      // Request permission - MainActivity now handles the telephony conflict
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

      print('✅ Camera permission granted');
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
            child: _isCheckingQuota
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _quotaExceeded ? null : _selectFromCamera,
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
                          onPressed: _quotaExceeded ? null : _selectFromGallery,
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