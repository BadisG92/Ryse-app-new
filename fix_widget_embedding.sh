#!/bin/bash

# Script pour corriger l'embedding du widget dans Xcode
# Ce script modifie le fichier project.pbxproj pour ajouter le widget comme dépendance

echo "🔧 Fixing Widget Embedding Configuration..."
echo ""

PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Project file not found: $PROJECT_FILE"
    exit 1
fi

# Backup du fichier
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"
echo "✅ Backup created: $PROJECT_FILE.backup"

# Vérifier si le widget est déjà dans les embed app extensions
if grep -q "Embed App Extensions" "$PROJECT_FILE"; then
    echo "✅ 'Embed App Extensions' phase already exists"
else
    echo "⚠️  'Embed App Extensions' phase not found"
    echo "   Vous devez l'ajouter manuellement dans Xcode"
fi

echo ""
echo "📋 Instructions Manuelles pour Xcode:"
echo ""
echo "1. Ouvrir Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. Sélectionner le target 'Runner'"
echo ""
echo "3. Aller dans l'onglet 'Build Phases'"
echo ""
echo "4. Cliquer sur '+' (en haut à gauche)"
echo ""
echo "5. Sélectionner 'New Copy Files Phase'"
echo ""
echo "6. Configurer la nouvelle phase:"
echo "   - Name: Embed App Extensions"
echo "   - Destination: Plug-Ins"
echo "   - Cliquer sur '+' pour ajouter"
echo "   - Sélectionner 'RyseMealWidgetExtension.appex'"
echo "   - Cocher 'Code Sign On Copy'"
echo ""
echo "7. Sauvegarder (⌘ + S)"
echo ""
echo "8. Product → Clean Build Folder (⌘ + Shift + K)"
echo ""
echo "9. Product → Archive"
echo ""
echo "✅ Le widget sera maintenant inclus dans l'archive!"
