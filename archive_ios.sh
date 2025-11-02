#!/bin/bash
# Script pour créer une archive iOS sans widgets

echo "📦 Création de l'archive iOS (sans widgets)..."
echo ""
echo "⚠️  Assurez-vous d'avoir décoché RyseMealWidget dans Edit Scheme → Build"
echo ""

# Clean
echo "🧹 Nettoyage..."
flutter clean
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework

# Récupérer les dépendances
echo "📥 Installation des dépendances..."
flutter pub get
cd ios && pod install && cd ..

# Build
echo "🔨 Build de l'app..."
flutter build ios --release --no-codesign

# Archive avec Xcode
echo "📦 Création de l'archive..."
cd ios
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  DEVELOPMENT_TEAM=YOUR_TEAM_ID

echo ""
echo "✅ Archive créée : ios/build/Runner.xcarchive"
echo ""
echo "Pour exporter l'IPA :"
echo "1. Ouvrez Xcode Organizer : open ~/Library/Developer/Xcode/Archives"
echo "2. Sélectionnez l'archive et cliquez sur 'Distribute App'"
