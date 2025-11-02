#!/bin/bash

# Script de lancement pour iOS en développement avec variables d'environnement

echo "🚀 Lancement de Ryse App (iOS Dev) avec configuration .env.local"
echo "================================================"

# Vérifier que .env.local existe
if [ ! -f .env.local ]; then
    echo "❌ Erreur: .env.local n'existe pas"
    echo "   Copiez .env.example vers .env.local et configurez vos clés"
    exit 1
fi

echo "✅ Fichier .env.local trouvé"
echo ""
echo "📱 Lancement de l'application..."

flutter run --dart-define-from-file=.env.local

