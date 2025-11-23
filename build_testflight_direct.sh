#!/bin/bash

# Build TestFlight via Xcode directement (évite les cycles de dépendance)

echo "🚀 Building for TestFlight via Xcode Archive..."
echo ""

# Vérifier .env.production
if [ ! -f ".env.production" ]; then
    echo "❌ .env.production n'existe pas!"
    exit 1
fi

# Clean
echo "🧹 Cleaning..."
flutter clean
flutter pub get

# Build Flutter framework seulement
echo "📦 Building Flutter framework..."
flutter build ios --release --dart-define-from-file=.env.production --no-codesign

if [ $? -ne 0 ]; then
    echo "❌ Flutter build failed"
    exit 1
fi

# Archive avec xcodebuild
echo ""
echo "📦 Archiving with Xcode..."
cd ios

xcodebuild clean archive \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/Runner.xcarchive \
    -allowProvisioningUpdates \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    | grep -E "error:|warning:|Archiving|Archive succeeded"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "❌ Archive failed"
    cd ..
    exit 1
fi

echo ""
echo "✅ Archive created!"

# Export IPA
echo ""
echo "📦 Exporting IPA..."

xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportPath build/ipa \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates \
    | grep -E "error:|warning:|Exporting|Export succeeded"

cd ..

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ Build réussi!"

    # Vérifier le widget
    IPA_PATH="ios/build/ipa/ryze_app.ipa"
    if [ -f "$IPA_PATH" ]; then
        echo ""
        echo "🔍 Vérification du widget..."

        TEMP_DIR=$(mktemp -d)
        unzip -q "$IPA_PATH" -d "$TEMP_DIR"

        WIDGET_PATH="$TEMP_DIR/Payload/Runner.app/PlugIns/RyseMealWidgetExtension.appex"
        if [ -d "$WIDGET_PATH" ]; then
            WIDGET_SIZE=$(du -sh "$WIDGET_PATH" | cut -f1)
            echo "✅ Widget inclus! Taille: $WIDGET_SIZE"

            # Lister les fichiers du widget
            echo "   Fichiers du widget:"
            ls -la "$WIDGET_PATH" | head -10
        else
            echo "❌ Widget non trouvé"
        fi

        rm -rf "$TEMP_DIR"

        echo ""
        echo "📱 IPA prêt: ios/build/ipa/ryze_app.ipa"
        echo ""
        echo "Pour uploader:"
        echo "   open -a Transporter"
        echo "   Drag & drop: ios/build/ipa/ryze_app.ipa"
    fi
else
    echo ""
    echo "❌ Export failed"
    exit 1
fi
