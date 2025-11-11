#!/bin/bash
# Script pour lancer UNIQUEMENT l'app Runner, pas le widget

set -e

echo "🚀 Lancement de l'app Runner (sans widget)..."
echo ""

# Nettoyer d'abord
flutter clean

# Lancer avec le bundle identifier explicite de Runner
flutter run \
  --dart-define-from-file=.env.local \
  -d "iPhone 16 Pro" \
  --target=lib/main.dart \
  --bundle-id=com.BadisG.ryzeApp

echo ""
echo "✅ App lancée!"
echo ""
echo "⚠️  Note: Le widget n'est pas inclus dans ce build"
echo "   Pour inclure le widget, utilisez Xcode directement:"
echo "   cd ios && open Runner.xcworkspace"
echo "   Puis: Product → Run (Cmd+R)"


