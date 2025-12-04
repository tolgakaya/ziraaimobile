import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/plant_analysis_repository.dart';
import '../../../../core/services/image_processing_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../../core/error/plant_analysis_exceptions.dart';
import '../../../../core/widgets/error_widgets.dart';
import '../../../subscription/presentation/screens/subscription_status_screen.dart';
import '../../../dashboard/presentation/pages/farmer_dashboard_page.dart';
import '../../../referral/presentation/screens/referral_link_generation_screen.dart';
import '../../../referral/presentation/bloc/referral_bloc.dart';
import '../../../../core/widgets/farmer_bottom_nav.dart';

class AnalysisOptionsScreen extends StatefulWidget {
  final File selectedImage;

  const AnalysisOptionsScreen({
    super.key,
    required this.selectedImage,
  });

  @override
  State<AnalysisOptionsScreen> createState() => _AnalysisOptionsScreenState();
}

class _AnalysisOptionsScreenState extends State<AnalysisOptionsScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  late final PlantAnalysisRepository _repository;
  late final LocationService _locationService;
  final ImagePicker _imagePicker = ImagePicker();

  // Location state
  String? _autoDetectedLocation; // Automatically detected GPS location
  bool _isLoadingLocation = false;

  // Plant type dropdown options
  final List<String> _plantTypes = [
    'Domates',
    'Biber',
    'Salatalık',
    'Patlıcan',
    'Fasulye',
    'Marul',
    'Lahana',
    'Karnabahar',
    'Brokoli',
    'Havuç',
    'Soğan',
    'Sarımsak',
    'Patates',
    'Buğday',
    'Arpa',
    'Mısır',
  ];

  String? _selectedPlantType;
  String _selectedAnalysisType = 'quick'; // 'quick' or 'detailed'
  bool _isSubmitting = false;
  PlantAnalysisException? _currentError;

  // Multi-image support (for detailed analysis)
  File? _leafTopImage;
  File? _leafBottomImage;
  File? _plantOverviewImage;
  File? _rootImage;

  @override
  void initState() {
    super.initState();
    // Initialize services
    _repository = getIt<PlantAnalysisRepository>();
    _locationService = getIt<LocationService>();
    _validateImage();
    // Automatically fetch location in background (silent, non-blocking)
    _fetchLocationInBackground();
  }

  /// Fetch GPS location in background without blocking UI
  /// This runs silently - no error dialogs if location unavailable
  Future<void> _fetchLocationInBackground() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final location = await _locationService.getCurrentLocationString();
      if (mounted) {
        setState(() {
          _autoDetectedLocation = location;
          _isLoadingLocation = false;
        });
        if (location != null) {
          print('✅ Auto-detected location: $location');
        } else {
          print('⚠️ Location not available (permission denied or services disabled)');
        }
      }
    } catch (e) {
      print('⚠️ Background location fetch error: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _validateImage() async {
    try {
      final validation = await ImageProcessingService.validateImage(widget.selectedImage);
      if (validation['isValid'] != true) {
        setState(() {
          _currentError = ImageValidationException(
            'Geçersiz dosya formatı veya boyutu',
            validationType: 'format_or_size',
          );
        });
      }
    } catch (e) {
      setState(() {
        _currentError = ImageProcessingException(
          'Görsel doğrulanamadı',
          processingStage: 'validation',
          originalError: e,
        );
      });
    }
  }

  Future<void> _startAnalysis() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _currentError = null;
    });

    try {
      // Prepare notes with crop type if selected
      String? combinedNotes = _notesController.text.trim();
      if (_selectedPlantType != null) {
        combinedNotes = combinedNotes.isNotEmpty
            ? 'Bitki Türü: $_selectedPlantType\n$combinedNotes'
            : 'Bitki Türü: $_selectedPlantType';
      }

      // ✅ NEW: Smart location handling
      // Priority: User input + Auto-detected location
      final String userLocation = _locationController.text.trim();
      final String? finalLocation = _buildFinalLocation(userLocation, _autoDetectedLocation);

      final String? notes = combinedNotes.isNotEmpty ? combinedNotes : null;

      // Choose endpoint based on analysis type
      final result = _selectedAnalysisType == 'detailed'
          ? await _repository.submitMultiImageAnalysis(
              mainImage: widget.selectedImage,
              leafTopImage: _leafTopImage,
              leafBottomImage: _leafBottomImage,
              plantOverviewImage: _plantOverviewImage,
              rootImage: _rootImage,
              location: finalLocation,
              notes: notes,
            )
          : await _repository.submitAnalysis(
              imageFile: widget.selectedImage,
              location: finalLocation,
              notes: notes,
            );

      if (!mounted) return;

      result.fold(
        // Left - Failure/Error
        (failure) {
          // Special handling for AuthorizationFailure (403 - no subscription)
          if (failure.toString().contains('AuthorizationFailure')) {
            _showNoSubscriptionDialog();
            setState(() {
              _isSubmitting = false;
            });
            return;
          }

          setState(() {
            _currentError = UnknownException(
              failure.toString(),
            );
          });
        },
        // Right - Success
        (data) {
          print('✅ Analysis submitted successfully, navigating back to dashboard...');
          print('   Analysis ID: ${data.analysisId}');
          print('   Status: ${data.status}');
          print('   Widget mounted: $mounted');
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Analiz başarıyla gönderildi!\nAnaliz ID: ${data.analysisId.substring(0, 8)}...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF22C55E),
                duration: const Duration(seconds: 4),
              ),
            );
          }

          // Navigate back to dashboard - async analysis runs in background
          print('🧭 Attempting to navigate back to dashboard...');
          print('   Context mounted: $mounted');
          
          if (mounted) {
            try {
              // Import needed for FarmerDashboardPage
              // Use pushAndRemoveUntil to clear stack and show fresh dashboard
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const FarmerDashboardPage(),
                ),
                (route) => false, // Remove all previous routes including splash
              );
              
              print('✅ Navigation completed - fresh dashboard loaded');
            } catch (e) {
              print('❌ Navigation error: $e');
            }
          } else {
            print('⚠️ Widget not mounted, skipping navigation');
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentError = UnknownException(
          'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
          originalError: e,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Pick additional image for multi-image analysis
  Future<void> _pickImage(ImageType imageType) async {
    // Show modern bottom sheet for source selection
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(Icons.add_photo_alternate, color: Color(0xFF22C55E), size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Resim Kaynağı Seçin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Camera option
              InkWell(
                onTap: () => Navigator.pop(context, ImageSource.camera),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFF22C55E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kamera',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Yeni bir fotoğraf çek',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1, color: Colors.grey.shade200),
              ),

              // Gallery option
              InkWell(
                onTap: () => Navigator.pop(context, ImageSource.gallery),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Color(0xFF22C55E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Galeri',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mevcut fotoğraflardan seç',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Cancel button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return; // User cancelled

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Validate image
        final validation = await ImageProcessingService.validateImage(imageFile);
        if (validation['isValid'] != true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Geçersiz resim formatı veya boyutu'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          switch (imageType) {
            case ImageType.leafTop:
              _leafTopImage = imageFile;
              break;
            case ImageType.leafBottom:
              _leafBottomImage = imageFile;
              break;
            case ImageType.plantOverview:
              _plantOverviewImage = imageFile;
              break;
            case ImageType.root:
              _rootImage = imageFile;
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove additional image
  void _removeImage(ImageType imageType) {
    setState(() {
      switch (imageType) {
        case ImageType.leafTop:
          _leafTopImage = null;
          break;
        case ImageType.leafBottom:
          _leafBottomImage = null;
          break;
        case ImageType.plantOverview:
          _plantOverviewImage = null;
          break;
        case ImageType.root:
          _rootImage = null;
          break;
      }
    });
  }

  /// Build image picker card widget
  Widget _buildImagePickerCard(
    String label,
    IconData icon,
    File? imageFile,
    ImageType imageType,
  ) {
    final bool hasImage = imageFile != null;

    return GestureDetector(
      onTap: hasImage ? null : () => _pickImage(imageType),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
            width: hasImage ? 2 : 1,
          ),
        ),
        child: hasImage
            ? Stack(
                children: [
                  // Image preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Row(
                      children: [
                        // Thumbnail
                        Image.file(
                          imageFile,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 12),
                        // Label
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(icon, size: 18, color: const Color(0xFF22C55E)),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Color(0xFF22C55E)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Eklendi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF22C55E),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Remove button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeImage(imageType),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF9CA3AF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Resim eklemek için tıklayın',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF9CA3AF),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
      ),
    );
  }

  /// Show dialog when user has no subscription
  void _showNoSubscriptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Abonelik Gerekli',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analiz yapabilmek için aktif bir aboneliğiniz olması gerekiyor.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.celebration, color: Colors.green.shade700, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ücretsiz Abonelik Kazanın!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Arkadaşlarınızı davet ederek ücretsiz premium abonelik kazanabilirsiniz.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to referral screen with BlocProvider
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => getIt<ReferralBloc>(),
                      child: const ReferralLinkGenerationScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Arkadaş Davet Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to subscription packages
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionStatusScreen(
                      scenario: 'no_subscription',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Paketleri Gör'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Analiz Seçenekleri',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Image Preview
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      widget.selectedImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // Action buttons overlay
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.crop_rotate, size: 20),
                            onPressed: () {
                              // Crop & Rotate functionality
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.tune, size: 20),
                            onPressed: () {
                              // Filters functionality
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Crop & Rotate and Filters buttons
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // Crop & Rotate functionality
                    },
                    icon: const Icon(Icons.crop_rotate),
                    label: const Text('Kırp & Döndür'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // Filters functionality
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Filtreler'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Analysis Type Section
            const Text(
              'Analiz Tipi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAnalysisType = 'quick';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _selectedAnalysisType == 'quick'
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedAnalysisType == 'quick'
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flash_on,
                            color: _selectedAnalysisType == 'quick'
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF6B7280),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hızlı Analiz',
                            style: TextStyle(
                              color: _selectedAnalysisType == 'quick'
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAnalysisType = 'detailed';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _selectedAnalysisType == 'detailed'
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedAnalysisType == 'detailed'
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.science,
                            color: _selectedAnalysisType == 'detailed'
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF6B7280),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detaylı',
                            style: TextStyle(
                              color: _selectedAnalysisType == 'detailed'
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Multi-Image Section (only for detailed analysis)
            if (_selectedAnalysisType == 'detailed') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_photo_alternate, color: Color(0xFF22C55E), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Ek Görseller (Opsiyonel)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daha detaylı analiz için farklı açılardan çekilmiş görseller ekleyebilirsiniz.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Image picker cards
                    _buildImagePickerCard(
                      'Yaprak Üstü',
                      Icons.eco,
                      _leafTopImage,
                      ImageType.leafTop,
                    ),
                    const SizedBox(height: 12),
                    _buildImagePickerCard(
                      'Yaprak Altı',
                      Icons.eco_outlined,
                      _leafBottomImage,
                      ImageType.leafBottom,
                    ),
                    const SizedBox(height: 12),
                    _buildImagePickerCard(
                      'Bitki Genel',
                      Icons.nature,
                      _plantOverviewImage,
                      ImageType.plantOverview,
                    ),
                    const SizedBox(height: 12),
                    _buildImagePickerCard(
                      'Kök Sistemi',
                      Icons.grass,
                      _rootImage,
                      ImageType.root,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Plant Type Dropdown
            const Text(
              'Bitki Türü (Opsiyonel)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPlantType,
                  hint: const Text(
                    'Bitki Türü Seçin',
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                  isExpanded: true,
                  items: _plantTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPlantType = newValue;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Location Input with Auto-Detection
            Row(
              children: [
                const Text(
                  'Konum (Opsiyonel)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_autoDetectedLocation != null)
                  const Tooltip(
                    message: 'GPS konumu otomatik olarak algılandı',
                    child: Icon(
                      Icons.gps_fixed,
                      size: 18,
                      color: Color(0xFF22C55E),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: _autoDetectedLocation != null
                      ? 'GPS: ${_autoDetectedLocation!.split(', ')[0]}'
                      : 'Örn: Ankara, Türkiye',
                  hintStyle: TextStyle(
                    color: _autoDetectedLocation != null
                        ? const Color(0xFF22C55E).withOpacity(0.7)
                        : const Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: Icon(
                    _autoDetectedLocation != null ? Icons.my_location : Icons.location_on,
                    color: _autoDetectedLocation != null
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF6B7280),
                  ),
                  suffixIcon: _autoDetectedLocation != null
                      ? IconButton(
                          icon: const Icon(Icons.info_outline, size: 20),
                          color: const Color(0xFF6B7280),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Konum Bilgisi'),
                                content: Text(
                                  'GPS Koordinatları:\n$_autoDetectedLocation\n\n'
                                  'İsterseniz şehir adını da girebilirsiniz. '
                                  'Her iki bilgi de analize eklenecektir.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Tamam'),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Additional Notes
            const Text(
              'Ek Notlar (Opsiyonel)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Örn: alt yapraklarda renk değişimi, bitki serada...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Error Message
            if (_currentError != null) ...[
              ErrorDisplayWidget(
                exception: _currentError!,
                onRetry: _currentError!.isRecoverable ? () {
                  setState(() {
                    _currentError = null;
                  });
                  _validateImage();
                } : null,
              ),
              const SizedBox(height: 16),
            ],

            // Analyze Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _currentError != null || _isSubmitting ? null : _startAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: const Color(0xFF9CA3AF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Analiz Et',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const FarmerBottomNav(currentIndex: 3),
    );
  }

  /// Navigate to subscription status screen for 403 errors
  void _navigateToSubscriptionStatus([String? scenario]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubscriptionStatusScreen(
          scenario: scenario ?? 'daily_exceeded', // Fallback to default scenario
        ),
      ),
    );
  }

  /// Determine the appropriate scenario based on quota exception details
  String _determineScenarioFromException(QuotaExceededException exception) {
    // If we have subscription tier information but quotas are exceeded
    if (exception.subscriptionTier != null) {
      if (exception.quotaType == 'daily') {
        return 'daily_exceeded';
      } else if (exception.quotaType == 'monthly') {
        return 'monthly_exceeded';
      }
      return 'basic_active'; // Has subscription but some other issue
    }

    // No subscription tier information means likely no active subscription
    return 'no_subscription';
  }

  /// Build final location string combining user input and auto-detected GPS
  /// Logic:
  /// - If user entered location AND GPS available: "User Location - GPS Coordinates"
  /// - If only user entered location: "User Location"
  /// - If only GPS available: "GPS Coordinates"
  /// - If neither: null
  String? _buildFinalLocation(String userInput, String? gpsLocation) {
    final hasUserInput = userInput.isNotEmpty;
    final hasGPS = gpsLocation != null && gpsLocation.isNotEmpty;

    if (hasUserInput && hasGPS) {
      // Both available: combine them
      return '$userInput - $gpsLocation';
    } else if (hasUserInput) {
      // Only user input
      return userInput;
    } else if (hasGPS) {
      // Only GPS
      return gpsLocation;
    } else {
      // Neither available
      return null;
    }
  }
}

/// Image types for multi-image analysis
enum ImageType {
  leafTop,
  leafBottom,
  plantOverview,
  root,
}