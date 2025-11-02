#!/bin/bash
# Script pour build l'app sans les widgets iOS

echo "🚀 Building app WITHOUT widgets..."

# Backup du project.pbxproj
cp ios/Runner.xcodeproj/project.pbxproj ios/Runner.xcodeproj/project.pbxproj.backup

# Build Flutter sans les widgets
flutter clean
flutter pub get

# Build iOS (le widget ne sera pas inclus si non coché dans Xcode)
echo "📦 Building iOS archive..."
echo "⚠️  IMPORTANT: Ouvrez Xcode et décochez RyseMealWidget dans Edit Scheme → Build"
echo ""
echo "Commandes:"
echo "1. open ios/Runner.xcworkspace"
echo "2. Product → Scheme → Edit Scheme → Build"
echo "3. Décochez RyseMealWidget et RyseMealWidgetExtension"
echo "4. Lancez: flutter build ios --release"
echo ""

read -p "Appuyez sur Entrée quand c'est fait..."

flutter build ios --release

echo "✅ Build terminé!"
echo "📦 Archive disponible pour export dans Xcode"
