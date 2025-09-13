# ZiraAI Mobile

Enterprise Flutter mobile application for ZiraAI agricultural plant analysis platform.

## Features

- **Plant Analysis**: AI-powered plant health assessment with disease detection
- **Sponsorship System**: Tier-based sponsorship integration (S, M, L, XL tiers)
- **Authentication**: Secure JWT-based authentication for farmers and sponsors
- **Multi-language Support**: Turkish, English, Arabic localization
- **Clean Architecture**: Scalable codebase with BLoC pattern

## Tech Stack

- **Framework**: Flutter 3.35.3
- **State Management**: BLoC Pattern with flutter_bloc
- **Network**: Dio + Retrofit for API integration
- **Storage**: SharedPreferences + Flutter Secure Storage
- **Navigation**: GoRouter
- **Dependency Injection**: GetIt + Injectable
- **Code Generation**: build_runner + json_serializable

## Development Setup

1. **Prerequisites**
   - Flutter SDK 3.35.3+
   - Dart 3.9.2+
   - Android Studio / VS Code

2. **Installation**
   ```bash
   git clone https://github.com/tolgakaya/ziraaimobile.git
   cd ziraaimobile
   flutter pub get
   flutter packages pub run build_runner build
   ```

3. **Run Application**
   ```bash
   flutter run
   ```

## Project Status

🚧 **In Active Development**

### ✅ Completed
- Clean Architecture setup
- Core infrastructure (API, Storage, DI)
- Dependency integration
- Code generation setup

### 🔄 In Progress
- Authentication module implementation
- API integration testing

## Backend Integration

Connects to ZiraAI .NET 9.0 REST API:
- **Production**: `https://api.ziraai.com/api/v1`
- **Staging**: `https://api-staging.ziraai.com/api/v1`
