import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../data/repositories/plant_analysis_repository.dart' as repo;
import '../../data/models/plant_analysis_response_new.dart';
import '../blocs/analysis_detail/analysis_detail_bloc.dart';
import '../blocs/analysis_detail/analysis_detail_event.dart';
import '../blocs/analysis_detail/analysis_detail_state.dart';

class AnalysisDetailScreen extends StatelessWidget {
  final String analysisId;

  const AnalysisDetailScreen({
    Key? key,
    required this.analysisId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalysisDetailBloc(
          repository: getIt<repo.PlantAnalysisRepository>())
        ..add(LoadAnalysisDetail(analysisId: analysisId)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
        body: BlocBuilder<AnalysisDetailBloc, AnalysisDetailState>(
          builder: (context, state) {
            if (state is AnalysisDetailLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF17CF17), // Primary green color
                ),
              );
            } else if (state is AnalysisDetailLoaded) {
              return _buildDetailContent(context, state.analysisResult);
            } else if (state is AnalysisDetailError) {
              return _buildErrorState(context, state.message);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, PlantAnalysisResult result) {
    return Column(
      children: [
        // Main content - scrollable
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header with back button and title
                _buildHeader(context),

                // Hero image section with confidence badge
                _buildHeroImageSection(result),

                // Content section
                _buildContentSection(result),
              ],
            ),
          ),
        ),

        // Bottom navigation (dashboard-style)
        _buildBottomNavigation(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.transparent,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF111811),
                    size: 24,
                  ),
                ),
              ),

              // Title - centered
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(right: 40), // Compensate for back button
                  child: const Text(
                    'Analysis Results',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF111811),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.015,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImageSection(PlantAnalysisResult result) {
    return Stack(
      children: [
        // Background image
        Container(
          height: 250,
          decoration: BoxDecoration(
            image: result.imagePath != null
                ? DecorationImage(
                    image: NetworkImage(result.imagePath!),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Fallback to default image
                    },
                  )
                : const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDTpUXmRR9kFEKDMYDaB3_CqCIB8aryrECWsdpHS-7E6i71NZij_lCmjavFzyhPsbfDM3oCyRLRV9h2GtRaMVZXb-w0ndoMsRa6h8aYVFcx_8u3tVK9sZFQCc0bOB5GF2eFgx2XnUuYJAVLmrLw7g-8AUDT2MzYoMN7UvkVVtr5BFXy7fcKZ0z6Ml9uJYE8Nm8E8o13Maq1mUIk5Uk6G7Tio4e_SjresezP4GsYqD0hWnyvhxnyxJpH5LLOexvNcXHj1k0v5cM4K5I',
                    ),
                    fit: BoxFit.cover,
                  ),
          ),
        ),

        // Gradient overlay
        Container(
          height: 250,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0x99000000), // from-black/60 to-transparent
              ],
              stops: [0.0, 1.0],
            ),
          ),
        ),

        // Bottom content (confidence badge and fullscreen button)
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Confidence badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x80059212), // bg-green-500/80
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Confidence: ${((result.confidence ?? 0.95) * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Fullscreen button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0x4D000000), // bg-black/30
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(PlantAnalysisResult result) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analysis ID
          Text(
            'Analysis ID: ${result.analysisId}',
            style: const TextStyle(
              color: Color(0xFF6B7280), // text-gray-500
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // Disease Detection Section
          _buildDiseaseDetectionSection(result),

          const SizedBox(height: 24),

          // Treatment Recommendations Section
          _buildTreatmentRecommendationsSection(result),

          const SizedBox(height: 24),

          // Additional Information Section
          _buildAdditionalInformationSection(),

          const SizedBox(height: 24),

          // Action Buttons Grid
          _buildActionButtonsGrid(),

          const SizedBox(height: 80), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildDiseaseDetectionSection(PlantAnalysisResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disease Detection',
          style: TextStyle(
            color: Color(0xFF111811),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.015,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Main disease info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.diseases?.isNotEmpty == true
                                ? (result.diseases!.first.name ?? 'Leaf Spot')
                                : 'Leaf Spot',
                            style: const TextStyle(
                              color: Color(0xFF111811),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.diseases?.isNotEmpty == true
                                ? 'Severity: ${result.diseases!.first.severity ?? 'High'}'
                                : 'Severity: High',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      result.diseases?.isNotEmpty == true
                          ? '${((result.diseases!.first.confidence ?? 0.95) * 100).toInt()}%'
                          : '95%',
                      style: const TextStyle(
                        color: Color(0xFF111811),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Visual Indicators row
              Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Visual Indicators',
                        style: TextStyle(
                          color: Color(0xFF111811),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF6B7280),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentRecommendationsSection(PlantAnalysisResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Treatment Recommendations',
          style: TextStyle(
            color: Color(0xFF111811),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.015,
          ),
        ),

        const SizedBox(height: 12),

        Column(
          children: [
            // Neem Oil Solution (Organic)
            _buildTreatmentCard(
              icon: Icons.eco,
              iconColor: const Color(0xFF17CF17),
              iconBgColor: const Color(0xFFDCFCE7), // green-50
              title: '1. Neem Oil Solution',
              subtitle: 'Organic Option',
              description: 'Apply neem oil solution every 7 days until symptoms disappear.',
            ),

            const SizedBox(height: 12),

            // Copper Sulfate Fungicide (Chemical)
            _buildTreatmentCard(
              icon: Icons.science,
              iconColor: const Color(0xFF2563EB), // blue-600
              iconBgColor: const Color(0xFFDBEAFE), // blue-50
              title: '2. Copper Sulfate Fungicide',
              subtitle: 'Chemical Option',
              description: 'Use a fungicide containing copper sulfate. Follow label instructions carefully.',
            ),

            const SizedBox(height: 12),

            // Prevention Tips
            _buildTreatmentCard(
              icon: Icons.shield,
              iconColor: const Color(0xFFEA580C), // orange-600
              iconBgColor: const Color(0xFFFED7AA), // orange-50
              title: 'Prevention Tips',
              subtitle: null,
              description: 'Ensure proper spacing between plants for better air circulation. Avoid overhead watering.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTreatmentCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111811),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],

                const SizedBox(height: 4),

                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(
            color: Color(0xFF111811),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.015,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Common Causes
              Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Common Causes',
                        style: TextStyle(
                          color: Color(0xFF111811),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF6B7280),
                      size: 16,
                    ),
                  ],
                ),
              ),

              // Divider
              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Similar Cases
              Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Similar Cases',
                        style: TextStyle(
                          color: Color(0xFF111811),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF6B7280),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Consult an Expert button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              // Handle expert consultation
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17CF17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Consult an Expert',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.015,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsGrid() {
    return Row(
      children: [
        // Share
        Expanded(
          child: _buildActionButton(
            icon: Icons.ios_share,
            label: 'Share',
            onTap: () {},
          ),
        ),

        // Save
        Expanded(
          child: _buildActionButton(
            icon: Icons.save,
            label: 'Save',
            onTap: () {},
          ),
        ),

        // Ask Sponsor
        Expanded(
          child: _buildActionButton(
            icon: Icons.contact_support,
            label: 'Ask Sponsor',
            onTap: () {},
          ),
        ),

        // New Analysis
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle,
            label: 'New Analysis',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), // bg-gray-100
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF374151), // text-gray-700
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                isActive: true,
                onTap: () => Navigator.pop(context),
              ),
              _buildNavItem(
                icon: Icons.history,
                label: 'History',
                isActive: false,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.chat_bubble,
                label: 'Messages',
                isActive: false,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Profile',
                isActive: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 24,
              color: isActive
                  ? const Color(0xFF17CF17)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? const Color(0xFF17CF17)
                  : const Color(0xFF6B7280),
              letterSpacing: 0.015,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Analysis Results'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17CF17),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}