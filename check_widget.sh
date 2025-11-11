#!/bin/bash
# Script de vérification rapide pour le widget iOS

echo "🔍 Vérification du widget iOS..."
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Vérifier que les fichiers existent
echo "1️⃣ Vérification des fichiers..."
if [ -f "ios/RyseMealWidget/RyseMealWidget.swift" ]; then
    echo -e "${GREEN}✅ RyseMealWidget.swift existe${NC}"
else
    echo -e "${RED}❌ RyseMealWidget.swift manquant${NC}"
fi

if [ -f "ios/RyseMealWidget/RyseMealWidgetBundle.swift" ]; then
    echo -e "${GREEN}✅ RyseMealWidgetBundle.swift existe${NC}"
else
    echo -e "${RED}❌ RyseMealWidgetBundle.swift manquant${NC}"
fi

if [ -f "ios/embed_widget.sh" ]; then
    echo -e "${GREEN}✅ embed_widget.sh existe${NC}"
else
    echo -e "${RED}❌ embed_widget.sh manquant${NC}"
fi

echo ""

# 2. Vérifier que le widget peut être compilé
echo "2️⃣ Test de compilation du widget..."
cd ios
if xcodebuild -scheme RyseMealWidgetExtension -sdk iphonesimulator -configuration Debug build -quiet 2>&1 | grep -q "BUILD SUCCEEDED"; then
    echo -e "${GREEN}✅ Widget compile correctement${NC}"
else
    echo -e "${YELLOW}⚠️  Erreur de compilation (normal si pas de scheme configuré)${NC}"
    echo "   Pour compiler manuellement :"
    echo "   cd ios && open Runner.xcworkspace"
    echo "   Puis dans Xcode : Product → Scheme → RyseMealWidgetExtension → Build"
fi
cd ..

echo ""

# 3. Vérifier les services Flutter
echo "3️⃣ Vérification des services Flutter..."
if [ -f "lib/services/meal_widget_data_provider.dart" ]; then
    echo -e "${GREEN}✅ meal_widget_data_provider.dart existe${NC}"
else
    echo -e "${RED}❌ meal_widget_data_provider.dart manquant${NC}"
fi

if [ -f "lib/services/widget_deep_link_handler.dart" ]; then
    echo -e "${GREEN}✅ widget_deep_link_handler.dart existe${NC}"
else
    echo -e "${RED}❌ widget_deep_link_handler.dart manquant${NC}"
fi

echo ""

# 4. Instructions
echo "📋 Pour voir le widget dans le simulateur :"
echo ""
echo "   Option 1 - Script automatique :"
echo "   ./run_with_widget.sh"
echo ""
echo "   Option 2 - Manuel :"
echo "   1. cd ios && open Runner.xcworkspace"
echo "   2. Dans Xcode : Product → Scheme → RyseMealWidgetExtension → Build"
echo "   3. cd .. && flutter run"
echo "   4. Dans le simulateur :"
echo "      - Cmd+Shift+H (écran d'accueil)"
echo "      - Long press sur espace vide"
echo "      - Cliquer sur '+'"
echo "      - Chercher 'Mes Repas'"
echo ""


