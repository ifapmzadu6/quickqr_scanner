# Contributing to QuickQR Scanner Plugin

Thank you for your interest in contributing to QuickQR Scanner Plugin! This document provides guidelines and information for contributors.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)

## 🤝 Code of Conduct

This project adheres to a code of conduct adapted from the Contributor Covenant. By participating, you are expected to uphold this code.

### Our Standards

- **Be respectful**: Treat all contributors with respect and kindness
- **Be inclusive**: Welcome developers of all backgrounds and experience levels
- **Be constructive**: Focus on constructive feedback and solutions
- **Be collaborative**: Work together toward common goals

## 🚀 How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**Bug Report Template:**

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Initialize scanner with '...'
2. Call method '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots or error logs.

**Environment:**
- Flutter version: [e.g. 3.16.0]
- Plugin version: [e.g. 0.1.0]
- Platform: [iOS/Android]
- Device: [e.g. iPhone 14, Pixel 7]
- OS Version: [e.g. iOS 17.0, Android 13]

**Additional context**
Any other context about the problem.
```

### ✨ Suggesting Features

Feature suggestions are welcome! Please provide:

1. **Clear description** of the proposed feature
2. **Use case** - why would this be useful?
3. **Implementation ideas** - how might it work?
4. **Backward compatibility** considerations

### 💻 Code Contributions

We welcome code contributions! Areas where help is needed:

- **Platform support**: Flutter Web, Desktop platforms
- **Performance improvements**: Optimization and efficiency
- **Additional barcode formats**: Support for more formats
- **UI components**: Custom scanner overlay widgets
- **Testing**: Unit tests, integration tests, example apps
- **Documentation**: API docs, tutorials, examples

## 🛠 Development Setup

### Prerequisites

- **Flutter SDK**: 3.16.0 or higher
- **Dart SDK**: 3.2.0 or higher
- **iOS Development** (for iOS contributions):
  - Xcode 14.0 or higher
  - iOS Simulator or physical device (iOS 12.0+)
- **Android Development** (for Android contributions):
  - Android Studio
  - Android SDK API 21 or higher
  - Android Emulator or physical device

### Local Setup

1. **Fork and clone** the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/quickqr_scanner_plugin.git
   cd quickqr_scanner_plugin
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   cd example
   flutter pub get
   ```

3. **Run the example app**:
   ```bash
   cd example
   flutter run
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```

### Development Workflow

1. Create a feature branch: `git checkout -b feature/my-new-feature`
2. Make your changes
3. Add tests for new functionality
4. Ensure all tests pass: `flutter test`
5. Format code: `dart format .`
6. Analyze code: `flutter analyze`
7. Commit changes with descriptive messages
8. Push to your fork and submit a pull request

## 📁 Project Structure

```
quickqr_scanner_plugin/
├── lib/                          # Dart plugin code
│   ├── src/
│   │   ├── models/              # Data models
│   │   │   ├── qr_scan_result.dart
│   │   │   ├── qr_scan_config.dart
│   │   │   └── scanner_exception.dart
│   ├── quickqr_scanner_plugin.dart # Main plugin API
│   ├── quickqr_scanner_plugin_platform_interface.dart
│   └── quickqr_scanner_plugin_method_channel.dart
├── ios/                          # iOS native code
│   ├── Classes/
│   │   └── QuickqrScannerProPlugin.swift
│   └── quickqr_scanner_plugin.podspec
├── android/                      # Android native code
│   └── src/main/kotlin/
│       └── QuickqrScannerProPlugin.kt
├── example/                      # Example Flutter app
│   ├── lib/main.dart
│   └── test/
├── test/                        # Dart tests
└── docs/                        # Documentation
```

### Key Files

- **`lib/quickqr_scanner_plugin.dart`**: Main plugin API
- **`ios/Classes/QuickqrScannerProPlugin.swift`**: iOS implementation
- **`android/.../QuickqrScannerProPlugin.kt`**: Android implementation
- **`example/lib/main.dart`**: Example app demonstrating usage

## 📝 Coding Standards

### Dart Code Style

Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart):

```dart
// Good
class QRScannerService {
  final QuickQRScannerPro _scanner = QuickQRScannerPro.instance;
  
  Future<void> initialize() async {
    await _scanner.initialize();
  }
}

// Use descriptive names
Future<QRScanResult?> scanQRFromImageFile(String imagePath) async {
  return await _scanner.scanFromImage(imagePath);
}
```

### Swift Code Style (iOS)

Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):

```swift
// Good
private func setupCaptureSession(result: @escaping FlutterResult) {
    // Implementation
}

// Use clear, descriptive method names
func handleQRDetection(_ observation: VNBarcodeObservation) {
    // Implementation
}
```

