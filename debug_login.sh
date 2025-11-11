#!/bin/bash

echo "🔧 Debug du problème de connexion"
echo "================================="
echo ""

# Vérifier les clés API
echo "1️⃣ Vérification des clés API..."
if [ -f .env.local ]; then
    echo "✅ Fichier .env.local trouvé"

    # Vérifier que les clés ne sont pas vides
    SUPABASE_URL=$(grep "SUPABASE_URL" .env.local | cut -d'=' -f2 | tr -d '"')
    SUPABASE_KEY=$(grep "SUPABASE_ANON_KEY" .env.local | cut -d'=' -f2 | tr -d '"')

    if [ -z "$SUPABASE_URL" ]; then
        echo "❌ SUPABASE_URL est vide!"
    else
        echo "✅ SUPABASE_URL définie: ${SUPABASE_URL:0:30}..."
    fi

    if [ -z "$SUPABASE_KEY" ]; then
        echo "❌ SUPABASE_ANON_KEY est vide!"
    else
        echo "✅ SUPABASE_ANON_KEY définie: ${SUPABASE_KEY:0:20}..."
    fi
else
    echo "❌ Fichier .env.local manquant!"
    echo "   Copiez .env.example vers .env.local et ajoutez vos clés"
    exit 1
fi

echo ""
echo "2️⃣ Nettoyage et reconstruction..."
flutter clean
flutter pub get

echo ""
echo "3️⃣ Lancement de l'app avec debug activé..."
echo ""
echo "📝 Instructions:"
echo "1. Essayez de vous connecter"
echo "2. Regardez les logs ci-dessous pour identifier l'erreur"
echo "3. Si vous voyez 'Invalid API key' → Vérifiez vos clés Supabase"
echo "4. Si vous voyez 'Network error' → Vérifiez votre connexion internet"
echo ""
echo "Lancement..."
flutter run --dart-define-from-file=.env.local --verbose 2>&1 | grep -E "auth|Auth|sign|Sign|login|Login|error|Error|Supabase|supabase"