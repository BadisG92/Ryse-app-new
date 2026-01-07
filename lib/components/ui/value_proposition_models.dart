/// Modèles de données pour les slides de value proposition

class ValuePropositionSlide {
  final int index;
  final String titleFr;
  final String titleEn;
  final String titleDe;

  ValuePropositionSlide({
    required this.index,
    required this.titleFr,
    required this.titleEn,
    required this.titleDe,
  });
}

/// Slide 1 : Méthodes d'input
class InputMethod {
  final String icon;
  final String labelFr;
  final String labelEn;
  final String labelDe;
  final String descriptionFr;
  final String descriptionEn;
  final String descriptionDe;

  InputMethod({
    required this.icon,
    required this.labelFr,
    required this.labelEn,
    required this.labelDe,
    required this.descriptionFr,
    required this.descriptionEn,
    required this.descriptionDe,
  });
}

class Slide1Data {
  static const String titleFr = "Suis ton alimentation comme tu veux";
  static const String titleEn = "Track how you want, when you want";
  static const String titleDe = "Verfolge deine Ernährung wie du willst";

  static const String coachNameFr = "Coach Ryze";
  static const String coachNameEn = "Coach Ryze";
  static const String coachNameDe = "Coach Ryze";

  static const String coachMessageFr = "Fais le suivi en 5 secondes, pas 10 minutes";
  static const String coachMessageEn = "Track your meals in 5 seconds, not 10 minutes";
  static const String coachMessageDe = "Tracke deine Mahlzeiten in 5 Sekunden, nicht 10 Minuten";

  static const String benefitFr = "Fini les recherches fastidieuses";
  static const String benefitEn = "No more tedious food database searches";
  static const String benefitDe = "Keine mühsamen Datenbanksuchen mehr";

  static final List<InputMethod> methods = [
    InputMethod(
      icon: "📸",
      labelFr: "Photo",
      labelEn: "Photo",
      labelDe: "Foto",
      descriptionFr: "Scanne ton assiette",
      descriptionEn: "Snap your plate",
      descriptionDe: "Scanne deinen Teller",
    ),
    InputMethod(
      icon: "🎤",
      labelFr: "Voix",
      labelEn: "Voice",
      labelDe: "Stimme",
      descriptionFr: "Dis ce que tu as mangé",
      descriptionEn: "Say what you ate",
      descriptionDe: "Sag was du gegessen hast",
    ),
    InputMethod(
      icon: "✏️",
      labelFr: "Texte",
      labelEn: "Text",
      labelDe: "Text",
      descriptionFr: "Écris ou cherche",
      descriptionEn: "Type or search",
      descriptionDe: "Tippe oder suche",
    ),
  ];
}

/// Slide 2 : Coach sur demande
class Slide2Data {
  static const String titleFr = "Ajuste ta nutrition en temps réel";
  static const String titleEn = "Adjust your nutrition in real-time";
  static const String titleDe = "Passe deine Ernährung in Echtzeit an";

  static const String coachMessageFr = "Je regarde ta journée et te propose la suite optimale";
  static const String coachMessageEn = "I review your day and suggest the optimal next steps";
  static const String coachMessageDe = "Ich schaue mir deinen Tag an und schlage die optimalen nächsten Schritte vor";

  static const String benefitFr = "Tu gardes toujours le contrôle de ta journée";
  static const String benefitEn = "You always stay in control of your day";
  static const String benefitDe = "Du behältst immer die Kontrolle über deinen Tag";

  static const String mockupCaloriesFr = "1200 / 2000 kcal";
  static const String mockupCaloriesEn = "1200 / 2000 kcal";
  static const String mockupCaloriesDe = "1200 / 2000 kcal";

  static const String mockupProteinsFr = "60g / 150g";
  static const String mockupProteinsEn = "60g / 150g";
  static const String mockupProteinsDe = "60g / 150g";

  static const String buttonTextFr = "Analyser ma journée";
  static const String buttonTextEn = "Analyze my day";
  static const String buttonTextDe = "Meinen Tag analysieren";

  // Exemples de réponses selon moment de la journée
  static const String coachResponseMorningFr = "Tu as encore 800 kcal. Pense à ajouter des protéines ce soir.";
  static const String coachResponseMorningEn = "You have 800 kcal left. Add protein tonight.";
  static const String coachResponseMorningDe = "Du hast noch 800 kcal übrig. Füge heute Abend Protein hinzu.";

  static const String coachResponsePostWorkoutFr = "Parfait pour la récup : 30g de protéines dans les 2h.";
  static const String coachResponsePostWorkoutEn = "Perfect for recovery: 30g protein within 2h.";
  static const String coachResponsePostWorkoutDe = "Perfekt für die Erholung: 30g Protein innerhalb von 2 Stunden.";

  static const String coachResponseEveningFr = "Bilan : 4/4 objectifs ! Bien joué, demain on ajuste.";
  static const String coachResponseEveningEn = "Summary: 4/4 goals! Well done, let's adjust tomorrow.";
  static const String coachResponseEveningDe = "Bilanz: 4/4 Ziele! Gut gemacht, morgen passen wir an.";

  static const List<String> featuresFr = [
    "Appuie pour analyser",
    "Conseils adaptés à ton moment",
    "Bilan personnalisé",
  ];

  static const List<String> featuresEn = [
    "Tap to analyze",
    "Context-aware advice",
    "Personalized insights",
  ];

  static const List<String> featuresDe = [
    "Tippe zum Analysieren",
    "Kontextbezogene Ratschläge",
    "Personalisierte Einblicke",
  ];
}

/// Slide 3 : Analyse sport
class Slide3Data {
  static const String titleFr = "Progresse plus vite avec un vrai plan";
  static const String titleEn = "Progress faster with a real plan";
  static const String titleDe = "Mache schneller Fortschritte mit einem echten Plan";

  static const String coachMessageFr = "Je te propose des séances personnalisées et j'analyse tes performances";
  static const String coachMessageEn = "I create personalized workouts and analyze your performance";
  static const String coachMessageDe = "Ich erstelle personalisierte Trainings und analysiere deine Leistung";

  static const String exerciseNameFr = "Squat";
  static const String exerciseNameEn = "Squat";
  static const String exerciseNameDe = "Kniebeuge";

  static const List<double> progressDataPoints = [60, 70, 80, 80];
  static const List<String> progressLabels = ["S1", "S2", "S3", "S4"];

  static const String buttonTextFr = "Analyser mes perfs";
  static const String buttonTextEn = "Analyze my performance";
  static const String buttonTextDe = "Meine Leistung analysieren";

  static const String analysisSummaryFr = "Tu progresses ! +25 % en 3 semaines";
  static const String analysisSummaryEn = "You're progressing! +25% in 3 weeks";
  static const String analysisSummaryDe = "Du machst Fortschritte! +25% in 3 Wochen";

  static const List<String> recommendationsFr = [
    "Augmente de 2,5 kg à la prochaine séance",
    "Maîtrise la technique avant de forcer",
  ];

  static const List<String> recommendationsEn = [
    "Increase by 2.5kg next session",
    "Master technique before pushing harder",
  ];

  static const List<String> recommendationsDe = [
    "Erhöhe nächste Einheit um 2,5 kg",
    "Beherrsche die Technik bevor du mehr Gewicht nimmst",
  ];

  static const String benefitFr = "Deviens la meilleure version de toi-même";
  static const String benefitEn = "Become the best version of yourself";
  static const String benefitDe = "Werde die beste Version von dir selbst";

  static const String ctaButtonFr = "Commencer";
  static const String ctaButtonEn = "Get Started";
  static const String ctaButtonDe = "Starten";
}
