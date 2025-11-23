#!/bin/bash

# Script pour builder l'app iOS pour TestFlight avec widget
# Utilise automatiquement les variables d'environnement de production

echo "🚀 Building Ryse App for TestFlight (with iOS Widget)..."
echo ""

# Vérifier que le fichier .env.production existe
if [ ! -f ".env.production" ]; then
    echo "❌ Erreur: .env.production n'existe pas!"
    echo "   Créez-le à partir de .env.example"
    exit 1
fi

# Vérifier la sécurité des clés API
echo "🔒 Checking API keys security..."
./check_api_keys.sh
if [ $? -ne 0 ]; then
    echo "⚠️  API keys check failed, but continuing..."
fi
echo ""

# Vérifier que le widget existe
if [ ! -d "ios/RyseMealWidget" ]; then
    echo "⚠️  Warning: ios/RyseMealWidget directory not found!"
    echo "   Widget may not be included in the build"
fi

# Clean
echo "🧹 Cleaning project..."
flutter clean

# Clean iOS build artifacts
echo "🧹 Cleaning iOS build cache..."
cd ios
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
rm -rf build/
cd ..

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build avec les variables d'environnement de production
echo "📦 Building IPA with production environment..."
echo "   - Environment: PRODUCTION"
echo "   - Widget: RyseMealWidgetExtension"
echo "   - Config: .env.production"
echo ""

flutter build ipa --release \
    --dart-define-from-file=.env.production \
    --export-options-plist=ios/ExportOptions.plist

# Vérifier le succès
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build réussi!"

    # Vérifier que le widget est inclus dans l'archive
    echo ""
    echo "🔍 Vérification du widget dans l'IPA..."
    IPA_PATH="build/ios/ipa/ryze_app.ipa"

    if [ -f "$IPA_PATH" ]; then
        # Extraire et vérifier la présence du widget
        TEMP_DIR=$(mktemp -d)
        unzip -q "$IPA_PATH" -d "$TEMP_DIR"

        if [ -d "$TEMP_DIR/Payload/Runner.app/PlugIns/RyseMealWidgetExtension.appex" ]; then
            echo "✅ Widget RyseMealWidgetExtension inclus dans l'IPA!"
        else
            echo "⚠️  Warning: Widget non trouvé dans l'IPA!"
            echo "   Vérifiez la configuration Xcode"
        fi

        # Cleanup
        rm -rf "$TEMP_DIR"
    fi

    echo ""
    echo "📱 Pour uploader sur TestFlight:"
    echo ""
    echo "   Option 1 - Transporter (Recommandé):"
    echo "   1. open -a Transporter"
    echo "   2. Drag & drop: build/ios/ipa/ryze_app.ipa"
    echo ""
    echo "   Option 2 - Xcode Organizer:"
    echo "   1. open ~/Library/Developer/Xcode/Archives/"
    echo "   2. Xcode → Window → Organizer"
    echo "   3. Distribute App → App Store Connect"
    echo ""
    echo "   Option 3 - Command line:"
    echo "   xcrun altool --upload-app --type ios --file build/ios/ipa/ryze_app.ipa \\"
    echo "              --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID"
    echo ""
else
    echo "❌ Build échoué"
    exit 1
fi
