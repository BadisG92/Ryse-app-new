# 🚀 Guide de Déploiement - coach-ryze.com sur GoDaddy

Guide complet pas-à-pas pour déployer votre site web sur GoDaddy.

---

## 📋 Table des Matières

1. [Préparation](#préparation)
2. [Méthode 1: File Manager GoDaddy (Facile)](#méthode-1-file-manager-godaddy)
3. [Méthode 2: FTP (Recommandée)](#méthode-2-ftp-recommandée)
4. [Configuration DNS](#configuration-dns)
5. [Activation SSL/HTTPS](#activation-ssl-https)
6. [Configuration Emails](#configuration-emails)
7. [Tests et Vérification](#tests-et-vérification)
8. [Optimisations Post-Déploiement](#optimisations-post-déploiement)

---

## 🎯 Préparation

### 1. Créer un fichier ZIP du site

```bash
cd /Users/badis/Documents/Ryse-app-new
zip -r website.zip website/ -x "*.DS_Store" "*node_modules*" "*.git*"
```

Votre fichier `website.zip` est prêt pour l'upload !

### 2. Checklist Avant Déploiement

- [ ] Tous les fichiers HTML sont prêts
- [ ] CSS et JS sont fonctionnels localement
- [ ] favicon.svg créé
- [ ] sitemap.xml généré
- [ ] robots.txt configuré
- [ ] .htaccess prêt pour HTTPS
- [ ] Screenshots ajoutés (si disponibles)

---

## 🌐 Méthode 1: File Manager GoDaddy

**⏱️ Temps estimé**: 15 minutes

### Étape 1: Connexion à GoDaddy

1. Allez sur [godaddy.com](https://www.godaddy.com)
2. Cliquez sur **"Sign In"** (Se connecter)
3. Entrez vos identifiants
4. Cliquez sur **"My Products"** (Mes produits)

### Étape 2: Accéder au cPanel

1. Trouvez votre hébergement web (**Web Hosting**)
2. Cliquez sur **"Manage"** (Gérer) à côté de coach-ryze.com
3. Cliquez sur **"cPanel Admin"**
4. Dans la section **Files** (Fichiers), cliquez sur **"File Manager"**

### Étape 3: Préparer le Répertoire

1. Naviguez vers `/public_html/`
2. **IMPORTANT**: Si des fichiers existent déjà :
   - Sélectionnez tous les anciens fichiers
   - Cliquez sur **"Delete"** (Supprimer)
   - Confirmez la suppression

### Étape 4: Upload des Fichiers

**Option A: Upload ZIP (Recommandé)**

1. Cliquez sur **"Upload"** dans la barre d'outils
2. Faites glisser `website.zip` ou cliquez pour sélectionner
3. Attendez que l'upload soit terminé (barre verte = 100%)
4. Retournez au File Manager
5. Cliquez-droit sur `website.zip` → **"Extract"** (Extraire)
6. Sélectionnez `/public_html/` comme destination
7. Cliquez sur **"Extract File(s)"**
8. Supprimez `website.zip` après extraction

**Option B: Upload Manuel**

1. Dans `/public_html/`, cliquez sur **"Upload"**
2. Uploadez **tous les fichiers** du dossier `website/` :
   ```
   ✓ index.html
   ✓ privacy.html
   ✓ terms.html
   ✓ support.html
   ✓ sitemap.xml
   ✓ robots.txt
   ✓ .htaccess
   ✓ assets/ (tout le dossier)
   ```

### Étape 5: Vérifier la Structure

Votre `/public_html/` doit ressembler à :

```
public_html/
├── index.html
├── privacy.html
├── terms.html
├── support.html
├── sitemap.xml
├── robots.txt
├── .htaccess
└── assets/
    ├── css/
    │   └── style.css
    ├── js/
    │   └── main.js
    └── images/
        └── favicon.svg
```

### Étape 6: Vérifier les Permissions

1. Sélectionnez tous les fichiers HTML
2. Cliquez-droit → **"Change Permissions"**
3. Fichiers: `644` (ou cochez: Owner Read+Write, Group Read, World Read)
4. Dossiers: `755` (ou cochez: Owner Read+Write+Execute, Group Read+Execute, World Read+Execute)

✅ **C'est fait !** Votre site est uploadé.

---

## 📡 Méthode 2: FTP (Recommandée)

**⏱️ Temps estimé**: 10 minutes

### Étape 1: Obtenir les Identifiants FTP

1. GoDaddy → **My Products** → **Web Hosting**
2. Cliquez sur **"Manage"** (Gérer)
3. Cliquez sur **"FTP"** dans la section **Settings**
4. Notez vos identifiants :
   - **FTP Hostname**: `ftp.coach-ryze.com` (ou IP fournie)
   - **Username**: `[votre_username]@coach-ryze.com`
   - **Password**: Votre mot de passe FTP

### Étape 2: Installer un Client FTP

**Téléchargez FileZilla** (gratuit):
- Mac: [filezilla-project.org](https://filezilla-project.org/download.php?type=client)
- Ou utilisez **Cyberduck** (alternative Mac)

### Étape 3: Connexion FTP

1. Ouvrez FileZilla
2. En haut, renseignez :
   - **Hôte**: `ftp://ftp.coach-ryze.com`
   - **Identifiant**: `[username]@coach-ryze.com`
   - **Mot de passe**: `[votre_password]`
   - **Port**: `21`
3. Cliquez sur **"Connexion rapide"**

### Étape 4: Upload via FTP

1. **Panneau gauche** (local): Naviguez vers `/Users/badis/Documents/Ryse-app-new/website/`
2. **Panneau droit** (serveur): Naviguez vers `/public_html/`
3. **Sélectionnez tous les fichiers** du panneau gauche
4. **Faites glisser** vers le panneau droit
5. Attendez la fin du transfert (barre verte en bas)

### Étape 5: Vérification

1. Dans FileZilla, panneau droit, vérifiez que tous les fichiers sont présents
2. Les fichiers doivent avoir les bonnes permissions automatiquement

✅ **Upload terminé !**

---

## 🌍 Configuration DNS

**⏱️ Temps de propagation**: 24-48h (souvent plus rapide)

### Étape 1: Vérifier les DNS

1. GoDaddy → **My Products** → **Domains**
2. Cliquez sur **"DNS"** à côté de `coach-ryze.com`

### Étape 2: Configuration des Enregistrements

Vérifiez que vous avez ces enregistrements **A** :

| Type | Nom | Valeur | TTL |
|------|-----|--------|-----|
| A | @ | [IP de votre hébergement] | 1 Hour |
| A | www | [IP de votre hébergement] | 1 Hour |

**Pour trouver l'IP de votre hébergement** :
1. GoDaddy → Web Hosting → Manage
2. Section **Settings** → **Server IP Address**

### Étape 3: Vérifier la Propagation DNS

Utilisez ces outils pour vérifier :
- [dnschecker.org](https://dnschecker.org)
- Entrez `coach-ryze.com`
- Attendez que tous les serveurs montrent votre IP

---

## 🔒 Activation SSL/HTTPS

**⚠️ CRUCIAL pour App Store et SEO**

### Étape 1: Installer le Certificat SSL

1. GoDaddy cPanel → Section **Security** (Sécurité)
2. Cliquez sur **"SSL/TLS Status"**
3. Trouvez `coach-ryze.com` dans la liste
4. Cliquez sur **"Run AutoSSL"** (Exécuter AutoSSL)
5. Attendez 2-5 minutes

Ou :

1. cPanel → **SSL/TLS**
2. Cliquez sur **"Manage SSL sites"**
3. Sélectionnez `coach-ryze.com`
4. Cliquez sur **"AutoSSL"** ou **"Let's Encrypt"** (gratuit)
5. Installez le certificat

### Étape 2: Vérifier HTTPS

1. Allez sur `https://coach-ryze.com` (notez le **https**)
2. Vous devriez voir un **cadenas vert** dans la barre d'adresse
3. Si erreur SSL, attendez quelques minutes et réessayez

### Étape 3: Forcer HTTPS (Déjà dans .htaccess)

Votre `.htaccess` inclut déjà la redirection HTTP → HTTPS :

```apache
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

✅ Vérifiez : `http://coach-ryze.com` devrait rediriger vers `https://coach-ryze.com`

---

## 📧 Configuration Emails

### Créer les Adresses Email

1. GoDaddy → **Email & Office** → **Workspace Email**
2. Si pas encore acheté, achetez un plan (environ 5€/mois)
3. Créez ces adresses :
   - `support@coach-ryze.com` (REQUIS pour App Store)
   - `privacy@coach-ryze.com`
   - `legal@coach-ryze.com`
   - `dpo@coach-ryze.com`
   - `contact@coach-ryze.com`

### Configuration Redirection (Optionnel)

Si vous voulez rediriger vers votre email personnel :

1. cPanel → **Email Accounts**
2. Cliquez sur **"Forwarders"**
3. Créez des redirections :
   ```
   support@coach-ryze.com → votre_email_perso@gmail.com
   privacy@coach-ryze.com → votre_email_perso@gmail.com
   ```

### Configurer sur iPhone/Mac

1. Paramètres → Mail → Comptes → Ajouter un compte
2. Choisissez **Autre** → **Ajouter un compte Mail**
3. Renseignez :
   - **Serveur entrant** : `imap.secureserver.net`
   - **Port** : `993` (SSL)
   - **Serveur sortant** : `smtpout.secureserver.net`
   - **Port** : `465` (SSL)
   - **Email** : `support@coach-ryze.com`
   - **Mot de passe** : [celui défini sur GoDaddy]

---

## ✅ Tests et Vérification

### Test 1: Accessibilité du Site

1. Ouvrez `https://coach-ryze.com`
2. Vérifiez que la page d'accueil s'affiche correctement
3. Testez tous les liens de navigation
4. Vérifiez chaque page :
   - [ ] `https://coach-ryze.com/` (Landing page)
   - [ ] `https://coach-ryze.com/support.html` (FAQ)
   - [ ] `https://coach-ryze.com/privacy.html` (Privacy)
   - [ ] `https://coach-ryze.com/terms.html` (Terms)

### Test 2: Responsive Mobile

1. Ouvrez Chrome DevTools (F12)
2. Cliquez sur l'icône mobile (📱)
3. Testez différentes tailles :
   - iPhone SE (375px)
   - iPhone 14 Pro (393px)
   - iPad (768px)
   - Desktop (1920px)

### Test 3: Performance

1. Allez sur [PageSpeed Insights](https://pagespeed.web.dev/)
2. Entrez `https://coach-ryze.com`
3. Attendez les résultats
4. **Objectif** : Score > 90/100 sur Mobile ET Desktop

### Test 4: SEO

1. Vérifiez `https://coach-ryze.com/robots.txt`
2. Vérifiez `https://coach-ryze.com/sitemap.xml`
3. Allez sur [Google Search Console](https://search.google.com/search-console)
4. Ajoutez votre propriété `coach-ryze.com`
5. Soumettez le sitemap

### Test 5: Sécurité

1. Allez sur [SSL Labs](https://www.ssllabs.com/ssltest/)
2. Entrez `coach-ryze.com`
3. **Objectif** : Note A ou A+

### Test 6: Emails

1. Envoyez un email de test à `support@coach-ryze.com`
2. Vérifiez que vous le recevez
3. Répondez pour tester l'envoi

---

## 🎨 Optimisations Post-Déploiement

### 1. Ajouter Screenshots Réels

**IMPORTANT** : Remplacez les SVG placeholders dans `index.html`

1. Prenez des screenshots de votre app sur iPhone :
   - Dashboard principal
   - Scanner IA en action
   - Cardio GPS avec carte
   - Workout session
   - Widget iOS

2. Optimisez les images :
   ```bash
   # Utilisez TinyPNG (https://tinypng.com) pour compresser
   # Ou installez ImageOptim (Mac) et glissez les images
   ```

3. Uploadez dans `/public_html/assets/images/screenshots/`

4. Modifiez `index.html` :
   ```html
   <!-- Remplacez les <svg> par -->
   <img src="assets/images/screenshots/dashboard.png" alt="Dashboard Ryse">
   ```

### 2. Créer Apple Touch Icon

1. Créez une image PNG 180x180px du logo Ryse
2. Nommez-la `apple-touch-icon.png`
3. Uploadez dans `/public_html/assets/images/`
4. L'icône apparaîtra quand on ajoute le site à l'écran d'accueil iOS

### 3. Créer OG Image (Réseaux Sociaux)

1. Créez une image 1200x630px avec :
   - Logo Ryse
   - Texte : "Coach Nutrition & Fitness IA"
   - Visuel de l'app
2. Nommez-la `og-image.jpg`
3. Uploadez dans `/public_html/assets/images/`

### 4. Google Analytics (Optionnel)

1. Créez un compte Google Analytics 4
2. Obtenez votre ID de mesure (G-XXXXXXXXXX)
3. Ajoutez le code avant `</head>` dans tous les HTML :

```html
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

### 5. Google Search Console

1. Allez sur [search.google.com/search-console](https://search.google.com/search-console)
2. Ajoutez `coach-ryze.com`
3. Méthode de validation : **HTML tag** (ajoutez dans `<head>`)
4. Soumettez le sitemap : `https://coach-ryze.com/sitemap.xml`

---

## 🐛 Dépannage

### Problème : Site ne s'affiche pas

**Solution** :
1. Vérifiez DNS propagation : [dnschecker.org](https://dnschecker.org)
2. Videz le cache navigateur (Cmd+Shift+R sur Mac)
3. Vérifiez que `index.html` est bien à la racine de `/public_html/`
4. Consultez les error logs GoDaddy (cPanel → Error Log)

### Problème : CSS/JS ne charge pas

**Solution** :
1. Vérifiez les chemins dans HTML (doivent être relatifs : `assets/css/style.css`)
2. Vérifiez permissions fichiers (644)
3. Hard refresh : Cmd+Shift+R (Mac) ou Ctrl+Shift+R (Windows)
4. Ouvrez DevTools (F12) → Console pour voir les erreurs

### Problème : Certificat SSL invalide

**Solution** :
1. Attendez 5-10 minutes après installation SSL
2. Videz le cache SSL navigateur
3. Réinstallez le certificat SSL dans cPanel
4. Contactez support GoDaddy si persiste

### Problème : Emails non reçus

**Solution** :
1. Vérifiez que le compte email est bien créé dans GoDaddy
2. Vérifiez les paramètres serveur (IMAP/SMTP)
3. Regardez dans le dossier Spam
4. Testez avec un autre client email

### Problème : Redirection HTTPS ne fonctionne pas

**Solution** :
1. Vérifiez que `.htaccess` est bien uploadé dans `/public_html/`
2. Vérifiez que le fichier commence bien par un point : `.htaccess`
3. Dans cPanel, vérifiez que mod_rewrite est activé
4. Testez manuellement : `http://coach-ryze.com` → doit aller vers `https://`

---

## 📞 Support

### Support GoDaddy
- **Téléphone France** : +33 (0)1 70 70 17 17
- **Chat** : Via votre compte GoDaddy
- **Email** : support@godaddy.com
- **Disponibilité** : 24/7

### Ressources
- [Guide GoDaddy cPanel](https://www.godaddy.com/help/cpanel-1)
- [Guide SSL GoDaddy](https://www.godaddy.com/help/install-ssl-certificates-16623)
- [DNS GoDaddy](https://www.godaddy.com/help/dns-management-19858)

---

## ✨ Checklist Finale

- [ ] Site accessible via `https://coach-ryze.com`
- [ ] Toutes les pages fonctionnent (index, support, privacy, terms)
- [ ] HTTPS activé (cadenas vert)
- [ ] Navigation mobile fonctionne
- [ ] Emails configurés et testés
- [ ] Google Search Console configuré
- [ ] Sitemap soumis
- [ ] Performance > 90/100 (PageSpeed)
- [ ] SSL note A+ (SSL Labs)
- [ ] Screenshots réels ajoutés (si disponibles)

---

**🎉 Félicitations ! Votre site est en ligne !**

**Liens pour App Store** :
- Support URL : `https://coach-ryze.com/support.html`
- Marketing URL : `https://coach-ryze.com`
- Privacy Policy : `https://coach-ryze.com/privacy.html`

---

**Créé le** : 9 novembre 2025
**Version** : 1.0
**Temps total estimé** : 1-2 heures (incluant propagation DNS)
