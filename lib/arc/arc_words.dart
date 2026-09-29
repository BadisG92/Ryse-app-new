import 'package:intl/intl.dart';

import '../services/translations.dart';

/// Les mots de l'arc qui se composent : ce qui manque, une date, des litres.
///
/// Écrits une fois ici pour que l'accueil, la feuille du matin, les rappels
/// et le coach disent la même chose de la même façon.
class ArcWords {
  ArcWords._();

  /// « 1 repas et 0,5 L d'eau », ou une chaîne vide si rien ne manque.
  static String missing({required int meals, required int waterMl, required String lang}) {
    final parts = <String>[
      if (meals > 0) (meals == 1 ? 'arc_missing_meal_one' : 'arc_missing_meals').tr(lang).replaceAll('{n}', '$meals'),
      if (waterMl > 0) 'arc_missing_water'.tr(lang).replaceAll('{n}', litres(waterMl, lang)),
    ];
    return parts.join('arc_and'.tr(lang));
  }

  /// « 0,5 L » : une décimale au plus, dans le format de la langue.
  static String litres(int ml, String lang) {
    final n = NumberFormat.decimalPattern(lang)..maximumFractionDigits = 1;
    // Arrondi au dixième supérieur : « il manque 0 L » pour 30 ml serait faux.
    final l = (ml / 100).ceil() / 10;
    return '${n.format(l)} L';
  }

  /// « 29 décembre », sans l'année.
  static String date(DateTime d, String lang) {
    try {
      return DateFormat.MMMMd(lang).format(d);
    } catch (_) {
      return '${d.day}/${d.month}';
    }
  }

  /// « jeudi 1 octobre », quand le jour de la semaine compte.
  static String longDate(DateTime d, String lang) {
    try {
      return DateFormat.MMMMEEEEd(lang).format(d);
    } catch (_) {
      return date(d, lang);
    }
  }

  /// « 29 déc. », pour une date qui doit tenir sur une ligne serrée.
  static String shortDate(DateTime d, String lang) {
    try {
      return DateFormat.MMMd(lang).format(d);
    } catch (_) {
      return '${d.day}/${d.month}';
    }
  }

  /// « jour » ou « jours ».
  static String days(int n, String lang) => (n == 1 ? 'day' : 'days').tr(lang);
}
