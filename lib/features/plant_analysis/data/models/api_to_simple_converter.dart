import 'plant_analysis_result.dart';
import 'plant_identification.dart';
import 'health_assessment.dart';
import 'plant_disease.dart';
import 'plant_treatment.dart';
import 'nutrient_status.dart';
import 'pest_disease.dart';
import 'recommendations.dart';
import 'analysis_summary.dart';
import 'environmental_factors.dart';
import 'sponsorship_metadata.dart';

class ApiToSimpleConverter {
  static PlantAnalysisResult convertApiResponse(Map<String, dynamic> apiData) {
    try {
      print('🔍 CONVERTER: Starting conversion with keys: ${apiData.keys.toList()}');
      print('🔍 CONVERTER: Searching for farmerFriendlySummary...');
      print('🔍 CONVERTER: farmerFriendlySummary direct: ${apiData['farmerFriendlySummary']}');
      
      // Check all possible locations for farmer summary
      if (apiData.containsKey('farmerFriendlySummary')) {
        print('✅ CONVERTER: Found farmerFriendlySummary at root level');
      }
      if (apiData['summary'] != null && (apiData['summary'] as Map).containsKey('farmerFriendlySummary')) {
        print('✅ CONVERTER: Found farmerFriendlySummary in summary');
      }
      if (apiData['detailedAnalysis'] != null && (apiData['detailedAnalysis'] as Map).containsKey('farmerFriendlySummary')) {
        print('✅ CONVERTER: Found farmerFriendlySummary in detailedAnalysis');
      }

      // Parse nested plantIdentification
      PlantIdentification? identification;
      if (apiData['plantIdentification'] != null) {
        print('🔍 CONVERTER: Processing plantIdentification');
        identification = PlantIdentification.fromJson(
          apiData['plantIdentification'] as Map<String, dynamic>
        );
      }

      // Parse nested healthAssessment
      HealthAssessment? health;
      if (apiData['healthAssessment'] != null) {
        print('🔍 CONVERTER: Processing healthAssessment');
        health = HealthAssessment.fromJson(
          apiData['healthAssessment'] as Map<String, dynamic>
        );
      }

      // Handle diseases from pestDisease.diseasesDetected
      List<PlantDisease>? diseases;
      if (apiData['pestDisease'] != null &&
          apiData['pestDisease']['diseasesDetected'] != null) {
        print('🔍 CONVERTER: Processing diseases from pestDisease');
        final diseasesData = apiData['pestDisease']['diseasesDetected'];
        if (diseasesData is List) {
          diseases = diseasesData
              .map((e) => PlantDisease.fromJson({
                'name': e['type'] ?? 'Unknown Disease',
                'severity': e['severity'],
                'confidence': e['confidence'],
                'category': e['category'],
                'affectedParts': e['affectedParts'],
                'description': e['type'],
              }))
              .toList();
        }
      }

      // Handle treatments from recommendations
      List<PlantTreatment>? treatments;
      if (apiData['recommendations'] != null &&
          apiData['recommendations']['immediate'] != null) {
        print('🔍 CONVERTER: Processing treatments from recommendations');
        final immediateRecs = apiData['recommendations']['immediate'];
        if (immediateRecs is List) {
          treatments = immediateRecs
              .map((e) => PlantTreatment.fromJson({
                'name': e['action'] ?? 'Unknown Treatment',
                'description': e['details'],
                'priority': e['priority'],
                'type': 'immediate',
                'instructions': e['details'],
              }))
              .toList();
        }
      }

      // Parse recommendations as simple strings
      List<String>? recommendations;
      if (apiData['summary'] != null && apiData['summary']['secondaryConcerns'] != null) {
        print('🔍 CONVERTER: Processing recommendations');
        final concerns = apiData['summary']['secondaryConcerns'];
        if (concerns is List) {
          recommendations = concerns.map((e) => e.toString()).toList();
        }
      }

      // Safe parsing of previousTreatments
      List<String>? previousTreatments;
      if (apiData['previousTreatments'] != null) {
        final treatments = apiData['previousTreatments'];
        if (treatments is List) {
          previousTreatments = treatments.map((e) => e.toString()).toList();
        }
      }

      // Parse nutrientStatus
      NutrientStatus? nutrientStatus;
      if (apiData['nutrientStatus'] != null) {
        print('🔍 CONVERTER: Processing nutrientStatus');
        nutrientStatus = NutrientStatus.fromJson(
          apiData['nutrientStatus'] as Map<String, dynamic>
        );
      }

      // Parse pestDisease (full structure)
      PestDisease? pestDiseaseComplete;
      if (apiData['pestDisease'] != null) {
        print('🔍 CONVERTER: Processing complete pestDisease');
        pestDiseaseComplete = PestDisease.fromJson(
          apiData['pestDisease'] as Map<String, dynamic>
        );
      }

      // Parse recommendations as detailed structure
      Recommendations? recommendationsDetailed;
      if (apiData['recommendations'] != null && apiData['recommendations'] is Map) {
        print('🔍 CONVERTER: Processing detailed recommendations');
        recommendationsDetailed = Recommendations.fromJson(
          apiData['recommendations'] as Map<String, dynamic>
        );
      }

      // Parse summary
      AnalysisSummary? summary;
      if (apiData['summary'] != null) {
        print('🔍 CONVERTER: Processing summary');
        summary = AnalysisSummary.fromJson(
          apiData['summary'] as Map<String, dynamic>
        );
      }

      // Parse environmentalFactors
      EnvironmentalFactors? environmentalFactors;
      if (apiData['environmentalFactors'] != null) {
        print('🔍 CONVERTER: Processing environmentalFactors');
        environmentalFactors = EnvironmentalFactors.fromJson(
          apiData['environmentalFactors'] as Map<String, dynamic>
        );
      }

      // Parse sponsorshipMetadata
      SponsorshipMetadata? sponsorshipMetadata;
      if (apiData['sponsorshipMetadata'] != null) {
        print('🔍 CONVERTER: Processing sponsorshipMetadata');
        print('📊 CONVERTER: sponsorshipMetadata raw: ${apiData['sponsorshipMetadata']}');
        sponsorshipMetadata = SponsorshipMetadata.fromJson(
          apiData['sponsorshipMetadata'] as Map<String, dynamic>
        );
        print('✅ CONVERTER: sponsorshipMetadata parsed - canMessage: ${sponsorshipMetadata.canMessage}');
      } else {
        print('⚠️ CONVERTER: No sponsorshipMetadata in response');
      }

      print('🔍 CONVERTER: Creating PlantAnalysisResult');
      print('🌾 CONVERTER: farmerFriendlySummary = ${apiData['farmerFriendlySummary']}');

      return PlantAnalysisResult(
        id: apiData['id'] as int?,
        analysisId: apiData['analysisId'] as String?,
        analysisDate: apiData['analysisDate'] != null
            ? DateTime.tryParse(apiData['analysisDate'] as String)
            : null,
        analysisStatus: apiData['analysisStatus'] as String?,
        userId: apiData['userId'] as int?,
        farmerId: apiData['farmerId'] as String?,
        location: apiData['location'] as String?,
        cropType: apiData['cropType'] as String?,
        previousTreatments: previousTreatments,
        notes: apiData['notes'] as String?,
        plantIdentification: identification,
        healthAssessment: health,
        diseases: diseases,
        treatments: treatments,
        recommendations: recommendations,
        imageUrl: (apiData['imageInfo'] as Map<String, dynamic>?)?['imageUrl'] as String?,
        additionalData: apiData,
        // New comprehensive fields
        nutrientStatus: nutrientStatus,
        pestDisease: pestDiseaseComplete,
        recommendationsDetailed: recommendationsDetailed,
        summary: summary,
        environmentalFactors: environmentalFactors,
        imagePath: apiData['imagePath'] as String?,
        analysisModel: apiData['analysisModel'] as String?,
        modelVersion: apiData['modelVersion'] as String?,
        createdDate: apiData['createdDate'] != null
            ? DateTime.tryParse(apiData['createdDate'] as String)
            : null,
        plantSpecies: apiData['plantSpecies'] as String?,
        sponsorshipMetadata: sponsorshipMetadata,
      );
    } catch (e, stackTrace) {
      print('❌ CONVERTER ERROR: $e');
      print('📍 CONVERTER STACK: $stackTrace');
      rethrow;
    }
  }
}