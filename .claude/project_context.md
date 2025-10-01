# ZiraAI Mobile - Project Context Preservation

## Project Identity
**Name**: ZiraAI Mobile Application
**Domain**: Agricultural Technology Platform
**Market**: Turkish Agricultural Sector
**Platform**: Flutter/Dart Mobile Application

## Technical Architecture

### Core Technologies
- **Framework**: Flutter/Dart
- **Architecture**: Clean Architecture Pattern
- **State Management**: Native StatefulWidget + GetIt DI
- **HTTP Client**: Dio for API integration
- **Authentication**: JWT Bearer tokens
- **Storage**: Secure local storage for tokens

### Project Structure
```
lib/
├── features/
│   ├── plant_analysis/
│   │   ├── presentation/screens/
│   │   │   └── analysis_detail_screen.dart
│   │   ├── domain/
│   │   └── data/
│   ├── subscription/
│   └── authentication/
├── core/
├── shared/
└── main.dart
```

### API Integration
- **Base URL**: https://api.ziraai.com/api/v1
- **Key Endpoints**:
  - `GET /api/v1/plantanalyses/{id}` - Analysis details
  - `GET /api/v1/plantanalyses/list` - Analysis list
  - `GET /api/v1/subscriptions/usage-status` - User subscription
- **Authentication**: JWT Bearer token headers

## Business Context

### Platform Purpose
ZiraAI is an enterprise-grade agricultural technology platform providing AI-powered plant analysis services through a sophisticated sponsorship system.

### Key Features
1. **Plant Analysis System**: AI-powered plant health assessment
2. **Sponsorship Links**: Multi-tier subscription system (S, M, L, XL)
3. **Farmer Dashboard**: Mobile-optimized analysis history
4. **Multi-Language**: Turkish primary, English, Arabic support
5. **Communication**: SMS/WhatsApp integration for outreach

### User Types
- **Farmers**: Plant analysis access, subscription management
- **Sponsors**: Company profiles, package purchasing
- **Admins**: Full system administration

### Market Context
- **Primary Market**: Turkish agricultural sector
- **Communication**: WhatsApp preferred, SMS backup
- **Cultural**: Regional farming terminology and practices
- **Network**: Rural connectivity considerations

## Technical Patterns Established

### 1. Flutter UI Modernization
```dart
// Modern Card Design Pattern
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.green[50]!, Colors.white],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  // Content
)
```

### 2. Turkish Localization System
```dart
// Comprehensive Turkish Text Formatting
String _formatTurkishText(String text) {
  if (text.isEmpty) return text;

  // Disease patterns
  text = text.replaceAllMapped(
    RegExp(r'\b(yaprak\s+lekesi|gövde\s+çürüklüğü|kök\s+çürüklüğü)',
           caseSensitive: false),
    (match) => _capitalizeWords(match.group(0)!),
  );

  // Agricultural terms
  text = text.replaceAllMapped(
    RegExp(r'\b(besin\s+eksikliği|fungal\s+hastalık|viral\s+enfeksiyon)',
           caseSensitive: false),
    (match) => _capitalizeWords(match.group(0)!),
  );

  return text;
}
```

### 3. Error Handling Pattern
```dart
// Comprehensive Error States
Widget build(BuildContext context) {
  return FutureBuilder<Map<String, dynamic>>(
    future: _loadAnalysisData(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildLoadingState();
      }

      if (snapshot.hasError) {
        return _buildErrorState(snapshot.error.toString());
      }

      if (!snapshot.hasData) {
        return _buildEmptyState();
      }

      return _buildContent(snapshot.data!);
    },
  );
}
```

### 4. Helper Methods Architecture
```dart
// Reusable UI Components
Widget _buildSectionCard(String title, Widget content) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(/* Modern design */),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: /* Section header style */),
          const SizedBox(height: 12),
          content,
        ],
      ),
    ),
  );
}
```

## Development Standards

### 1. Code Organization
- **File Naming**: snake_case for files, camelCase for variables
- **Class Naming**: PascalCase for classes and widgets
- **Method Naming**: camelCase with descriptive names
- **Constants**: SCREAMING_SNAKE_CASE for constants

### 2. UI/UX Standards
- **Spacing**: 16px base unit (8px, 12px, 20px, 24px variations)
- **Colors**: Semantic usage (success, warning, error, info)
- **Typography**: Material Design scale with custom agricultural context
- **Touch Targets**: Minimum 44px for accessibility

### 3. Localization Standards
- **Turkish Primary**: All UI text in Turkish
- **Agricultural Context**: Specialized terminology formatting
- **Grammar Rules**: Automated capitalization for proper nouns
- **Cultural Sensitivity**: Turkish farming practices consideration

### 4. Performance Standards
- **Image Loading**: Progressive with fallbacks
- **Network Calls**: Async with error handling
- **Memory Management**: Efficient widget disposal
- **Loading States**: Visual feedback for all async operations

## Quality Assurance

### 1. Testing Strategy
- **Unit Tests**: Helper methods and business logic
- **Widget Tests**: UI component behavior
- **Integration Tests**: API communication
- **Manual Testing**: Turkish language and agricultural context

### 2. Code Quality Metrics
- **Readability**: Self-documenting code with clear naming
- **Maintainability**: Modular architecture with separation of concerns
- **Performance**: Optimized for mobile devices and rural networks
- **Accessibility**: Screen reader support and high contrast

### 3. Business Validation
- **Agricultural Accuracy**: Terminology validation with domain experts
- **User Experience**: Farmer-centric design validation
- **Cultural Appropriateness**: Turkish agricultural context validation
- **Technical Robustness**: Rural network condition testing

## Development Environment

### 1. Setup Requirements
- **IDE**: Visual Studio 2022 or VS Code
- **Platform**: Windows development environment
- **Flutter SDK**: Latest stable version
- **Dependencies**: See pubspec.yaml for complete list

### 2. Git Workflow
- **Main Branch**: `master`
- **Feature Branches**: `feature/[feature-name]`
- **Current**: `feature/analysis-detail-screen`
- **Commit Style**: Conventional commits with Turkish context

### 3. Build Configuration
- **Target**: Android and iOS mobile platforms
- **API Integration**: Staging and production environments
- **Localization**: Turkish primary with multi-language support
- **Performance**: Optimized for rural network conditions

## Knowledge Base

### 1. Agricultural Domain Knowledge
- **Turkish Farming**: Regional practices and terminology
- **Plant Diseases**: Common issues in Turkish agriculture
- **Seasonal Patterns**: Planting and harvest cycles
- **Communication**: Farmer preferences and technology adoption

### 2. Technical Implementation Knowledge
- **Flutter Patterns**: Modern UI/UX implementation
- **Turkish Localization**: Language-specific formatting rules
- **Mobile Performance**: Rural network optimization
- **API Integration**: ZiraAI backend communication

### 3. Business Understanding
- **Sponsorship Model**: Tier-based subscription system
- **User Journey**: Farmer analysis workflow
- **Market Requirements**: Turkish agricultural technology needs
- **Success Metrics**: User adoption and engagement

---

**Context Preserved**: 2025-09-30
**Status**: Ready for continued development
**Next Session**: Full project context available for immediate continuation