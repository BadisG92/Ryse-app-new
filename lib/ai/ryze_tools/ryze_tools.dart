import 'journal_tools.dart';
import 'memory_tools.dart';
import 'nav_tools.dart';
import 'ryze_tool.dart';
import 'sport_tools.dart';

export 'journal_tools.dart';
export 'memory_tools.dart';
export 'nav_tools.dart';
export 'ryze_tool.dart';
export 'sport_tools.dart';

/// Tout ce que Ryze sait faire.
///
/// Le coach n'avait rien : son prompt lui apprenait à décrire l'endroit où
/// l'utilisateur devait aller. Chaque outil ici enveloppe un service qui
/// existait déjà et que l'application utilise par ailleurs — rien n'est
/// réécrit, seul le chemin change.
///
/// Le planificateur garde ses propres outils tant qu'il tourne sur son moteur ;
/// ils rejoindront ce registre au lot suivant.
RyzeToolRegistry buildRyzeToolRegistry() => RyzeToolRegistry([
      ...JournalTools.all,
      ...SportTools.all,
      ...NavTools.all,
      ...MemoryTools.all,
    ]);

/// Le registre de l'application, construit une fois.
final ryzeTools = buildRyzeToolRegistry();
