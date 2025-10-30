#!/usr/bin/env python3
"""
Script pour mettre à jour automatiquement le Run Script dans le projet Xcode
pour compiler et embarquer le widget extension.
"""

import os
import re

# Chemin vers le projet Xcode
pbxproj_path = os.path.join(os.path.dirname(__file__), 'Runner.xcodeproj', 'project.pbxproj')

print(f"📝 Modification de {pbxproj_path}...")

# Lire le fichier
with open(pbxproj_path, 'r') as f:
    content = f.read()

# Nouveau script shell
new_script = '"${SRCROOT}/embed_widget.sh"'

# Pattern pour trouver le shellScript dans la section "Embed Widget Extension"
# On cherche le shellScript qui contient "Embed Widget" dans son nom
pattern = r'(shellScript = ")([^"]*?)(";\s*showEnvVarsInLog[^}]*?name = "Embed Widget Extension";)'

def replace_script(match):
    return match.group(1) + new_script[1:-1] + match.group(3)

# Remplacer le script
new_content = re.sub(pattern, replace_script, content, flags=re.DOTALL)

# Vérifier si on a fait un changement
if new_content != content:
    # Sauvegarder le fichier
    with open(pbxproj_path, 'w') as f:
        f.write(new_content)
    print("✅ Script Xcode mis à jour avec succès")
    print(f"   Nouveau script: {new_script}")
else:
    print("⚠️ Aucun changement détecté - le script pourrait déjà être à jour")
    # Essayer de trouver et afficher le script actuel
    match = re.search(r'shellScript = "([^"]*)".*?name = "Embed Widget Extension"', content, re.DOTALL)
    if match:
        print(f"   Script actuel: {match.group(1)[:100]}...")
