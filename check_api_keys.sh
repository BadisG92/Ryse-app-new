#!/bin/bash

# 🔒 Script de vérification de sécurité des clés API
# À exécuter avant chaque commit

echo "🔍 Vérification de sécurité des clés API..."
echo ""

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteur d'erreurs
ERRORS=0

# 1. Vérifier qu'il n'y a pas de clés Gemini dans le code
echo "1️⃣  Recherche de clés Gemini hardcodées..."
# Exclure les fichiers .md (documentation) et les commentaires
GEMINI_FOUND=$(grep -r "AIza" lib/ --exclude-dir=node_modules --exclude-dir=.dart_tool --exclude="*.md" 2>/dev/null | grep -v "// " | grep -v "fromEnvironment" | grep -v "EnvConfig")
if [ -n "$GEMINI_FOUND" ]; then
    echo -e "${RED}❌ ERREUR : Clé API Gemini trouvée dans le code !${NC}"
    echo "$GEMINI_FOUND"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ Aucune clé Gemini hardcodée trouvée${NC}"
fi
echo ""

# 2. Vérifier qu'il n'y a pas de clés Supabase hardcodées
echo "2️⃣  Recherche de clés Supabase hardcodées..."
if grep -r "eyJ" lib/config/ --exclude-dir=node_modules --exclude-dir=.dart_tool 2>/dev/null | grep -v "fromEnvironment" | grep -v "//"; then
    echo -e "${RED}❌ ERREUR : Clé Supabase trouvée dans le code !${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ Aucune clé Supabase hardcodée trouvée${NC}"
fi
echo ""

# 3. Vérifier que .env.local est bien gitignored
echo "3️⃣  Vérification de .gitignore..."
if git check-ignore .env.local > /dev/null 2>&1; then
    echo -e "${GREEN}✅ .env.local est bien dans .gitignore${NC}"
else
    echo -e "${RED}❌ ERREUR : .env.local n'est PAS dans .gitignore !${NC}"
    ERRORS=$((ERRORS + 1))
fi

if git check-ignore .env.production > /dev/null 2>&1; then
    echo -e "${GREEN}✅ .env.production est bien dans .gitignore${NC}"
else
    echo -e "${RED}❌ ERREUR : .env.production n'est PAS dans .gitignore !${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 4. Vérifier qu'aucun fichier .env n'est tracké par Git
echo "4️⃣  Vérification des fichiers .env trackés..."
TRACKED_ENV=$(git ls-files | grep "\.env$\|\.env\.local$\|\.env\.production$")
if [ -n "$TRACKED_ENV" ]; then
    echo -e "${RED}❌ ERREUR : Fichiers .env trackés par Git :${NC}"
    echo "$TRACKED_ENV"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ Aucun fichier .env tracké par Git${NC}"
fi
echo ""

# 5. Vérifier que les fichiers de config utilisent bien EnvConfig
echo "5️⃣  Vérification de l'utilisation d'EnvConfig..."
CONFIG_FILES=$(find lib/config -name "*.dart" ! -name "env_config.dart")
BAD_CONFIG=0
for file in $CONFIG_FILES; do
    if grep -q "static const String.*=.*['\"]AIza" "$file" || \
       grep -q "static const String.*=.*['\"]eyJ" "$file"; then
        echo -e "${RED}❌ ERREUR : $file contient des clés hardcodées${NC}"
        BAD_CONFIG=1
        ERRORS=$((ERRORS + 1))
    fi
done
if [ $BAD_CONFIG -eq 0 ]; then
    echo -e "${GREEN}✅ Tous les fichiers de config utilisent EnvConfig${NC}"
fi
echo ""

# 6. Vérifier que .env.local existe
echo "6️⃣  Vérification de la présence de .env.local..."
if [ -f ".env.local" ]; then
    echo -e "${GREEN}✅ .env.local existe${NC}"

    # Vérifier que les clés sont configurées
    if grep -q "GEMINI_API_KEY=AIza" .env.local; then
        echo -e "${GREEN}✅ GEMINI_API_KEY configurée${NC}"
    else
        echo -e "${YELLOW}⚠️  GEMINI_API_KEY non configurée dans .env.local${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  .env.local n'existe pas (créez-le depuis .env.example)${NC}"
fi
echo ""

# Résumé final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ SÉCURITÉ OK - Aucune fuite détectée${NC}"
    echo ""
    echo "Vous pouvez commiter en toute sécurité 🚀"
    exit 0
else
    echo -e "${RED}❌ SÉCURITÉ COMPROMISE - $ERRORS erreur(s) trouvée(s)${NC}"
    echo ""
    echo "🚫 NE COMMITEZ PAS avant d'avoir corrigé ces erreurs !"
    echo ""
    echo "📚 Voir SECURITY_API_KEYS.md pour plus d'informations"
    exit 1
fi
