# Voice Vision

A Flutter application that uses Google's Generative AI to describe images through voice for accessibility.

## Features

- 📸 Real-time camera access with visual preview
- 🤖 AI-powered image description using Google Gemini 1.5 Flash
- 🔊 Text-to-speech audio feedback
- ♿ Accessibility-first design for visually impaired users
- 📱 Cross-platform support (iOS, Android)

## Prerequisites

- Flutter SDK 3.11.0 or higher
- Dart 3.11.0 or higher
- Android SDK (for Android builds)
- Xcode (for iOS builds)
- Google Cloud API Key with Generative AI enabled

## Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd voice_vision
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API Key:**
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Open `.env` and add your Google Generative AI API key:
     ```
     GOOGLE_GENERATIVE_AI_API_KEY=your_api_key_here
     ```
   
   **Getting an API Key:**
   - Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key
   - Enable the Generative AI API
   - Copy the key to `.env` file

4. **Platform-Specific Setup:**

   ### iOS Setup
   - Open `ios/Runner.xcworkspace` in Xcode
   - Ensure deployment target is iOS 13.0 or higher
   - Grant permissions in Info.plist (already configured)
   - Run: `flutter pub get && pod install` (if needed)

   ### Android Setup
   - Minimum SDK: API 21 (Android 5.0)
   - Target SDK: API 34 (Android 14)
   - Permissions are pre-configured in AndroidManifest.xml

## Running the App

### Development Mode
```bash
flutter run
```

### Release Mode
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Permissions

### iOS
- **Camera**: Required to capture images
- **Microphone**: Required for voice feedback

### Android
- `INTERNET`: For API communication
- `CAMERA`: For image capture
- `RECORD_AUDIO`: For voice features

These permissions are automatically requested at runtime.

## Project Structure

```
lib/
├── main.dart          # Main application and UI
├── constants/         # (Future) Configuration constants
└── services/          # (Future) API services
```

## Dependencies

- `flutter_tts`: Text-to-speech functionality
- `camera`: Camera access and preview
- `google_generative_ai`: Google AI integration
- `flutter_dotenv`: Environment variable management
- `permission_handler`: Runtime permission handling

## Building for Production

### Pre-Release Checklist
- [ ] API key configured in `.env` (not hardcoded)
- [ ] Run `flutter analyze` with no critical issues
- [ ] Run `flutter test` and ensure all tests pass
- [ ] Build APK: `flutter build apk --release`
- [ ] Build iOS: `flutter build ios --release`
- [ ] Test on physical device
- [ ] Remove `.env` file from source control

### Android Release Build
```bash
flutter build apk --release --verbose
# Output: build/app/outputs/apk/release/app-release.apk
```

### iOS Release Build
```bash
flutter build ios --release --verbose
# Output: build/ios/iphoneos/Runner.app
```

## Troubleshooting

### Camera Not Working
- Ensure camera permissions are granted
- Check that `flutter pub get` was run
- Verify camera is not in use by another app

### API Errors
- Verify `.env` file exists and contains valid API key
- Check internet connection
- Ensure API quota hasn't been exceeded in Google Cloud Console

### Permission Denied Errors
- For iOS: Check Info.plist has NSCameraUsageDescription and NSMicrophoneUsageDescription
- For Android: Verify AndroidManifest.xml has required permissions
- Try uninstalling and reinstalling the app

### Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade
```

## Code Quality

The project uses Flutter Lints for code quality. Run analysis with:
```bash
flutter analyze
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and analysis
4. Submit a pull request

## License

[Add your license here]

## Support

For issues and questions, please create an issue in the repository.

## Security Notes

- **Never** commit `.env` file with actual API keys
- Always use environment variables for sensitive data
- Keep Flutter SDK and dependencies updated
- Review security advisories regularly

---

**Last Updated:** December 24, 2025  
**Version:** 1.0.0
