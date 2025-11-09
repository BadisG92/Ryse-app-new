# 🚀 Quick Start - Déploiement Rapide

**Temps total : 30 minutes** ⏱️

---

## 📦 Étape 1 : Créer le ZIP (2 min)

```bash
cd /Users/badis/Documents/Ryse-app-new
zip -r website.zip website/ -x "*.DS_Store" "*.git*"
```

Votre fichier `website.zip` est prêt !

---

## 🌐 Étape 2 : Upload sur GoDaddy (10 min)

### Via File Manager (Facile)

1. Allez sur [godaddy.com](https://godaddy.com) → **Sign In**
2. **My Products** → **Web Hosting** → **Manage**
3. Cliquez **cPanel Admin**
4. **File Manager** (section Files)
5. Naviguez vers `/public_html/`
6. **Supprimez** tous les anciens fichiers
7. Cliquez **Upload**
8. Glissez `website.zip`
9. Clic-droit sur ZIP → **Extract** → `/public_html/`
10. Supprimez le ZIP

✅ **Fait !**

---

## 🔒 Étape 3 : Activer SSL (5 min)

1. Dans cPanel → **SSL/TLS Status**
2. Cherchez `coach-ryze.com`
3. Cliquez **Run AutoSSL**
4. Attendez 2-5 minutes
5. Testez : `https://coach-ryze.com` (cadenas vert ✅)

---

## 📧 Étape 4 : Emails (10 min)

1. GoDaddy → **Email & Office** → **Workspace Email**
2. Achetez un plan (~5€/mois)
3. Créez :
   - `support@coach-ryze.com` ✅ REQUIS App Store
   - `privacy@coach-ryze.com`
   - `legal@coach-ryze.com`
4. Envoyez un test → vérifiez réception

---

## ✅ Étape 5 : Vérifications (3 min)

### Tests Rapides

- [ ] `https://coach-ryze.com` → Page d'accueil OK
- [ ] `https://coach-ryze.com/support.html` → FAQ OK
- [ ] `https://coach-ryze.com/privacy.html` → Privacy OK
- [ ] `https://coach-ryze.com/terms.html` → Terms OK
- [ ] Cadenas vert HTTPS visible
- [ ] Menu mobile fonctionne
- [ ] Email test reçu

### URLs pour App Store

Copiez ces URLs dans App Store Connect :

```
Support URL:
https://coach-ryze.com/support.html

Marketing URL:
https://coach-ryze.com

Privacy Policy URL:
https://coach-ryze.com/privacy.html

Email Support:
support@coach-ryze.com
```

---

## 🎉 C'EST FAIT !

Votre site est en ligne ! 🚀

### Prochaines étapes (optionnel)

1. 📸 Ajouter screenshots réels app
2. 📊 Installer Google Analytics
3. 🔍 Soumettre sitemap Google Search Console
4. 🎨 Créer Apple Touch Icon (180x180)
5. 📱 Créer OG Image réseaux sociaux (1200x630)

---

## 🐛 Problème ?

### Site ne s'affiche pas
- Vérifiez DNS : [dnschecker.org](https://dnschecker.org)
- Attendez 24-48h propagation DNS
- Videz cache : Cmd+Shift+R

### HTTPS ne marche pas
- Attendez 5-10 min après install SSL
- Réinstallez certificat SSL

### CSS cassé
- Vérifiez structure : `/public_html/assets/css/style.css`
- Hard refresh : Cmd+Shift+R

---

## 📚 Documentation Complète

Pour plus de détails, consultez :

- 📖 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Guide détaillé
- ✅ [CHECKLIST.md](CHECKLIST.md) - 120 points de vérification
- 📋 [FINAL_SUMMARY.md](FINAL_SUMMARY.md) - Résumé complet

---

**Support GoDaddy** : +33 (0)1 70 70 17 17

✨ **Bon lancement !** ✨
