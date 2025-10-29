# 📄 Documents Légaux - Ryze App

## Fichiers Créés

- ✅ **privacy.html** - Politique de Confidentialité
- ✅ **terms.html** - Conditions Générales d'Utilisation
- ✅ **support.html** - Page de Support

## 🚀 Hébergement (Gratuit avec GitHub Pages)

### Étape 1: Créer un Repo GitHub

```bash
# 1. Aller sur github.com
# 2. Cliquer "New repository"
# 3. Nom: ryze-legal
# 4. Public
# 5. Create repository
```

### Étape 2: Pousser les Fichiers

```bash
# Dans le dossier legal-docs
cd "c:\rise app v2\ryze_app\legal-docs"

# Initialiser git
git init
git add .
git commit -m "Add legal documents"

# Connecter au repo GitHub
git remote add origin https://github.com/VOTRE_USERNAME/ryze-legal.git
git branch -M main
git push -u origin main
```

### Étape 3: Activer GitHub Pages

```
1. Aller sur: https://github.com/VOTRE_USERNAME/ryze-legal
2. Cliquer sur "Settings"
3. Dans le menu de gauche: "Pages"
4. Source: "Deploy from a branch"
5. Branch: main / (root)
6. Save
7. Attendre 2-3 minutes
```

### Étape 4: URLs Finales

Vos documents seront disponibles à :

```
https://VOTRE_USERNAME.github.io/ryze-legal/privacy.html
https://VOTRE_USERNAME.github.io/ryze-legal/terms.html
https://VOTRE_USERNAME.github.io/ryze-legal/support.html
```

## 📝 À Personnaliser

Avant de mettre en ligne, **recherchez et remplacez** dans les 3 fichiers HTML :

- `[VOTRE ADRESSE COMPLÈTE]` → Votre vraie adresse postale
- `[VOTRE NOM/SOCIÉTÉ]` → Votre nom ou nom de société
- `[SI APPLICABLE]` → Votre SIRET si vous en avez un

**Rechercher/Remplacer dans VS Code** :
```
Ctrl+Shift+F (Windows) ou Cmd+Shift+F (Mac)
Chercher: [VOTRE
```

## 🔗 Utilisation dans App Store Connect

1. **App Store Connect** → Your App → App Privacy
2. **Privacy Policy URL** : `https://VOTRE_USERNAME.github.io/ryze-legal/privacy.html`
3. **Support URL** : `https://VOTRE_USERNAME.github.io/ryze-legal/support.html`

## ✅ Checklist

- [ ] Fichiers HTML personnalisés (remplacer [VOTRE...])
- [ ] Repo GitHub créé
- [ ] Fichiers poussés sur GitHub
- [ ] GitHub Pages activé
- [ ] URLs testées (accessibles dans navigateur)
- [ ] URLs ajoutées dans App Store Connect

## 📧 Emails à Créer

Ces adresses email apparaissent dans les documents :

- `support@ryze-app.com` - Support client
- `privacy@ryze-app.com` - Questions confidentialité
- `bugs@ryze-app.com` - Signalement bugs
- `feature@ryze-app.com` - Suggestions
- `contact@ryze-app.com` - Contact général

**Option gratuite** : Créer des alias sur Gmail ou créer un compte professionnel.

## 🎨 Design

Les fichiers HTML sont stylisés avec :
- Police Apple system (cohérent avec iOS)
- Couleurs Ryze (#0B132B, #1C2951)
- Responsive (mobile-friendly)
- Accessibles et lisibles

## 📱 Test Mobile

Ouvrir sur iPhone pour tester :
```
Safari → Entrer l'URL → Vérifier affichage
```

---

**Date de création** : 29 octobre 2025
**Prêt pour** : Soumission App Store
