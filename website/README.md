# Site Web Ryse - coach-ryze.com

Site web officiel de l'application Ryse - Coach Nutrition & Fitness propulsé par l'IA.

## 📁 Structure du Projet

```
website/
├── index.html              # Page d'accueil / Landing page
├── privacy.html            # Politique de confidentialité (RGPD)
├── terms.html              # Conditions générales d'utilisation
├── support.html            # Centre d'aide & FAQ
├── assets/
│   ├── css/
│   │   └── style.css       # Feuille de style principale
│   ├── js/
│   │   └── main.js         # JavaScript interactif
│   └── images/             # Images et screenshots
└── README.md               # Ce fichier
```

## 🎨 Design System

Le site utilise la même direction artistique que l'application Flutter :

### Couleurs Principales
- **Primary Dark**: `#0B132B` (bleu très foncé)
- **Primary Medium**: `#1C2951` (bleu moyen)
- **Accent Blue**: `#3B82F6`
- **Accent Green**: `#10B981`
- **Accent Orange**: `#F59E0B`

### Typographie
- **Font**: Inter (Google Fonts)
- **Poids**: 400, 500, 600, 700, 800, 900

### Composants
- Navigation fixe avec backdrop blur
- Hero section avec gradient
- Feature cards avec hover effects
- Footer complet
- Responsive mobile-first

## 🚀 Déploiement sur GoDaddy

### Option 1: Upload FTP Manuel

1. **Connexion FTP** :
   - Ouvrir FileZilla ou tout client FTP
   - Hôte: `ftp.coach-ryze.com` (ou IP fournie par GoDaddy)
   - Utilisateur: Votre username GoDaddy
   - Mot de passe: Votre password GoDaddy
   - Port: 21

2. **Upload des fichiers** :
   ```
   Dossier local: /Users/badis/Documents/Ryse-app-new/website/
   Dossier distant: /public_html/ (ou /htdocs/ selon config)
   ```

3. **Structure sur le serveur** :
   ```
   public_html/
   ├── index.html
   ├── privacy.html
   ├── terms.html
   ├── support.html
   └── assets/
       ├── css/
       ├── js/
       └── images/
   ```

### Option 2: File Manager GoDaddy (via navigateur)

1. Connexion à GoDaddy → Mon compte
2. Produits → cPanel → File Manager
3. Naviguer vers `/public_html/`
4. Upload tous les fichiers du dossier `website/`
5. Vérifier les permissions (644 pour fichiers, 755 pour dossiers)

### Option 3: Git Deployment (Recommandé)

```bash
# Dans le terminal local
cd /Users/badis/Documents/Ryse-app-new/website

# Initialiser git (si pas déjà fait)
git init
git add .
git commit -m "Initial website version"

# Connecter au serveur GoDaddy via SSH (si disponible)
# Configurer Git hooks pour auto-deploy
```

## 🔧 Configuration DNS

Assurez-vous que votre domaine pointe vers votre hébergement :

```
Type A Record:
coach-ryze.com → [IP de votre serveur GoDaddy]
www.coach-ryze.com → [IP de votre serveur GoDaddy]
```

**Propagation DNS** : Peut prendre 24-48h

## ✅ Checklist Avant Mise en Production

### Contenu
- [ ] Remplacer les SVG placeholders par de vraies screenshots
- [ ] Ajouter le logo Ryse en SVG dans `assets/images/`
- [ ] Créer favicon.svg et apple-touch-icon.png
- [ ] Ajouter og-image.jpg (1200x630px) pour réseaux sociaux
- [ ] Mettre à jour les liens App Store (remplacer `#`)

### SEO & Performance
- [ ] Vérifier tous les meta tags
- [ ] Optimiser les images (compression, WebP)
- [ ] Ajouter sitemap.xml
- [ ] Ajouter robots.txt
- [ ] Configurer HTTPS (SSL/TLS)
- [ ] Test vitesse Google PageSpeed Insights

### Fonctionnel
- [ ] Tester formulaire de contact
- [ ] Vérifier tous les liens internes
- [ ] Tester responsive sur mobile/tablet
- [ ] Vérifier compatibilité navigateurs (Chrome, Safari, Firefox)
- [ ] Tester navigation mobile (hamburger menu)

### Légal
- [ ] Vérifier emails de contact (`support@coach-ryze.com`, etc.)
- [ ] Configurer redirections emails GoDaddy
- [ ] Mettre à jour dates dans privacy.html et terms.html
- [ ] Ajouter mention CNIL si applicable

## 📧 Configuration Email

Pour configurer les emails professionnels (`support@coach-ryze.com`, etc.) :

1. GoDaddy → Email & Office → Workspace Email
2. Créer les adresses :
   - `support@coach-ryze.com`
   - `privacy@coach-ryze.com`
   - `legal@coach-ryze.com`
   - `dpo@coach-ryze.com`
