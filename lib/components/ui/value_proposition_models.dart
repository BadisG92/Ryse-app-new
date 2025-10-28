/// Modèles de données pour les slides de value proposition

class ValuePropositionSlide {
  final int index;
  final String titleFr;
  final String titleEn;

  ValuePropositionSlide({
    required this.index,
    required this.titleFr,
    required this.titleEn,
  });
}

/// Slide 1 : Méthodes d'input
class InputMethod {
  final String icon;
  final String labelFr;
  final String labelEn;
  final String descriptionFr;
  final String descriptionEn;

  InputMethod({
    required this.icon,
    required this.labelFr,
    required this.labelEn,
    required this.descriptionFr,
    required this.descriptionEn,
  });
}

class Slide1Data {
  static const String titleFr = "Suis ton alimentation comme tu veux";
  static const String titleEn = "Track how you want, when you want";

  static const String coachNameFr = "Coach Ryze";
  static const String coachNameEn = "Coach Ryze";

  static const String coachMessageFr = "Fais le suivi en 5 secondes, pas 10 minutes";
  static const String coachMessageEn = "Track your meals in 5 seconds, not 10 minutes";

  static const String benefitFr = "Fini les recherches fastidieuses";
  static const String benefitEn = "No more tedious food database searches";

  static final List<InputMethod> methods = [
    InputMethod(
      icon: "📸",
      labelFr: "Photo",
      labelEn: "Photo",
      descriptionFr: "Scanne ton assiette",
      descriptionEn: "Snap your plate",
    ),
    InputMethod(
      icon: "🎤",
      labelFr: "Voix",
      labelEn: "Voice",
      descriptionFr: "Dis ce que tu as mangé",
      descriptionEn: "Say what you ate",
    ),
    InputMethod(
      icon: "✏️",
      labelFr: "Texte",
      labelEn: "Text",
      descriptionFr: "Écris ou cherche",
      descriptionEn: "Type or search",
    ),
  ];
}

/// Slide 2 : Coach sur demande
class Slide2Data {
  static const String titleFr = "Ajuste ta nutrition en temps réel";
  static const String titleEn = "Adjust your nutrition in real-time";

  static const String coachMessageFr = "Je regarde ta journée et te propose la suite optimale";
  static const String coachMessageEn = "I review your day and suggest the optimal next steps";

  static const String benefitFr = "Tu gardes toujours le contrôle de ta journée";
  static const String benefitEn = "You always stay in control of your day";

  static const String mockupCaloriesFr = "1200 / 2000 kcal";
  static const String mockupCaloriesEn = "1200 / 2000 kcal";

  static const String mockupProteinsFr = "60g / 150g";
  static const String mockupProteinsEn = "60g / 150g";

  static const String buttonTextFr = "Analyser ma journée";
  static const String buttonTextEn = "Analyze my day";

  // Exemples de réponses selon moment de la journée
  static const String coachResponseMorningFr = "Tu as encore 800 kcal. Pense à ajouter des protéines ce soir.";
  static const String coachResponseMorningEn = "You have 800 kcal left. Add protein tonight.";

  static const String coachResponsePostWorkoutFr = "Parfait pour la récup : 30g de protéines dans les 2h.";
  static const String coachResponsePostWorkoutEn = "Perfect for recovery: 30g protein within 2h.";

  static const String coachResponseEveningFr = "Bilan : 4/4 objectifs ! Bien joué, demain on ajuste.";
  static const String coachResponseEveningEn = "Summary: 4/4 goals! Well done, let's adjust tomorrow.";

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
}

/// Slide 3 : Analyse sport
class Slide3Data {
  static const String titleFr = "Progresse plus vite avec un vrai plan";
  static const String titleEn = "Progress faster with a real plan";

  static const String coachMessageFr = "Je te propose des séances personnalisées et j'analyse tes performances";
  static const String coachMessageEn = "I create personalized workouts and analyze your performance";

  static const String exerciseNameFr = "Squat";
  static const String exerciseNameEn = "Squat";

  static const List<double> progressDataPoints = [60, 70, 80, 80];
  static const List<String> progressLabels = ["S1", "S2", "S3", "S4"];

  static const String buttonTextFr = "Analyser mes perfs";
  static const String buttonTextEn = "Analyze my performance";

  static const String analysisSummaryFr = "Tu progresses ! +25 % en 3 semaines";
  static const String analysisSummaryEn = "You're progressing! +25% in 3 weeks";

  static const List<String> recommendationsFr = [
    "Augmente de 2,5 kg à la prochaine séance",
    "Maîtrise la technique avant de forcer",
  ];

  static const List<String> recommendationsEn = [
    "Increase by 2.5kg next session",
    "Master technique before pushing harder",
  ];

  static const String benefitFr = "Deviens la meilleure version de toi-même";
  static const String benefitEn = "Become the best version of yourself";

  static const String ctaButtonFr = "Commencer";
  static const String ctaButtonEn = "Get Started";
}
