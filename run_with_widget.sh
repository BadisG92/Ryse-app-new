#!/bin/bash
# Script pour lancer l'app Ryse avec le widget iOS
set -e

echo "🚀 Lancement de Ryse avec widget iOS"
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Étape 1: Compiler le widget extension
echo -e "${BLUE}📦 Étape 1/3: Compilation du widget extension...${NC}"
cd ios
xcodebuild -scheme RyseMealWidgetExtension \
    -sdk iphonesimulator \
    -configuration Debug \
    build \
    | grep -E "BUILD SUCCEEDED|error:|warning:" || true

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Widget compilé avec succès${NC}"
else
    echo -e "${RED}❌ Échec de la compilation du widget${NC}"
    exit 1
fi

cd ..

# Étape 2: Lancer l'app Flutter
echo -e "${BLUE}📱 Étape 2/3: Lancement de l'app Flutter...${NC}"
echo ""

# Détecter le simulateur
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone.*Booted" | head -1 | grep -o '[A-F0-9-]\{36\}' || echo "")

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${RED}❌ Aucun simulateur démarré${NC}"
    echo "Démarrage du simulateur iPhone 13 Pro..."
    open -a Simulator
    sleep 5
    xcrun simctl boot "iPhone 13 Pro" 2>/dev/null || true
    sleep 3
    SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 13 Pro.*Booted" | head -1 | grep -o '[A-F0-9-]\{36\}')
fi

echo -e "${GREEN}✅ Simulateur détecté: $SIMULATOR_ID${NC}"
echo ""

# Lancer Flutter
echo -e "${BLUE}🔥 Lancement de Flutter...${NC}"
flutter run -d "$SIMULATOR_ID" --dart-define-from-file=.env.local

echo ""
echo -e "${GREEN}✅ App lancée avec succès!${NC}"
echo ""
echo "📋 Pour tester le widget:"
echo "  1. Retournez à l'écran d'accueil (Cmd+Shift+H)"
echo "  2. Long press sur un espace vide"
echo "  3. Cliquez sur '+' en haut à gauche"
echo "  4. Cherchez 'Mes Repas' ou 'Ryse'"
echo "  5. Ajoutez le widget"