### Kotlin Code Style (Android)

Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html):

```kotlin
// Good
class QuickqrScannerProPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var context: Context
    
    private fun initializeMLKit() {
        // Implementation
    }
}
```

### Code Formatting

- **Dart**: Use `dart format .` to format code
- **Swift**: Follow Xcode's default formatting
- **Kotlin**: Use Android Studio's default formatting

### Documentation

- Add doc comments to all public APIs
- Use clear, concise descriptions
- Include usage examples where helpful
- Update README.md for new features

```dart
/// Scans a QR code from an image file.
/// 
/// [imagePath] must be an absolute path to the image file.
/// 
/// Returns a [QRScanResult] if a QR code is found, null otherwise.
/// 
/// Throws [ScannerException] if the image cannot be processed.
/// 
/// Example:
/// ```dart
/// final result = await scanner.scanFromImage('/path/to/image.jpg');
/// if (result != null) {
///   print('QR content: ${result.content}');
/// }
/// ```
Future<QRScanResult?> scanFromImage(String imagePath);
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/quickqr_scanner_plugin_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Structure

- **Unit Tests**: Test individual methods and classes
- **Integration Tests**: Test plugin integration with Flutter
- **Platform Tests**: Test native platform implementations

### Writing Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quickqr_scanner_plugin/quickqr_scanner_plugin.dart';

void main() {
  group('QuickQRScannerPro', () {
    late QuickQRScannerPro scanner;

    setUp(() {
      scanner = QuickQRScannerPro.instance;
    });

    test('should be singleton', () {
      final scanner2 = QuickQRScannerPro.instance;
      expect(scanner, same(scanner2));
    });

    // Add more tests...
  });
}
```

### Example App Testing

The example app should demonstrate:
- All plugin features
- Proper error handling
- Good UX practices
- Platform-specific behavior

## 📤 Pull Request Process

### Before Submitting

1. **Test thoroughly**: Ensure all tests pass
2. **Update documentation**: Update README, API docs if needed
3. **Check formatting**: Run `dart format .` and `flutter analyze`
4. **Verify example**: Ensure example app works with changes

### Pull Request Template

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Example app works correctly
- [ ] Tested on iOS
- [ ] Tested on Android

## Screenshots/Videos
If applicable, add screenshots or videos demonstrating the changes.

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Code is documented
- [ ] Tests are added/updated
- [ ] Documentation is updated
```

### Review Process

1. **Automated checks**: CI/CD will run tests and analysis
2. **Code review**: Maintainers will review code quality and design
3. **Testing**: Changes will be tested on multiple platforms
4. **Documentation**: Ensure documentation is complete and accurate

## 🐞 Issue Reporting

### Bug Reports

Use the GitHub issue template and provide:

- **Clear reproduction steps**
- **Expected vs actual behavior**
- **Environment information**
- **Error logs/screenshots**
- **Minimal code example**

### Feature Requests

Provide:

- **Problem description**: What problem does this solve?
- **Proposed solution**: How should it work?
- **Alternatives considered**: What other approaches were considered?
- **Additional context**: Any other relevant information

### Good Issue Examples

**Bug Report:**
```markdown
Title: Scanner fails to initialize on Android API 21

Description:
The scanner initialization fails on Android API 21 devices with 
"INIT_ERROR: Camera2 not supported" even though Camera2 should be 
available on API 21+.

Steps to reproduce:
1. Run on Android API 21 device
2. Call QuickQRScannerPro.instance.initialize()
3. Receives error

Expected: Initialization should succeed
Actual: Throws exception

Environment: Android 5.0 (API 21), Plugin v0.1.0
```

**Feature Request:**
```markdown
Title: Add support for custom scan area

Description:
Allow developers to specify a custom scanning area instead of full camera view.

Use case:
Many apps only need to scan QR codes in a specific area of the screen 
to improve performance and user experience.

Proposed API:
```dart
final config = QRScanConfig(
  scanArea: Rect.fromLTWH(100, 100, 200, 200),
);
await scanner.initialize(config);
```
```

## 🏆 Recognition

Contributors will be recognized in:

- **README.md**: Contributors section
- **CHANGELOG.md**: Credit for specific features/fixes
- **Release notes**: Major contributions highlighted

## 📞 Getting Help

- **Discussion**: Use GitHub Discussions for questions
- **Discord**: Join our Discord server (link in README)
- **Email**: Contact maintainers directly for sensitive issues

## 📜 License

By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project.

---

Thank you for contributing to QuickQR Scanner Plugin! 🙏