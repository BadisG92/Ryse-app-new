# 📱 Checklist App Store - Ryze App

## ✅ **Permissions & Configurations iOS**

### **Info.plist configuré avec :**
- ✅ `NSLocationWhenInUseUsageDescription` - Géolocalisation pendant usage
- ✅ `NSLocationAlwaysAndWhenInUseUsageDescription` - Géolocalisation background
- ✅ `NSMotionUsageDescription` - Capteurs mouvement/pas
- ✅ `NSHealthShareUsageDescription` - Lecture données Santé
- ✅ `NSHealthUpdateUsageDescription` - Écriture données Santé
- ✅ `NSUserTrackingUsageDescription` - iOS 14.5+ privacy
- ✅ `UIBackgroundModes` - location + background-processing
- ✅ `UIRequiredDeviceCapabilities` - GPS + accelerometer
- ✅ `NSAppTransportSecurity` - Sécurité réseau

### **Entitlements configurés :**
- ✅ `com.apple.developer.healthkit` - HealthKit
- ✅ `com.apple.developer.location.services` - Location
- ✅ `com.apple.developer.location.background` - Background location

## 🎯 **Fonctionnalités GPS conformes Apple**

### **Utilisation légitime du GPS :**
- ✅ **Fitness tracking** - Course, vélo, marche
- ✅ **Calcul distance/vitesse** en temps réel  
- ✅ **Calories basées sur effort réel** (METs + vitesse GPS)
- ✅ **Pas de tracking publicitaire** - uniquement fitness
- ✅ **Mode fallback** - App fonctionne sans GPS
- ✅ **Arrêt automatique** - GPS se coupe après séance

### **Interface utilisateur :**
- ✅ **Indicateur GPS visible** (GPS/SIMU)
- ✅ **Demande permission explicite** avec dialog informatif
- ✅ **Bouton réactivation GPS** si refusé
- ✅ **Usage clairement justifié** à l'utilisateur

## 📋 **Actions requises avant soumission**

### **1. Dans Xcode :**
```bash
# Ouvrir le projet
open ios/Runner.xcworkspace

# Configurer dans Xcode:
# - Signing & Capabilities → Location
# - Signing & Capabilities → HealthKit  
# - Signing & Capabilities → Background Modes → Location updates
```

### **2. Tests obligatoires :**
- ✅ Test sur **iPhone physique** (GPS ne marche pas sur simulateur)
- ✅ Test **permissions accordées/refusées**
- ✅ Test **course/vélo/marche** avec vraies données GPS
- ✅ Vérifier **calculs calories** réalistes
- ✅ Test **background mode** (app en arrière-plan)

### **3. App Store Connect :**
- ✅ **Description claire** du suivi fitness GPS
- ✅ **Captures d'écran** montrant l'interface GPS
- ✅ **Justification permissions** dans les notes de review
- ✅ **Catégorie**: Health & Fitness
- ✅ **Âge minimum**: 4+ ou 9+ (fitness apps)

## 🚨 **Points d'attention Apple Review**

### **Permissions sensibles - Justifications :**

**Location (GPS) :**
> "L'app utilise le GPS uniquement pendant les séances de sport actives pour mesurer précisément la distance parcourue, la vitesse et calculer les calories brûlées. Pas de tracking publicitaire."

**HealthKit :**
> "Intégration optionnelle avec l'app Santé iOS pour synchroniser les séances d'entraînement. L'utilisateur peut refuser sans impact sur les fonctionnalités principales."

**Background Location :**
> "Le GPS continue en arrière-plan uniquement pendant une séance de sport active pour ne pas perdre le tracking si l'utilisateur change d'app. Se désactive automatiquement à la fin."

### **Screenshots requis :**
1. **Écran demande permission GPS** avec explication claire
2. **Interface tracking** avec indicateur GPS visible
3. **Résultats séance** avec données GPS (distance, vitesse)
4. **Settings GPS** pour montrer le contrôle utilisateur

## ✅ **Conformité GDPR/Privacy**

- ✅ **Données GPS non envoyées** sur serveurs tiers
- ✅ **Stockage local** ou serveur Supabase sécurisé
- ✅ **Pas de vente données** à des annonceurs
- ✅ **Contrôle utilisateur** - peut désactiver GPS
- ✅ **Transparent sur l'usage** dans l'interface

## 🎉 **Status: PRÊT POUR SOUMISSION APP STORE!**

Toutes les configurations Apple requises sont en place pour une app de fitness avec géolocalisation.