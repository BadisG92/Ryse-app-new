#!/bin/bash

# Script pour builder l'app iOS pour TestFlight
# Utilise automatiquement les variables d'environnement de production

echo "🚀 Building Ryse App for TestFlight..."
echo ""

# Vérifier que le fichier .env.production existe
if [ ! -f ".env.production" ]; then
    echo "❌ Erreur: .env.production n'existe pas!"
    echo "   Créez-le à partir de .env.example"
    exit 1
fi

# Clean
echo "🧹 Cleaning project..."
flutter clean

# Build avec les variables d'environnement de production
echo "📦 Building IPA with production environment..."
flutter build ipa --release --dart-define-from-file=.env.production

# Vérifier le succès
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build réussi!"
    echo ""
    echo "📱 Pour uploader sur TestFlight:"
    echo "   1. Ouvrir Transporter: open -a Transporter"
    echo "   2. Drag & drop: build/ios/ipa/ryze_app.ipa"
    echo ""
    echo "   OU"
    echo ""
    echo "   Ouvrir Xcode Organizer: open ios/Runner.xcworkspace"
    echo "   Window → Organizer → Distribute App"
    echo ""
else
    echo "❌ Build échoué"
    exit 1
fi
