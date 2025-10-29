# Configuration de l'authentification Google et Apple - Ryse App

## ✅ Ce qui a été fait automatiquement

1. ✅ Ajout de la capacité Apple Sign-In dans `ios/Runner/Runner.entitlements`
2. ✅ Ajout de la structure Google Sign-In dans `ios/Runner/Info.plist`
3. ✅ Configuration du plugin Google Services dans `android/build.gradle.kts`
4. ✅ Application du plugin Google Services dans `android/app/build.gradle.kts`
5. ✅ Création du dossier `assets/icons/` pour les icônes

---

## 🔧 CE QUE VOUS DEVEZ FAIRE MAINTENANT

### 1️⃣ Configuration Google Cloud Console

#### A. Créer/Configurer le projet Google Cloud

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet ou sélectionnez le projet existant "Ryse App"
3. Activez **Google Sign-In API** :
   - Menu hamburger → APIs & Services → Library
   - Recherchez "Google Sign-In API"
   - Cliquez sur "Enable"

#### B. Créer les credentials OAuth 2.0

**Pour iOS :**
1. APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID
2. Type : **iOS**
3. Name : `Ryse App iOS`
4. Bundle ID : `com.example.ryze_app` (ou votre bundle ID réel)
5. Cliquez sur **Create**
6. **Notez le Client ID généré** (format : `123456789-abc.apps.googleusercontent.com`)

**Pour Android :**
1. D'abord, obtenez votre SHA-1 fingerprint :
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copiez le SHA-1 affiché (quelque chose comme `12:34:56:78:90:AB:CD:...`)

2. Retournez dans Google Cloud Console
3. Create Credentials → OAuth 2.0 Client ID
4. Type : **Android**
5. Name : `Ryse App Android`
6. Package name : `com.example.ryze_app`
7. **SHA-1 certificate fingerprint** : Collez le SHA-1 copié
8. Cliquez sur **Create**

**Pour Supabase (Web) :**
1. Create Credentials → OAuth 2.0 Client ID
2. Type : **Web application**
3. Name : `Ryse App Web (Supabase)`
4. Authorized redirect URIs : `https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback`
   - Remplacez `YOUR-PROJECT-REF` par votre référence de projet Supabase
5. Cliquez sur **Create**
6. **Notez le Client ID et Client Secret**

---

### 2️⃣ Mettre à jour le fichier iOS Info.plist

Ouvrez `ios/Runner/Info.plist` et remplacez les placeholders :

**Ligne 106** : Remplacez `YOUR-CLIENT-ID` par votre Client ID iOS
```xml
<string>com.googleusercontent.apps.123456789-abc</string>
```

**Ligne 112** : Remplacez `YOUR-CLIENT-ID` par votre Client ID iOS complet
```xml
<string>123456789-abc.apps.googleusercontent.com</string>
```

> **Note** : Pour la ligne 106, inversez le Client ID (reversed client ID).
> Si votre Client ID est `123456789-abc.apps.googleusercontent.com`,
> le reversed client ID est `com.googleusercontent.apps.123456789-abc`

---

### 3️⃣ Configuration Apple Sign-In

#### A. Apple Developer Portal

