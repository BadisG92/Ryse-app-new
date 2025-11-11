# 🐛 Guide de Debug - Popup de Célébration

## Comment Débugger le Problème

### 1. Teste l'ajout manuel
1. Ouvre l'app
2. Va sur le dashboard nutrition
3. Clique sur le bouton "Manuel"
4. Cherche un aliment (ex: "pomme")
5. Clique sur un aliment
6. Clique sur "Ajouter"

### 2. Regarde les logs dans la console Flutter

Tu devrais voir ces logs:
```
🎉 DEBUG - _addFoodToSelectedMeal called with: <nom aliment>
🎉 DEBUG - Bottom sheet closed
🎉 DEBUG - Scheduling popup in 300ms, mounted=true
🎉 DEBUG - Delayed callback, mounted=true, context=<context>
🎉 DEBUG - Calling CelebrationService.celebrateFoodEntry
🎊 CelebrationService.celebrateFoodEntry - START
   Context: <context>
   Message: <message aléatoire>
   Subtitle: <subtitle>
   Calling CelebrationPopup.show...
🎊 CelebrationService.celebrateFoodEntry - END
🎉 DEBUG - CelebrationService.celebrateFoodEntry returned
```

### 3. Scénarios possibles

#### ✅ Tous les logs apparaissent mais pas de popup
→ Problème dans CelebrationPopup.show() ou showDialog()

#### ⚠️ Logs s'arrêtent à "Scheduling popup"
→ Le callback Future.delayed n'est jamais exécuté
→ Possible que le widget soit dispose avant les 300ms

#### ❌ "Widget not mounted!"
→ Le widget NutritionJournalHybrid est dispose trop tôt
→ Besoin d'utiliser un GlobalKey ou Navigator.of(context, rootNavigator: true)

#### 🔴 Aucun log "🎉 DEBUG"
→ _addFoodToSelectedMeal n'est jamais appelé
→ Le flux manuel passe par un autre chemin

### 4. Solutions selon le problème

**Si widget not mounted**:
```dart
// Option 1: Utiliser rootNavigator
Future.delayed(const Duration(milliseconds: 300), () {
  CelebrationService().celebrateFoodEntry(
    Navigator.of(context, rootNavigator: true).context
  );
});

// Option 2: Sauvegarder le context
final savedContext = context;
Future.delayed(const Duration(milliseconds: 300), () {
  CelebrationService().celebrateFoodEntry(savedContext);
});
```

**Si callback non exécuté**:
```dart
// Réduire le délai
Future.delayed(const Duration(milliseconds: 100), () { ... });

// Ou appeler immédiatement
WidgetsBinding.instance.addPostFrameCallback((_) {
  CelebrationService().celebrateFoodEntry(context);
});
```

**Si showDialog ne fonctionne pas**:
```dart
// Utiliser rootNavigator
CelebrationPopup.show(
  Navigator.of(context, rootNavigator: true).context,
  ...
);
```

---

## Fichiers avec Logs de Debug

- `lib/components/nutrition_journal_hybrid.dart` (lignes 165, 184, 192, 195-201)
- `lib/services/celebration_service.dart` (lignes 190-211)

---

**Prochain pas**: Teste et envoie-moi les logs!