3. Configurer redirections si besoin

## 🔒 HTTPS / SSL

**IMPORTANT** : Activer HTTPS pour sécurité et SEO

1. GoDaddy cPanel → SSL/TLS
2. Installer certificat SSL (Let's Encrypt gratuit)
3. Forcer HTTPS via `.htaccess` :

```apache
# Redirection HTTP → HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Redirection www → non-www (optionnel)
RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]
RewriteRule ^(.*)$ https://%1/$1 [R=301,L]
```

## 📊 Analytics (Optionnel)

### Google Analytics 4

Ajouter avant `</head>` dans toutes les pages HTML :

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

### Plausible Analytics (Alternative privacy-friendly)

```html
<script defer data-domain="coach-ryze.com" src="https://plausible.io/js/script.js"></script>
```

## 🎯 SEO Avancé

### Sitemap.xml

Créer `sitemap.xml` à la racine :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://coach-ryze.com/</loc>
    <lastmod>2025-11-09</lastmod>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://coach-ryze.com/privacy.html</loc>
    <lastmod>2025-11-09</lastmod>
    <priority>0.5</priority>
  </url>
  <url>
    <loc>https://coach-ryze.com/terms.html</loc>
    <lastmod>2025-11-09</lastmod>
    <priority>0.5</priority>
  </url>
  <url>
    <loc>https://coach-ryze.com/support.html</loc>
    <lastmod>2025-11-09</lastmod>
    <priority>0.8</priority>
  </url>
</urlset>
```

### Robots.txt

Créer `robots.txt` à la racine :

```
User-agent: *
Allow: /
Sitemap: https://coach-ryze.com/sitemap.xml
```

## 📱 Screenshots à Ajouter

Remplacer les SVG placeholders dans `index.html` par de vraies captures d'écran :

### Screenshots requis :
1. **Dashboard Principal** (1242x2688px)
2. **Scanner IA** (repas en cours d'analyse)
3. **Cardio GPS** (carte avec parcours)
4. **Workout Session** (musculation en cours)
5. **Widget iOS** (home screen + lock screen)
6. **Progression** (graphiques)

**Format** : PNG optimisés (compression TinyPNG)
**Localisation** : `assets/images/screenshots/`

## 🌐 Internationalisation (Future)

Pour ajouter version anglaise :

```
website/
├── index.html (FR)
├── en/
│   ├── index.html (EN)
│   ├── privacy.html
│   ├── terms.html
│   └── support.html
```

Ajouter language switcher dans navbar.

## 🔍 Tests Recommandés

### Performance
- Google PageSpeed Insights
- GTmetrix
- WebPageTest

### SEO
- Google Search Console
- Ahrefs Site Audit
- Screaming Frog

### Responsive
- BrowserStack
- Responsive Design Checker
- Real devices (iPhone, iPad, Android)

### Accessibilité
- WAVE Web Accessibility Evaluation Tool
- Lighthouse (Chrome DevTools)
- axe DevTools

## 🐛 Débogage

### Site ne s'affiche pas
1. Vérifier DNS propagation : https://dnschecker.org
2. Vérifier index.html est à la racine de `/public_html/`
3. Vérifier permissions fichiers (644) et dossiers (755)
4. Check error logs GoDaddy cPanel

### CSS/JS ne charge pas
1. Vérifier chemins relatifs dans HTML
2. Vérifier CORS headers
3. Hard refresh navigateur (Cmd+Shift+R)
4. Check console navigateur (F12)

## 📞 Support GoDaddy

- **Téléphone** : +33 (0)1 70 70 17 17
- **Chat** : Via compte GoDaddy
- **Email** : support@godaddy.com

## 🚀 Mise à Jour du Site

```bash
# Après modifications locales
cd /Users/badis/Documents/Ryse-app-new/website

# Upload via FTP
# OU
# Utiliser File Manager GoDaddy
```

## 📝 Notes Importantes

- **RGPD Compliance** : Privacy policy et terms sont conformes RGPD
- **App Store Requirements** : Privacy policy URL requise pour soumission App Store
- **Performance** : Site optimisé pour mobile-first (important pour App Store)
- **Sécurité** : Tous les formulaires utilisent HTTPS

## 🎉 Prochaines Étapes

1. Upload fichiers sur GoDaddy
2. Configurer DNS
3. Activer SSL/HTTPS
4. Ajouter vraies screenshots
5. Configurer emails professionnels
6. Tester sur différents devices
7. Soumettre sitemap à Google Search Console
8. Lancer campagne SEO/Marketing

---

**Créé le** : 9 novembre 2025
**Version** : 1.0
**Auteur** : Claude Code pour Ryse App
