#!/bin/bash
# Script pour compiler le widget ET lancer l'app Flutter

set -e

echo "🚀 Compilation du widget et lancement de l'app..."
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Étape 1: Compiler le widget extension
echo -e "${BLUE}📦 Étape 1/3: Compilation du widget extension...${NC}"
cd ios

# Vérifier si le workspace existe
if [ ! -f "Runner.xcworkspace/contents.xcworkspacedata" ]; then
    echo -e "${RED}❌ Runner.xcworkspace introuvable${NC}"
    echo "   Exécutez: cd ios && pod install"
    exit 1
fi

# Compiler le widget
echo "   Compilation en cours..."
xcodebuild -workspace Runner.xcworkspace \
    -scheme RyseMealWidgetExtension \
    -sdk iphonesimulator \
    -configuration Debug \
    -derivedDataPath build \
    build 2>&1 | tee /tmp/widget_build.log

if grep -q "BUILD SUCCEEDED" /tmp/widget_build.log; then
    echo -e "${GREEN}✅ Widget compilé avec succès${NC}"
else
    echo -e "${YELLOW}⚠️  Erreur de compilation du widget${NC}"
    echo "   Vérifiez les logs ci-dessus"
    echo ""
    echo "   Solution alternative :"
    echo "   1. Ouvrir Xcode: open Runner.xcworkspace"
    echo "   2. Sélectionner scheme: RyseMealWidgetExtension"
    echo "   3. Product → Build (Cmd+B)"
    echo "   4. Revenir au scheme Runner et lancer l'app"
    exit 1
fi

cd ..

# Étape 2: Vérifier le simulateur
echo ""
echo -e "${BLUE}📱 Étape 2/3: Vérification du simulateur...${NC}"

SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone.*Booted" | head -1 | grep -o '[A-F0-9-]\{36\}' || echo "")

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${YELLOW}⚠️  Aucun simulateur démarré${NC}"
    echo "   Démarrage d'un simulateur..."
    open -a Simulator
    sleep 3
    
    # Essayer de démarrer iPhone 16 Pro
    xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || {
        echo "   Tentative avec iPhone 15 Pro..."
        xcrun simctl boot "iPhone 15 Pro" 2>/dev/null || {
            echo "   Utilisation du premier iPhone disponible..."
            FIRST_IPHONE=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/')
            if [ ! -z "$FIRST_IPHONE" ]; then
                xcrun simctl boot "$FIRST_IPHONE" 2>/dev/null || true
            fi
        }
    }
    
    sleep 3
    SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone.*Booted" | head -1 | grep -o '[A-F0-9-]\{36\}' || echo "")
fi

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${RED}❌ Impossible de démarrer un simulateur${NC}"
    exit 1
fi

SIMULATOR_NAME=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | sed 's/.*\(iPhone.*\) (.*/\1/')
echo -e "${GREEN}✅ Simulateur détecté: $SIMULATOR_NAME ($SIMULATOR_ID)${NC}"

# Étape 3: Lancer Flutter
echo ""
echo -e "${BLUE}🔥 Étape 3/3: Lancement de l'app Flutter...${NC}"
echo ""

# Nettoyer le build Flutter pour forcer la recompilation avec le widget
flutter clean
flutter pub get

# Lancer l'app
flutter run -d "$SIMULATOR_ID" --dart-define-from-file=.env.local

echo ""
echo -e "${GREEN}✅ App lancée!${NC}"
echo ""
echo "📋 Pour voir le widget:"
echo "   1. Dans le simulateur: Cmd+Shift+H (écran d'accueil)"
echo "   2. Long press sur un espace vide"
echo "   3. Cliquer sur '+' en haut à gauche"
echo "   4. Chercher 'Mes Repas' ou 'Ryse'"
echo ""


