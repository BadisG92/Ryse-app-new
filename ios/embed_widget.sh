#!/bin/bash
# Script pour embarquer le widget extension dans l'app iOS
# Ce script est appelé automatiquement par Xcode lors du build
# Note: Pour 'flutter build ipa', Xcode gère automatiquement l'embedding

# Ne pas arrêter sur erreur car Flutter build ipa gère l'embedding différemment
set +e

WIDGET_EXTENSION_PATH="${BUILT_PRODUCTS_DIR}/RyseMealWidgetExtension.appex"
TARGET_PATH="${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/PlugIns/RyseMealWidgetExtension.appex"

echo "📱 Embedding widget extension..."

# Vérifier que le widget extension existe
if [ ! -d "$WIDGET_EXTENSION_PATH" ]; then
    echo "⚠️  Widget extension not found at: $WIDGET_EXTENSION_PATH"
    echo "   This is normal for 'flutter build ipa' - Xcode will handle it automatically"
    exit 0  # Ne pas faire échouer le build
fi

# Créer le dossier PlugIns s'il n'existe pas
mkdir -p "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/PlugIns" 2>/dev/null || true

# Copier le widget extension
echo "   Copying widget extension..."
if cp -R "$WIDGET_EXTENSION_PATH" "$TARGET_PATH" 2>/dev/null; then
    echo "✅ Widget extension embedded successfully"
else
    echo "⚠️  Widget copy skipped (may be handled by Flutter build)"
fi

# Toujours réussir pour ne pas bloquer le build
exit 0
