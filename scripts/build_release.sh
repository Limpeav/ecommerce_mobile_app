#!/bin/bash
set -e

echo "🚀 Building Cherish Baby Store for Production Release..."

# 1. Ensure dependencies and localization are up-to-date
flutter pub get
flutter gen-l10n

# 2. Run unit and integration tests
echo "🧪 Running tests..."
flutter test

# 3. Analyze code quality
echo "🔍 Running static analysis..."
flutter analyze

# 4. Build Android App Bundle (.aab)
echo "📦 Building Android App Bundle (.aab)..."
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=BASE_URL=https://backend-80bu.onrender.com

echo "✅ Android AppBundle generated at build/app/outputs/bundle/release/app-release.aab"

# 5. Build iOS Release Bundle (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "🍎 Building iOS Release Archive (without codesigning for Xcode export)..."
  flutter build ipa --no-codesign --release \
    --dart-define=APP_ENV=production \
    --dart-define=BASE_URL=https://backend-80bu.onrender.com
  echo "✅ iOS IPA archive prepared for Xcode Organizer distribution."
fi

echo "🎉 Release build completed successfully!"
