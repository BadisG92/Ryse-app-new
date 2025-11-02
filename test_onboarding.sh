#!/bin/bash

echo "🚀 Lancement de l'environnement de test onboarding..."
echo ""
echo "📱 Ce test va :"
echo "   1. Effacer les SharedPreferences"
echo "   2. Forcer l'affichage de l'onboarding"
echo "   3. Vous permettre de tester les nouvelles modifications"
echo ""
echo "🎯 Points à vérifier :"
echo "   ✓ Calculs caloriques améliorés (pas de valeurs trop basses)"
echo "   ✓ Affichage de l'estimation de temps (uniquement pour perte/gain)"
echo "   ✓ Texte sans détail kg/semaine"
echo "   ✓ Pas d'affichage pour maintien"
echo ""
echo "⏳ Démarrage..."
echo ""

# Lancer flutter avec le fichier de test
flutter run -t lib/test_onboarding_display.dart
