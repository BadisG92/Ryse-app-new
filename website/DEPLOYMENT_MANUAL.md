# 🚀 Guide de Déploiement Manuel - Netlify

**Date** : 9 novembre 2025
**Version** : 1.1 - Design aligné avec l'app Flutter

---

## 📝 Résumé des Modifications

### ✅ Ce qui a été changé

1. **Logo Ryse** - Exactement comme dans l'app Flutter
   - Container carré avec gradient bleu (#0B132B → #1C2951)
   - Panda SVG blanc à l'intérieur
   - Texte "Ryze" en FontWeight 900, letter-spacing -1

2. **Images Coach Ryze** - Ajoutées
   - 6 avatars Coach Ryze panda copiés dans `/assets/images/coach/`
   - Remplacent les emojis génériques
   - Image hero avec `coach_ryze_welcome_arms.png`

3. **Gradients Verts** - Supprimés
   - Tous remplacés par gradients bleu uniquement
   - Plus de pastilles vertes

4. **CSS** - Ajouté
   - Styles `.logo-container` et `.logo-text`
   - Styles `.feature-image` pour les avatars Coach Ryze
   - Styles `.coach-ryze-hero`

---

## 🎯 Comment Déployer sur Netlify

### Méthode : Drag & Drop (puisque GitHub n'est plus synchronisé)

#### Étape 1 : Créer un ZIP du dossier website

```bash
cd /Users/badis/Documents/Ryse-app-new
zip -r website_v1.1.zip website/
```

**OU** via Finder :
1. Ouvre le Finder
2. Va dans `/Users/badis/Documents/Ryse-app-new/`
3. Clic droit sur le dossier `website/`
4. Sélectionne "Compresser 'website'"
5. Tu obtiens `website.zip`

#### Étape 2 : Déployer sur Netlify

1. Va sur [https://app.netlify.com](https://app.netlify.com)
2. Connecte-toi à ton compte
3. Clique sur ton site **coach-ryze**
4. Va dans l'onglet **"Deploys"**
5. Fais glisser le dossier `website/` directement dans la zone **"Drag and drop your site output folder here"**
   - ⚠️ **IMPORTANT** : Glisse le **contenu** du dossier `website/`, PAS le dossier lui-même
   - Tu dois voir `index.html`, `assets/`, etc. à la racine

#### Étape 3 : Attendre le déploiement

- Netlify va automatiquement déployer le site (1-2 minutes)
- Tu verras "Site is live" quand c'est fini
- Le site sera accessible sur `https://coach-ryze.com`

---

## ✅ Vérifications Post-Déploiement

### 1. Logo
- [ ] Le logo Ryze s'affiche avec le container gradient bleu
- [ ] Le panda est blanc à l'intérieur
- [ ] Le texte "Ryze" est en gras (900) et serré

### 2. Images Coach Ryze
- [ ] Section Features : Les avatars Coach Ryze s'affichent
- [ ] Section Hero : `coach_ryze_welcome_arms.png` s'affiche

### 3. Gradients
- [ ] Plus de gradient vert nulle part
- [ ] Tous les gradients sont bleu (#0B132B → #3B82F6)

### 4. Responsive
- [ ] Le site s'affiche correctement sur mobile
- [ ] Le menu hamburger fonctionne

---

## 📂 Fichiers Modifiés

```
website/
├── index.html                         [MODIFIÉ - Nouveau logo + images Coach Ryze]
├── assets/
│   ├── css/
│   │   └── style.css                  [MODIFIÉ - Ajout styles logo + suppression vert]
│   └── images/
│       └── coach/                     [NOUVEAU DOSSIER]
│           ├── coach_ryze_welcome_arms.png
│           ├── coach_ryze_nutrition_avatar.png
│           ├── coach_ryze_sport_avatar.png
│           ├── coach_ryze_chef_avatar.png
│           ├── coach_ryze_workout_avatar.png
│           └── coach_ryze_congratulations.png
```

---

## 🐛 Troubleshooting

### Le logo ne s'affiche pas correctement ?
1. Vérifie que `logo_ryze.svg` est bien dans `assets/images/`
2. Vide le cache navigateur : `Cmd + Shift + R`

### Les images Coach Ryze ne s'affichent pas ?
1. Vérifie que le dossier `assets/images/coach/` a bien été uploadé
2. Vérifie les permissions des images (644)

### Le gradient est encore vert ?
1. Vérifie que le nouveau `style.css` a bien été uploadé
2. Vide le cache : `Cmd + Shift + R`

---

## 📞 Support

Si tu as des problèmes :
1. Vérifie les Deploy logs dans Netlify
2. Vérifie la console navigateur (F12) pour les erreurs

---

## 🎉 Prochaines Étapes

Après le déploiement :
1. Teste le site sur mobile et desktop
2. Partage le lien sur Instagram/Twitter
3. Ajoute de vrais screenshots de l'app dans la section Screenshots

---

**Temps estimé** : 5-10 minutes
**Difficulté** : Facile 🟢

Bon déploiement ! 🚀
