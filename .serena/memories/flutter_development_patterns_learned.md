# Flutter Development Patterns - Session Learnings

## Critical Type Safety Patterns

### 1. Safe Type Conversion for API Responses
**Problem**: API responses may return int/double when expecting String
```dart
// ❌ WRONG - Can cause runtime crash
confidence: json['confidence'] as String?,

// ✅ CORRECT - Safe conversion
confidence: json['confidence']?.toString(),
```

### 2. Null Safety in UI Components
**Pattern**: Always provide fallbacks for nullable data
```dart
// ✅ Safe UI display with fallbacks
Text(treatment.name ?? 'Tedavi Adı Belirtilmedi'),
Text('${detail.confidence?.toInt() ?? 0}%'),

// ✅ Safe method parameter passing
_buildRecommendationCard(
  treatment.name ?? 'Tedavi',
  treatment.instructions ?? 'Talimatlar mevcut değil',
  'Yüksek',
  'Hemen',
  'İyileşme beklenir',
)
```

### 3. Flutter Build Recovery Strategy
**Critical Learning**: Always backup working files before `flutter clean`
- File corruption can occur during clean operations
- Keep `.dart` backups with `_fixed` suffix
- Test incremental changes rather than massive rebuilds

## Model Design Patterns

### 1. Comprehensive Data Models
**Strategy**: Map ALL API fields to prevent runtime surprises
```dart
class ComprehensiveAnalysisResponse {
  // Include every possible field from API
  final PlantIdentificationComplete? plantIdentification;
  final HealthAssessmentComplete? healthAssessment;
  final NutrientStatusExtended? nutrientStatus;
  // ... all 10 sections mapped completely
}
```

### 2. Safe fromJson Patterns
```dart
factory Model.fromJson(Map<String, dynamic> json) {
  return Model(
    // Safe conversions for mixed types
    stringField: json['field']?.toString(),
    intField: (json['intField'] as num?)?.toInt(),
    doubleField: (json['doubleField'] as num?)?.toDouble(),
    
    // Safe list parsing
    listField: (json['list'] as List<dynamic>?)
        ?.map((e) => SubModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
```

## UI Architecture Patterns

### 1. Grid Layouts for Complex Data
**Use Case**: Displaying 14 nutrients in organized grid
```dart
GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemCount: nutrientData.length,
  itemBuilder: (context, index) => _buildNutrientCard(nutrientData[index]),
)
```

### 2. Conditional Section Display
```dart
if (detail.diseases?.isNotEmpty == true) 
  ...detail.diseases!.map((disease) => _buildDiseaseCard(disease))
else 
  _buildNoIssuesCard('Hastalık tespit edilmedi'),
```

## Error Recovery Patterns

### 1. Build Error Analysis
**Strategy**: Use `flutter analyze` for precise error location
```bash
cd lib/features/plant_analysis/presentation/screens 
flutter analyze analysis_detail_screen.dart
```

### 2. Incremental Fix Approach
- Fix one error type at a time (null safety, then type casting, then missing fields)
- Test compilation after each fix category
- Don't attempt massive changes in single operation

## Project Structure Learnings
- Always verify correct project directory (`ziraai_mobile/` folder)
- User emphasized project structure multiple times - critical requirement
- Use relative paths correctly within Flutter project structure