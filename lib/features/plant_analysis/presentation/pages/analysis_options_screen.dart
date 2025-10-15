import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/repositories/plant_analysis_repository.dart';
import '../../../../core/services/image_processing_service.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../../core/error/plant_analysis_exceptions.dart';
import '../../../../core/widgets/error_widgets.dart';
import '../../../subscription/presentation/screens/subscription_status_screen.dart';
import '../../../dashboard/presentation/pages/farmer_dashboard_page.dart';

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
  bool _isSubmitting = false;
  PlantAnalysisException? _currentError;

  @override
  void initState() {
    super.initState();
    // Temporary: Use mock repository with correct async flow
    _repository = getIt<PlantAnalysisRepository>();
    _validateImage();
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

      // Submit analysis request to API
      final result = await _repository.submitAnalysis(
        imageFile: widget.selectedImage,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        notes: combinedNotes.isNotEmpty ? combinedNotes : null,
      );

      if (!mounted) return;

      result.fold(
        // Left - Failure/Error
        (failure) {
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
          'Analysis Options',
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
                    label: const Text('Crop & Rotate'),
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
                    label: const Text('Filters'),
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
              'Analysis Type',
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF22C55E)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.flash_on, color: Color(0xFF22C55E), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Quick Analysis',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.science, color: Color(0xFF6B7280), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Detailed',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Plant Type Dropdown
            const Text(
              'Plant Type (Optional)',
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
                    'Select Plant Type',
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

            // Location Input
            const Text(
              'Location (Optional)',
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
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Ankara, Turkey',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF6B7280)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Additional Notes
            const Text(
              'Additional Notes (Optional)',
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
                  hintText: 'e.g., discoloration on lower leaves, plant is in a greenhouse...',
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
                        'Analyze',
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
}