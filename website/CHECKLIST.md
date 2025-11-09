# ✅ Checklist Complète - Déploiement coach-ryze.com

Utilisez cette checklist pour vous assurer que tout est prêt avant et après le déploiement.

---

## 📦 1. Préparation des Fichiers

### Fichiers HTML
- [x] `index.html` - Landing page créée
- [x] `privacy.html` - Politique de confidentialité (RGPD compliant)
- [x] `terms.html` - Conditions d'utilisation
- [x] `support.html` - Centre d'aide avec FAQ
- [x] `404.html` - Page d'erreur personnalisée

### Fichiers Techniques
- [x] `sitemap.xml` - Plan du site pour SEO
- [x] `robots.txt` - Instructions pour crawlers
- [x] `.htaccess` - Configuration Apache (HTTPS, sécurité)

### Assets
- [x] `assets/css/style.css` - Feuille de style complète
- [x] `assets/js/main.js` - JavaScript interactif
- [x] `assets/images/favicon.svg` - Favicon SVG

### Screenshots (À AJOUTER)
- [ ] `assets/images/screenshots/dashboard.png`
- [ ] `assets/images/screenshots/scanner.png`
- [ ] `assets/images/screenshots/cardio.png`
- [ ] `assets/images/screenshots/workout.png`
- [ ] `assets/images/screenshots/widget.png`
- [ ] `assets/images/apple-touch-icon.png` (180x180)
- [ ] `assets/images/og-image.jpg` (1200x630)

---

## 🚀 2. Déploiement

### Upload sur GoDaddy
- [ ] Connexion GoDaddy réussie
- [ ] Accès au cPanel obtenu
- [ ] Ancien contenu de `/public_html/` supprimé (si existant)
- [ ] Tous les fichiers uploadés via File Manager OU FTP
- [ ] Structure du site vérifiée :
  ```
  public_html/
  ├── index.html
  ├── privacy.html
  ├── terms.html
  ├── support.html
  ├── 404.html
  ├── sitemap.xml
  ├── robots.txt
  ├── .htaccess
  └── assets/
  ```
- [ ] Permissions fichiers : `644`
- [ ] Permissions dossiers : `755`

---

## 🌐 3. Configuration DNS

