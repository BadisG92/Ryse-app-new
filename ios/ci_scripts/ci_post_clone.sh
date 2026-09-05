#!/bin/bash
# Xcode Cloud post-clone script for the Ryze Flutter app.
#
# Xcode Cloud only clones the repository: it has neither Flutter nor the
# CocoaPods dependencies installed. Without this script the "Archive - iOS"
# action fails with:
#   Unable to load contents of file list: '/Target Support Files/Pods-Runner/...'
# because PODS_ROOT is undefined until `pod install` has run.
#
# Environment variables to configure in App Store Connect
# (Xcode Cloud > workflow > Environment > Environment Variables):
#   RYZE_ENV_FILE_B64   REQUIRED. Base64 of the .env file to bake into the build.
#                       From Windows PowerShell, in the project folder:
#                       [Convert]::ToBase64String([IO.File]::ReadAllBytes(".env.production")) | Set-Clipboard
#   RYZE_FLUTTER_VERSION          optional, Flutter tag to install (default 3.38.5)
#   RYZE_ALLOW_PLACEHOLDER_ENV=1  optional, debug only: build with .env.example values
#                                 (the app will NOT work at runtime)

set -e
# Print the exact failing command in the Xcode Cloud log
trap 'echo "### ci_post_clone.sh FAILED at line $LINENO: $BASH_COMMAND"' ERR

FLUTTER_VERSION="${RYZE_FLUTTER_VERSION:-3.38.5}"

# Xcode Cloud sets CI_PRIMARY_REPOSITORY_PATH; the fallback allows local testing.
cd "${CI_PRIMARY_REPOSITORY_PATH:-$(dirname "$0")/../..}"
echo "Working directory: $(pwd)"

echo "=== Installing Flutter $FLUTTER_VERSION ==="
git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"
flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version
flutter precache --ios

echo "=== Installing CocoaPods (if missing) ==="
if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi
pod --version

echo "=== Preparing environment file ==="
if [ -n "$RYZE_ENV_FILE_B64" ]; then
  printf '%s' "$RYZE_ENV_FILE_B64" | base64 --decode > ci.env
  echo "Using .env values from RYZE_ENV_FILE_B64"
elif [ -n "$RYZE_ENV_FILE" ]; then
  printf '%s\n' "$RYZE_ENV_FILE" > ci.env
  echo "Using .env values from RYZE_ENV_FILE"
elif [ "$RYZE_ALLOW_PLACEHOLDER_ENV" = "1" ]; then
  tr -d '\r' < .env.example > ci.env
  echo "WARNING: building with placeholder values from .env.example, the app will not work at runtime"
else
  echo "ERROR: RYZE_ENV_FILE_B64 is not set."
  echo "Add it in App Store Connect > Xcode Cloud > workflow > Environment > Environment Variables."
  echo "Value = base64 of .env.production. From PowerShell in the project folder:"
  echo "  [Convert]::ToBase64String([IO.File]::ReadAllBytes(\".env.production\")) | Set-Clipboard"
  exit 1
fi
if ! grep -q '^SUPABASE_URL=' ci.env; then
  echo "ERROR: ci.env does not look like a valid .env file (no SUPABASE_URL= line)"
  exit 1
fi

echo "=== Build number ==="
# pubspec.yaml holds "version: 1.1.1+16". Xcode Cloud's CI_BUILD_NUMBER starts at 1,
# so it is added to the pubspec build number to always produce a new, increasing
# build number for TestFlight (e.g. 16 + 3 = 19).
PUBSPEC_BUILD=$(sed -n 's/^version: *[0-9.]*+\([0-9]*\).*/\1/p' pubspec.yaml)
PUBSPEC_BUILD="${PUBSPEC_BUILD:-0}"
BUILD_NUMBER=$((PUBSPEC_BUILD + ${CI_BUILD_NUMBER:-0}))
echo "pubspec build=$PUBSPEC_BUILD, CI_BUILD_NUMBER=${CI_BUILD_NUMBER:-unset} -> build number $BUILD_NUMBER"

echo "=== Flutter dependencies and iOS project configuration ==="
flutter pub get
# Writes ios/Flutter/Generated.xcconfig (FLUTTER_ROOT, DART_DEFINES, build number)
# used by the Xcode build phases, and runs pod install. Nothing is compiled here:
# Xcode Cloud does the actual archive.
flutter build ios --config-only --release --no-codesign \
  --dart-define-from-file=ci.env \
  --build-number="$BUILD_NUMBER"

echo "=== CocoaPods dependencies ==="
cd ios
pod install
echo "Pods-Runner support files:"
ls "Pods/Target Support Files/Pods-Runner/" | head -5

echo "=== ci_post_clone.sh done ==="
exit 0
