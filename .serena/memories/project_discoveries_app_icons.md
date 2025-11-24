# App Icon Management - ZiraAI Mobile

## Flutter Launcher Icons Setup

### Package Configuration
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icons/app_icon_512.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icons/app_icon_512.png"
```

### Icon Generation Process
1. Place source image (512x512 PNG recommended) in `assets/icons/`
2. Configure pubspec.yaml with image path and settings
3. Run `flutter pub get` to add package
4. Run `dart run flutter_launcher_icons` to generate all sizes
5. Rebuild APK to include new icons

### Generated Icon Sizes
- mdpi: 48x48
- hdpi: 72x72
- xhdpi: 96x96
- xxhdpi: 144x144
- xxxhdpi: 192x192
- Adaptive icons with separate background and foreground layers

### Current Icon
- **Source**: ZiraAI logo from `claudedocs/favicon_io/android-chrome-512x512.png`
- **Design**: Green leaf with "AI" text
- **Background**: White (#FFFFFF) for adaptive icons
- **Location**: `assets/icons/app_icon_512.png`

### Important Notes
- Icons are embedded during build, so APK must be rebuilt after icon changes
- Adaptive icons (Android 8.0+) use separate background/foreground layers
- The package automatically creates mipmap directories and resources
- colors.xml is created automatically if not present
