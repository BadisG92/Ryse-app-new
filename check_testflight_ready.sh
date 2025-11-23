#!/bin/bash

# Script de vérification avant le build TestFlight
# Vérifie que tout est prêt pour un build de production

echo "🔍 Vérification de la préparation TestFlight..."
echo ""

ERRORS=0
WARNINGS=0

# 1. Vérifier l'environnement de production
echo "📋 Vérification des fichiers de configuration..."
if [ -f ".env.production" ]; then
    echo "✅ .env.production existe"

    # Vérifier les clés importantes
    if grep -q "ENVIRONMENT=production" .env.production; then
        echo "✅ ENVIRONMENT=production configuré"
    else
        echo "❌ ENVIRONMENT n'est pas 'production'"
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q "SUPABASE_URL=" .env.production && ! grep -q "SUPABASE_URL=$" .env.production; then
        echo "✅ SUPABASE_URL configuré"
    else
        echo "❌ SUPABASE_URL manquant"
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q "GEMINI_API_KEY=" .env.production && ! grep -q "GEMINI_API_KEY=$" .env.production; then
        echo "✅ GEMINI_API_KEY configuré"
    else
        echo "⚠️  GEMINI_API_KEY manquant"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "❌ .env.production n'existe pas!"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 2. Vérifier le widget iOS
echo "🔧 Vérification du widget iOS..."
if [ -d "ios/RyseMealWidget" ]; then
    echo "✅ Dossier ios/RyseMealWidget existe"

    if [ -f "ios/RyseMealWidget/RyseMealWidget.swift" ]; then
        echo "✅ RyseMealWidget.swift trouvé"
    else
        echo "❌ RyseMealWidget.swift manquant"
        ERRORS=$((ERRORS + 1))
    fi

    if [ -f "ios/RyseMealWidget/Info.plist" ]; then
        echo "✅ Widget Info.plist trouvé"
    else
        echo "❌ Widget Info.plist manquant"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ Dossier ios/RyseMealWidget n'existe pas!"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 3. Vérifier le scheme Xcode
echo "🎯 Vérification du scheme Xcode..."
if [ -f "ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme" ]; then
    echo "✅ Runner.xcscheme existe"

    if grep -q "RyseMealWidgetExtension" ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme; then
        echo "✅ Widget inclus dans le scheme"

        if grep -q "buildForArchiving = \"YES\"" ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme; then
            echo "✅ Widget configuré pour Archive"
        else
            echo "⚠️  Widget peut ne pas être archivé"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo "⚠️  Widget non trouvé dans le scheme"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "❌ Runner.xcscheme n'existe pas!"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 4. Vérifier les targets Xcode
echo "🎯 Vérification des targets Xcode..."
TARGETS=$(xcodebuild -list -project ios/Runner.xcodeproj 2>/dev/null | grep -A 10 "Targets:" | tail -n +2 | head -n 10)

if echo "$TARGETS" | grep -q "Runner"; then
    echo "✅ Target Runner trouvé"
else
    echo "❌ Target Runner manquant"
    ERRORS=$((ERRORS + 1))
fi

if echo "$TARGETS" | grep -q "RyseMealWidgetExtension"; then
    echo "✅ Target RyseMealWidgetExtension trouvé"
else
    echo "❌ Target RyseMealWidgetExtension manquant"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 5. Vérifier ExportOptions.plist
echo "📄 Vérification de ExportOptions.plist..."
if [ -f "ios/ExportOptions.plist" ]; then
    echo "✅ ExportOptions.plist existe"

    if grep -q "app-store" ios/ExportOptions.plist; then
        echo "✅ Method: app-store configuré"
    else
        echo "⚠️  Method n'est pas 'app-store'"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  ExportOptions.plist manquant (non critique)"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 6. Vérifier Flutter
echo "🔧 Vérification de Flutter..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo "✅ Flutter installé: $FLUTTER_VERSION"

    # Vérifier flutter doctor
    if flutter doctor --android-licenses > /dev/null 2>&1; then
        echo "✅ Flutter doctor OK"
    else
        echo "⚠️  Flutter doctor a des warnings"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "❌ Flutter n'est pas installé"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 7. Vérifier Xcode
echo "🛠️  Vérification de Xcode..."
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    echo "✅ Xcode installé: $XCODE_VERSION"
else
    echo "❌ Xcode n'est pas installé"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 8. Vérifier les dépendances
echo "📦 Vérification des dépendances..."
if [ -f "pubspec.yaml" ]; then
    echo "✅ pubspec.yaml existe"

    if [ -d ".dart_tool" ]; then
        echo "✅ Dépendances Flutter installées"
    else
        echo "⚠️  Dépendances non installées (exécutez 'flutter pub get')"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "❌ pubspec.yaml manquant"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 9. Vérifier la sécurité des clés API
echo "🔒 Vérification de la sécurité..."
if [ -f "./check_api_keys.sh" ]; then
    ./check_api_keys.sh > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Sécurité des clés API OK"
    else
        echo "⚠️  Vérifiez la sécurité des clés API"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  Script check_api_keys.sh manquant"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Résumé final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RÉSUMÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ PRÊT POUR TESTFLIGHT!"
    echo ""
    echo "🚀 Vous pouvez maintenant lancer:"
    echo "   ./build_testflight.sh"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  PRÊT AVEC WARNINGS ($WARNINGS warnings)"
    echo ""
    echo "🚀 Vous pouvez lancer le build, mais vérifiez les warnings:"
    echo "   ./build_testflight.sh"
    echo ""
    exit 0
else
    echo "❌ NON PRÊT POUR TESTFLIGHT"
    echo ""
    echo "Erreurs: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Corrigez les erreurs avant de continuer."
    exit 1
fi
