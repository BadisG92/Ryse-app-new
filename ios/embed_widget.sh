#!/bin/bash
# Script pour embarquer le widget extension dans l'app iOS
# Ce script est appelé automatiquement par Xcode lors du build

set -e

WIDGET_EXTENSION_PATH="${BUILT_PRODUCTS_DIR}/RyseMealWidgetExtension.appex"
TARGET_PATH="${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/PlugIns/RyseMealWidgetExtension.appex"

echo "📱 Embedding widget extension..."

# Vérifier que le widget extension existe
if [ ! -d "$WIDGET_EXTENSION_PATH" ]; then
    echo "⚠️  Widget extension not found at: $WIDGET_EXTENSION_PATH"
    echo "   This is normal if building without the widget target."
    echo "   To include the widget, build with: ./run_with_widget.sh"
    exit 0  # Ne pas faire échouer le build si le widget n'est pas compilé
fi

# Créer le dossier PlugIns s'il n'existe pas
mkdir -p "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/PlugIns"

# Copier le widget extension
echo "   Copying widget extension..."
cp -R "$WIDGET_EXTENSION_PATH" "$TARGET_PATH"

# Vérifier que la copie a réussi
if [ -d "$TARGET_PATH" ]; then
    echo "✅ Widget extension embedded successfully"
else
    echo "❌ Failed to embed widget extension"
    exit 1
fi
