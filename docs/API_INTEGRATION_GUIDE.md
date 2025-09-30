# ZiraAI Mobile - API Integration Guide

## Overview
This document details the API integration between ZiraAI Mobile application and the backend services, specifically focusing on the plant analysis feature flow.

## API Configuration

### Environment Settings
- **Production**: `https://ziraai-api-prod.up.railway.app`
- **Staging**: `https://ziraai-api-sit.up.railway.app` (Currently Active)
- **Development**: `https://api.ziraai.com`
- **Local**: `http://localhost:5000`

Configuration file: `lib/core/config/api_config.dart`

## Authentication
All API requests require JWT Bearer authentication:
```http
Authorization: Bearer {token}
```

Token is stored in secure storage and retrieved via `SecureStorageService`.

## Plant Analysis Flow

### 1. Dashboard - Analysis List

#### Endpoint
```
GET /api/v1/plantanalyses/list?page=1&pageSize=10
```

#### Response Structure
```json
{
  "data": {
    "analyses": [
      {
        "id": 165,                    // ⚠️ IMPORTANT: Numeric ID for detail API
        "analysisId": "analysis_1758102151186_F112_ce4xcjr1b",  // String ID for reference
        "imagePath": "https://iili.io/KRgsgr7.jpg",
        "thumbnailUrl": "https://iili.io/KRgsgr7.jpg",
        "analysisDate": "2025-09-17T09:42:29.803471+00:00",
        "status": "Completed",
        "plantSpecies": "Solanum lycopersicum",
        "primaryConcern": "nitrogen deficiency",
        "overallHealthScore": 6,
        "formattedDate": "17.09.2025 09:42"
      }
    ],
    "totalCount": 3,
    "page": 1,
    "pageSize": 20
  },
  "success": true,
  "message": "Found 3 plant analyses"
}
```

#### Implementation Details
- **File**: `lib/features/dashboard/presentation/widgets/recent_analyses_grid.dart`
- **Key Point**: The `id` field (numeric) is used for navigation, NOT `analysisId` (string)

### 2. Analysis Detail Screen

#### Endpoint
```
GET /api/v1/plantanalyses/{id}
```
⚠️ **CRITICAL**: Use numeric `id` (e.g., 165), NOT string `analysisId`

#### Request Example
```
GET /api/v1/plantanalyses/165
```

#### Response Structure
```json
{
  "data": {
    "id": 165,
    "imagePath": "https://iili.io/KRgsgr7.jpg",
    "analysisDate": "2025-09-17T09:42:29.803471+00:00",
    "status": "Completed",
    "userId": 112,
    "analysisId": "analysis_1758102151186_F112_ce4xcjr1b",
    "farmerId": "F112",
    "plantType": "Solanum lycopersicum",
    "growthStage": "vegetative",
    "elementDeficiencies": [
      {
        "element": "Nitrogen",
        "severity": "Medium",
        "description": "Yellowing of lower leaves"
      }
    ],
    "diseases": [
      {
        "name": "Early Blight",
        "severity": "Low",
        "confidence": 0.85,
        "description": "Minor fungal infection detected"
      }
    ],
    "pests": []
  },
  "success": true
}
```

#### Implementation Details
- **Repository**: `lib/features/plant_analysis/data/repositories/plant_analysis_repository.dart`
- **BLoC**: `lib/features/plant_analysis/presentation/blocs/analysis_detail/analysis_detail_bloc.dart`
- **Screen**: `lib/features/plant_analysis/presentation/screens/analysis_detail_screen.dart`

## Navigation Flow

```
Dashboard (ListView)
    ↓
Tap Analysis Card
    ↓
Extract numeric ID from API response (e.g., 165)
    ↓
Navigate to AnalysisDetailScreen(analysisId: "165")
    ↓
API Call: GET /api/v1/plantanalyses/165
    ↓
Display Analysis Details
```

## Common Issues & Solutions

### Issue 1: 400 Bad Request on Detail API
**Cause**: Using string `analysisId` instead of numeric `id`
```
❌ Wrong: /api/v1/plantanalyses/analysis_1758102151186_F112_ce4xcjr1b
✅ Correct: /api/v1/plantanalyses/165
```

