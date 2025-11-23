#!/bin/bash

# Script pour builder l'app iOS pour TestFlight avec widget via Xcode
# Cette méthode garantit que le widget est correctement embedé

echo "🚀 Building Ryse App for TestFlight via Xcode (with iOS Widget)..."
echo ""

# Vérifier que le fichier .env.production existe
if [ ! -f ".env.production" ]; then
    echo "❌ Erreur: .env.production n'existe pas!"
    exit 1
fi

# Vérifier la sécurité des clés API
echo "🔒 Checking API keys security..."
./check_api_keys.sh
if [ $? -ne 0 ]; then
    echo "⚠️  API keys check failed, but continuing..."
fi
echo ""

# Clean
echo "🧹 Cleaning project..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build Flutter framework pour iOS
echo "📦 Building Flutter framework..."
flutter build ios --release --dart-define-from-file=.env.production --no-codesign

# Archive avec Xcode
echo "📦 Archiving with Xcode..."
cd ios

xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath "$PWD/build/Runner.xcarchive" \
    -allowProvisioningUpdates \
    archive

if [ $? -ne 0 ]; then
    echo "❌ Archive failed"
    cd ..
    exit 1
fi

echo "✅ Archive created successfully"

# Export IPA
echo "📦 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$PWD/build/Runner.xcarchive" \
    -exportPath "$PWD/build/ipa" \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates

cd ..

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build réussi!"

    # Vérifier que le widget est inclus
    echo ""
    echo "🔍 Vérification du widget dans l'IPA..."
    IPA_PATH="ios/build/ipa/ryze_app.ipa"

    if [ -f "$IPA_PATH" ]; then
        TEMP_DIR=$(mktemp -d)
        unzip -q "$IPA_PATH" -d "$TEMP_DIR"

        if [ -d "$TEMP_DIR/Payload/Runner.app/PlugIns/RyseMealWidgetExtension.appex" ]; then
            # Vérifier que ce n'est pas vide
            WIDGET_SIZE=$(du -sk "$TEMP_DIR/Payload/Runner.app/PlugIns/RyseMealWidgetExtension.appex" | cut -f1)
            if [ "$WIDGET_SIZE" -gt 100 ]; then
                echo "✅ Widget RyseMealWidgetExtension inclus dans l'IPA! (${WIDGET_SIZE}KB)"
            else
                echo "⚠️  Widget trouvé mais semble vide (${WIDGET_SIZE}KB)"
            fi
        else
            echo "⚠️  Widget non trouvé dans l'IPA!"
        fi

        rm -rf "$TEMP_DIR"
    fi

    echo ""
    echo "📱 IPA créé: ios/build/ipa/ryze_app.ipa"
    echo ""
    echo "Pour uploader sur TestFlight:"
    echo "   open -a Transporter"
    echo "   Drag & drop: ios/build/ipa/ryze_app.ipa"
    echo ""
else
    echo "❌ Export IPA échoué"
    exit 1
fi