- [ ] DNS A Record : `@` → IP hébergement
- [ ] DNS A Record : `www` → IP hébergement
- [ ] Propagation DNS vérifiée sur [dnschecker.org](https://dnschecker.org)
- [ ] Site accessible via `http://coach-ryze.com`
- [ ] Site accessible via `http://www.coach-ryze.com`

---

## 🔒 4. SSL/HTTPS

- [ ] Certificat SSL installé (AutoSSL ou Let's Encrypt)
- [ ] Site accessible via `https://coach-ryze.com`
- [ ] Cadenas vert visible dans la barre d'adresse
- [ ] Redirection HTTP → HTTPS fonctionnelle
- [ ] Redirection www → non-www fonctionnelle (optionnel)
- [ ] Note SSL Labs : A ou A+ ([ssllabs.com/ssltest](https://www.ssllabs.com/ssltest/))

---

## 📧 5. Configuration Emails

- [ ] Adresses email créées :
  - [ ] `support@coach-ryze.com` (REQUIS App Store)
  - [ ] `privacy@coach-ryze.com`
  - [ ] `legal@coach-ryze.com`
  - [ ] `dpo@coach-ryze.com`
  - [ ] `contact@coach-ryze.com`
- [ ] Email de test envoyé et reçu
- [ ] Configuration email sur iPhone/Mac réussie
- [ ] Redirections email configurées (si applicable)

---

## ✅ 6. Tests Fonctionnels

### Navigation
- [ ] Page d'accueil s'affiche correctement
- [ ] Tous les liens de navigation fonctionnent
- [ ] Menu mobile hamburger fonctionne
- [ ] Smooth scrolling fonctionne sur ancres (#features, #download, etc.)

### Pages
- [ ] `https://coach-ryze.com/` - Landing page OK
- [ ] `https://coach-ryze.com/support.html` - FAQ interactive OK
- [ ] `https://coach-ryze.com/privacy.html` - Policy affichée
- [ ] `https://coach-ryze.com/terms.html` - Terms affichés
- [ ] `https://coach-ryze.com/404.html` - Page erreur OK

### Fichiers Techniques
- [ ] `https://coach-ryze.com/robots.txt` accessible
- [ ] `https://coach-ryze.com/sitemap.xml` accessible et valide
- [ ] `.htaccess` active (HTTPS redirect fonctionne)

### Responsive
- [ ] iPhone SE (375px) - Affichage correct
- [ ] iPhone 14 Pro (393px) - Affichage correct
- [ ] iPad (768px) - Affichage correct
- [ ] Desktop (1920px) - Affichage correct
- [ ] Menu mobile fonctionne sur petit écran
- [ ] Pas de scroll horizontal sur mobile

---

## 🎨 7. Design & UX

- [ ] Police Inter charge correctement
- [ ] Couleurs app respectées (#0B132B, #1C2951)
- [ ] Animations fonctionnent (fade-in, hover, float)
- [ ] Boutons CTA cliquables et visuels
- [ ] Footer complet et lisible
- [ ] Pas d'erreurs de layout

---

## 📊 8. Performance & SEO

### Performance
- [ ] Test PageSpeed Insights : [pagespeed.web.dev](https://pagespeed.web.dev/)
  - [ ] Score Mobile > 90
  - [ ] Score Desktop > 90
- [ ] Images optimisées (compression TinyPNG si screenshots ajoutés)
- [ ] CSS minifié (optionnel pour v1)
- [ ] JS minifié (optionnel pour v1)

### SEO
- [ ] Meta title présent sur toutes les pages
- [ ] Meta description présente sur toutes les pages
- [ ] Meta keywords présents (optionnel)
- [ ] Open Graph tags présents (Facebook/LinkedIn)
- [ ] Twitter Card tags présents
- [ ] H1 unique sur chaque page
- [ ] Structure H1-H6 logique
- [ ] Alt text sur toutes les images importantes

---

## 🔍 9. Google Search Console

- [ ] Propriété `coach-ryze.com` ajoutée
- [ ] Validation domaine réussie (HTML tag ou DNS)
- [ ] Sitemap soumis : `https://coach-ryze.com/sitemap.xml`
- [ ] Première indexation demandée pour pages principales
- [ ] Aucune erreur critique détectée

---

## 📈 10. Analytics (Optionnel)

- [ ] Google Analytics 4 configuré
- [ ] Code GA installé avant `</head>`
- [ ] Événements de base trackés (clics CTA)
- [ ] Dashboard GA accessible

---

## 🛡️ 11. Sécurité

- [ ] Headers de sécurité activés (dans .htaccess)
  - [ ] X-Frame-Options
  - [ ] X-XSS-Protection
  - [ ] X-Content-Type-Options
  - [ ] Strict-Transport-Security (HSTS)
- [ ] Pas de fichiers sensibles exposés (README, .git, etc.)
- [ ] Permissions fichiers correctes (644/755)
- [ ] Pas d'erreurs dans error_log

---

## 📱 12. App Store Requirements

- [ ] URL Support : `https://coach-ryze.com/support.html` ✅
- [ ] URL Marketing : `https://coach-ryze.com` ✅
- [ ] Privacy Policy URL : `https://coach-ryze.com/privacy.html` ✅
- [ ] Terms URL : `https://coach-ryze.com/terms.html` ✅
- [ ] Email support : `support@coach-ryze.com` ✅
- [ ] Privacy Policy conforme RGPD ✅
- [ ] Mention des API tierces (Gemini, Vision, OpenFoodFacts) ✅

---

## 🎁 13. Optimisations Bonus

- [ ] Apple Touch Icon (180x180) créé et uploadé
- [ ] OG Image (1200x630) créé pour réseaux sociaux
- [ ] Favicon multi-tailles générées (16x16, 32x32, etc.)
- [ ] Page 404 personnalisée configurée dans cPanel
- [ ] Compression Gzip activée (vérifié dans .htaccess)
- [ ] Browser caching configuré (vérifié dans .htaccess)

---

## 📧 14. Communication Post-Lancement

- [ ] Email de notification aux bêta-testeurs (si applicable)
- [ ] Post Instagram : "Le site est en ligne !"
- [ ] Post Twitter/X : Annonce avec lien
- [ ] Story Instagram avec QR code vers le site
- [ ] Mise à jour bio Instagram : lien vers coach-ryze.com

---

## 🔄 15. Maintenance Future

- [ ] Calendrier de vérifications mensuelles créé
- [ ] Renouvellement SSL automatique activé
- [ ] Backup automatique configuré (GoDaddy)
- [ ] Monitoring uptime activé (UptimeRobot gratuit)
- [ ] Liste de tâches V2 créée (nouvelles features site)

---

## 🚨 Troubleshooting Rapide

### Site ne s'affiche pas
1. ✅ Vérifier DNS : [dnschecker.org](https://dnschecker.org)
2. ✅ Vérifier structure : `index.html` dans `/public_html/`
3. ✅ Vider cache navigateur : Cmd+Shift+R

### HTTPS ne fonctionne pas
1. ✅ Attendre 5-10 min après install SSL
2. ✅ Vérifier `.htaccess` bien uploadé
3. ✅ Réinstaller certificat SSL

### CSS/JS ne charge pas
1. ✅ Vérifier chemins relatifs (`assets/css/style.css`)
2. ✅ Vérifier permissions : 644
3. ✅ Hard refresh : Cmd+Shift+R

---

## 🎉 Score Final

**Total des tâches complétées** : _____ / 120

- **90-120** : 🌟 Excellent ! Site prêt pour production
- **70-89** : ✅ Bon ! Quelques optimisations à faire
- **50-69** : ⚠️ Fonctionnel mais améliorations nécessaires
- **< 50** : ❌ Problèmes critiques à résoudre

---

## 📞 Support & Ressources

- **GoDaddy Support** : +33 (0)1 70 70 17 17
- **Guide déploiement** : `DEPLOYMENT_GUIDE.md`
- **Documentation** : `README.md`

---

**Date de complétion** : _______________
**Déployé par** : _______________
**Version du site** : 1.0
**Temps total** : _______________

---

✨ **Félicitations pour votre lancement !** ✨