**Solution**: In `recent_analyses_grid.dart`:
```dart
// Use numeric ID first, fallback to analysisId
id: apiItem['id']?.toString() ?? apiItem['analysisId'] ?? ''
```

### Issue 2: Model Conflicts
**Cause**: Duplicate model definitions in different files
**Solution**: Use import aliases:
```dart
import '../../data/repositories/plant_analysis_repository.dart' as repo;
```

## Repository Implementation

### getAnalysisResult Method
```dart
Future<Result<PlantAnalysisDetailResult>> getAnalysisResult(String analysisId) async {
  // Get authentication token
  final token = await _storageService.getToken();

  // Make API call using numeric ID
  final response = await _networkClient.get(
    '${ApiConfig.plantAnalysisDetail}/$analysisId',
    options: Options(
      headers: ApiConfig.authHeader(token),
    ),
  );

  // Parse and return result
  if (response.data['success'] == true) {
    // Convert to PlantAnalysisDetailResult model
    return Result.success(result);
  }
}
```

## BLoC Pattern Implementation

### State Management Flow
1. **LoadAnalysisDetail Event**: Triggered with numeric ID
2. **API Call**: Repository fetches data from backend
3. **Data Transformation**: API response → Domain model
4. **State Update**: Emit AnalysisDetailLoaded with data
5. **Fallback**: If API fails, use mock data

### Error Handling
- Network errors → Fallback to mock data
- Authentication errors → Redirect to login
- Invalid ID → Show error message

## Testing Checklist

- [ ] Dashboard loads analysis list from API
- [ ] Analysis cards display correct images and data
- [ ] Clicking card navigates to detail screen
- [ ] Detail screen loads with numeric ID
- [ ] API returns correct analysis details
- [ ] Error states handled gracefully
- [ ] Mock data fallback works when API fails

## Debug Tips

### Enable API Logging
Check network requests in:
```dart
lib/core/network/network_client.dart
```

### View Console Logs
```bash
flutter logs
```

### Check API Response
Look for these log patterns:
- `🚀 CLAUDE: Making API call to plantanalyses/list`
- `🔍 CLAUDE: Converting API item`
- `Error loading from API:` (indicates fallback to mock)

## Model Definitions

### PlantAnalysisDetailResult
```dart
class PlantAnalysisDetailResult {
  final int id;                    // Numeric ID for API
  final String analysisId;         // String reference ID
  final String imagePath;         // Full image URL
  final String analysisDate;      // ISO timestamp
  final String status;            // Completed/Processing/Failed
  final String plantType;         // Scientific name
  final String growthStage;       // Growth phase
  final List<ElementDeficiency> elementDeficiencies;
  final List<DiseaseDetail> diseases;
  final List<PestDetail> pests;
}
```

## API Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 400 | Bad Request - Invalid ID format | Use numeric ID, not string |
| 401 | Unauthorized | Refresh authentication token |
| 403 | Forbidden | Check user permissions |
| 404 | Analysis not found | Verify ID exists |
| 500 | Server error | Retry or use fallback |

## Future Improvements

1. **Caching**: Implement local caching for offline support
2. **Pagination**: Add infinite scroll for analysis list
3. **Real-time Updates**: WebSocket for analysis status
4. **Image Optimization**: Lazy loading and compression
5. **Error Recovery**: Automatic retry with exponential backoff

## Related Files

- Configuration: `lib/core/config/api_config.dart`
- Network Client: `lib/core/network/network_client.dart`
- Repository: `lib/features/plant_analysis/data/repositories/plant_analysis_repository.dart`
- Dashboard Widget: `lib/features/dashboard/presentation/widgets/recent_analyses_grid.dart`
- Detail Screen: `lib/features/plant_analysis/presentation/screens/analysis_detail_screen.dart`
- BLoC: `lib/features/plant_analysis/presentation/blocs/analysis_detail/`

## Contact & Support

For API issues or questions, refer to the main project documentation or contact the backend team.

---
*Last Updated: September 17, 2025*
*Version: 1.0.0*