1. Allez sur [Apple Developer](https://developer.apple.com/account)
2. Certificates, Identifiers & Profiles → **Identifiers**
3. Sélectionnez votre App ID (ou créez-en un)
4. Cochez **Sign in with Apple**
5. Cliquez sur **Save**

#### B. Dans Xcode (IMPORTANT)

1. Ouvrez `ios/Runner.xcodeproj` dans Xcode
2. Sélectionnez le projet **Runner** dans le navigateur
3. Onglet **Signing & Capabilities**
4. Cliquez sur **+ Capability**
5. Ajoutez **Sign in with Apple**
6. Assurez-vous que votre équipe de développement est sélectionnée

---

### 4️⃣ Télécharger les fichiers de configuration Google

#### Pour iOS :
1. Dans Google Cloud Console, allez dans le projet
2. Téléchargez `GoogleService-Info.plist`
3. Placez-le dans `ios/Runner/GoogleService-Info.plist`
4. Dans Xcode, faites glisser le fichier dans le dossier Runner (cochez "Copy items if needed")

#### Pour Android :
1. Dans Google Cloud Console, téléchargez `google-services.json`
2. Placez-le dans `android/app/google-services.json`

---

### 5️⃣ Configuration Supabase

1. Allez dans votre dashboard [Supabase](https://app.supabase.com)
2. Sélectionnez votre projet Ryse App
3. Menu de gauche → **Authentication** → **Providers**

#### Activer Google :
1. Cliquez sur **Google**
2. Activez "Enable Sign in with Google"
3. **Client ID (for Web)** : Collez le Client ID Web créé plus tôt
4. **Client Secret** : Collez le Client Secret Web
5. Cliquez sur **Save**

#### Activer Apple :
1. Cliquez sur **Apple**
2. Activez "Enable Sign in with Apple"
3. Vous aurez besoin de :
   - **Services ID** (créé dans Apple Developer Portal)
   - **Team ID** (trouvé dans Apple Developer → Membership)
   - **Key ID** (de la clé .p8 créée)
   - **Private Key** (contenu du fichier .p8)

**Pour créer la clé Apple :**
1. Apple Developer → Keys
2. Cliquez sur le bouton **+**
3. Name : `Ryse App Sign in with Apple Key`
4. Cochez **Sign in with Apple**
5. Cliquez sur **Continue** puis **Register**
6. Téléchargez le fichier `.p8` (vous ne pourrez le télécharger qu'une fois !)
7. Notez le **Key ID**

4. Collez toutes ces informations dans Supabase
5. Cliquez sur **Save**

---

### 6️⃣ Ajouter les icônes Google et Apple (Optionnel)

Les boutons utilisent actuellement des icônes Material par défaut. Pour de vraies icônes :

1. Téléchargez les icônes :
   - Google : [Icône officielle Google](https://developers.google.com/identity/branding-guidelines)
   - Apple : [Icône officielle Apple](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple)

2. Placez-les dans :
   ```
   assets/icons/google.png
   assets/icons/apple.png
   ```

3. Mettez à jour `lib/widgets/social_login_button.dart` pour utiliser `Image.asset(icon)` au lieu des Icons

---

## 🧪 Tester l'implémentation

### iOS
```bash
flutter clean
flutter pub get
cd ios
pod install
pod update
cd ..
flutter run -d ios
```

### Android
```bash
flutter clean
flutter pub get
flutter run -d android
```

---

## ⚠️ Troubleshooting

### Erreur "PlatformException" sur Android
- Vérifiez que le SHA-1 dans Google Cloud Console correspond bien à celui de `./gradlew signingReport`
- Vérifiez que `google-services.json` est bien dans `android/app/`

### Erreur "GoogleSignIn not configured" sur iOS
- Vérifiez que `GoogleService-Info.plist` est dans Xcode
- Vérifiez que les Client IDs dans `Info.plist` sont corrects
- Vérifiez que le reversed client ID est bien inversé

### Apple Sign-In ne fonctionne pas
- Vérifiez que la capability est activée dans Xcode
- Vérifiez que l'App ID a Sign in with Apple activé sur le portail Apple
- Apple Sign-In ne fonctionne que sur des appareils réels, pas sur simulateur (pour certaines versions iOS)

### Erreur Supabase "Invalid login credentials"
- Vérifiez que les providers sont bien activés dans Supabase
- Vérifiez que les Client IDs/Secrets sont corrects
- Vérifiez que l'URL de redirection est correcte

---

## 📚 Ressources utiles

- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Sign in with Apple Flutter](https://pub.dev/packages/sign_in_with_apple)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Apple Developer Portal](https://developer.apple.com/account)

---

## ✅ Checklist finale

Avant de tester, assurez-vous que :

- [ ] Client IDs Google créés (iOS, Android, Web)
- [ ] SHA-1 ajouté dans Google Cloud Console pour Android
- [ ] `GoogleService-Info.plist` dans `ios/Runner/`
- [ ] `google-services.json` dans `android/app/`
- [ ] Info.plist mis à jour avec les vrais Client IDs
- [ ] Capability "Sign in with Apple" ajoutée dans Xcode
- [ ] Providers Google et Apple activés dans Supabase
- [ ] Clean + pub get + pod install effectués

Bonne chance ! 🚀
