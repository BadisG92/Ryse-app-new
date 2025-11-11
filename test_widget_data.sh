#!/bin/bash

# Script de test pour vérifier les données du widget iOS
# Vérifie que les vraies valeurs utilisateur sont bien synchronisées

echo "🧪 Test de synchronisation des données widget iOS"
echo "================================================"

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Vérifier que l'app est bien lancée
echo ""
echo "📱 Vérification de l'app..."
if pgrep -x "Runner" > /dev/null; then
    echo -e "${GREEN}✅ L'app Ryse est en cours d'exécution${NC}"
else
    echo -e "${YELLOW}⚠️ L'app n'est pas lancée. Lancement...${NC}"
    echo "Exécutez: flutter run --dart-define-from-file=.env.local"
    exit 1
fi

# 2. Récupérer les données du widget depuis UserDefaults
echo ""
echo "📊 Lecture des données widget depuis UserDefaults..."
echo "----------------------------------------------------"

# Fonction pour lire UserDefaults sur le simulateur iOS
read_widget_data() {
    # Trouver le chemin du simulateur actif
    DEVICE_ID=$(xcrun simctl list devices | grep -E 'Booted' | head -1 | awk -F'[()]' '{print $2}')

    if [ -z "$DEVICE_ID" ]; then
        echo -e "${RED}❌ Aucun simulateur iOS en cours d'exécution${NC}"
        echo "Lancez un simulateur depuis Xcode ou avec: open -a Simulator"
        exit 1
    fi

    echo "📱 Simulateur détecté: $DEVICE_ID"

    # Chemin vers les données de l'app
    APP_CONTAINER="$HOME/Library/Developer/CoreSimulator/Devices/$DEVICE_ID/data/Containers/Data/Application"

    # Trouver le conteneur de l'app Ryse
    RYSE_CONTAINER=$(find "$APP_CONTAINER" -name "group.com.ryze.app" 2>/dev/null | head -1)

    if [ -z "$RYSE_CONTAINER" ]; then
        # Essayer de trouver via le bundle ID
        for dir in "$APP_CONTAINER"/*; do
            if [ -f "$dir/Library/Preferences/com.ryse.app.plist" ]; then
                RYSE_CONTAINER="$dir"
                break
            fi
        done
    fi

    if [ -z "$RYSE_CONTAINER" ]; then
        echo -e "${YELLOW}⚠️ Conteneur de l'app non trouvé. L'app doit être lancée au moins une fois.${NC}"
        exit 1
    fi

    echo "📂 Conteneur trouvé: $(basename "$RYSE_CONTAINER")"

    # Lire les données du widget
    PLIST_PATH="$RYSE_CONTAINER/Library/Preferences/group.com.ryze.app.plist"

    if [ -f "$PLIST_PATH" ]; then
        echo ""
        echo "📖 Données du widget:"
        echo "--------------------"

        # Extraire et parser le JSON
        /usr/libexec/PlistBuddy -c "Print :widget_meal_data" "$PLIST_PATH" 2>/dev/null | python3 -c "
import sys
import json

try:
    data = sys.stdin.read()
    if data:
        parsed = json.loads(data)

        # Afficher les objectifs
        totals = parsed.get('totals', {})
        water = parsed.get('water', {})

        print('🎯 Objectifs utilisateur:')
        print(f'   Calories: {totals.get(\"goal\", 0)} kcal')
        print(f'   Eau: {water.get(\"goalL\", 0)} L ({water.get(\"goal\", 0)} ml)')

        print('')
        print('📊 Consommation actuelle:')
        print(f'   Calories: {totals.get(\"current\", 0)} kcal ({totals.get(\"percentage\", 0)}%)')
        print(f'   Eau: {water.get(\"currentL\", 0)} L ({water.get(\"percentage\", 0)}%)')

        # Vérifier les valeurs
        print('')
        calorie_goal = totals.get('goal', 0)
        water_goal = water.get('goal', 0)

        if calorie_goal == 0 or calorie_goal == 2000:
            print('❌ PROBLÈME: Objectif calories est', calorie_goal, '(valeur par défaut ou 0)')
        else:
            print('✅ Objectif calories personnalisé:', calorie_goal, 'kcal')

        if water_goal == 0 or water_goal == 2000:
            print('❌ PROBLÈME: Objectif eau est', water_goal, 'ml (valeur par défaut ou 0)')
        else:
            print('✅ Objectif eau personnalisé:', water_goal, 'ml')

    else:
        print('⚠️ Aucune donnée widget trouvée')
except json.JSONDecodeError as e:
    print('❌ Erreur de parsing JSON:', str(e))
except Exception as e:
    print('❌ Erreur:', str(e))
" || echo -e "${YELLOW}⚠️ Aucune donnée widget trouvée dans UserDefaults${NC}"
    else
        echo -e "${YELLOW}⚠️ Fichier de préférences non trouvé${NC}"
    fi
}

# 3. Exécuter le test
read_widget_data

echo ""
echo "================================================"
echo "📝 Conseils de debug:"
echo ""
echo "1. Si les valeurs sont à 0 ou par défaut:"
echo "   - Relancez l'app: flutter run --dart-define-from-file=.env.local"
echo "   - Connectez-vous avec votre compte"
echo "   - Attendez quelques secondes"
echo ""
echo "2. Pour voir les logs du widget:"
echo "   - Ouvrez Xcode → Window → Devices and Simulators"
echo "   - Sélectionnez votre appareil"
echo "   - Cliquez sur 'View Device Logs'"
echo ""
echo "3. Pour forcer le refresh du widget:"
echo "   - Sur le simulateur, maintenez appuyé sur le widget"
echo "   - Choisissez 'Edit Widget' puis supprimez-le"
echo "   - Rajoutez-le depuis la galerie de widgets"
echo ""
echo "✨ Fin du test"