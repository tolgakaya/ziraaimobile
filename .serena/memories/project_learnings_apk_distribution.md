# APK Distribution and Installation - ZiraAI Mobile

## Building Release APK

### Command
```bash
flutter build apk --release --flavor staging
```

### Build Flavors
- **staging**: Points to staging API environment for testing
- **production**: Points to production API (not yet configured)

### Build Output
- **Location**: `build\app\outputs\flutter-apk\app-staging-release.apk`
- **Typical Size**: ~60-65 MB for ZiraAI Mobile
- **Additional Files**: `.sha1` hash file (not needed for installation)

### Build Optimizations
- Tree-shaking for fonts (MaterialIcons reduced by 98.6%)
- Code minification and obfuscation in release mode
- Asset optimization and compression

## Installation on Real Devices

### File Transfer Methods
1. **USB Cable**: Copy APK to phone's Download folder, install via file manager
2. **Cloud Storage**: Upload to Google Drive, download on phone
3. **ADB**: `adb install app-staging-release.apk` (requires developer mode)

### Google Play Protect Handling
- **Expected Behavior**: Warning for non-Play Store apps
- **Solution Options**:
  1. Tap "Install anyway" or "More details" if available
  2. Temporarily disable Play Protect scanning in Settings
  3. Enable "Install from unknown sources" for installer app

### Required Permissions
- **Installation**: "Install unknown apps" permission for file manager
- **Runtime**: App will request permissions (camera, storage, etc.) on first use

### APK vs App Bundle
- **APK**: Direct installation, single file for all devices
- **App Bundle (AAB)**: Optimized for Play Store, requires bundletool for local install
- **For Testing**: APK is simpler and more convenient

## Testing Checklist
- [ ] App launches successfully
- [ ] Authentication flows work
- [ ] Camera/image picker permissions
- [ ] Network connectivity (staging API)
- [ ] Payment integration
- [ ] Contact picker functionality
- [ ] App icons display correctly
- [ ] Push notifications (if implemented)
