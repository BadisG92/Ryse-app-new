import 'package:intl/intl.dart';

import 'translations.dart';

/// Dates written for a screen, without a screen ever depending on them.
///
/// `DateFormat` with an explicit locale throws when the ICU symbols for that
/// locale have not been loaded, and in release an exception thrown inside a
/// build is a grey rectangle where the page should be. That is exactly how the
/// Nutrition tab died: three date lines took the whole tab with them.
///
/// The symbols are loaded once in `main`, so the good path is the real one.
/// These helpers only make sure that if they are ever missing again — a new
/// language, a trimmed build, an initialisation that timed out — the app writes
/// a plainer date instead of showing nothing.
class RyzeDates {
  RyzeDates._();

  /// L'heure qu'un horodatage du journal portait au moment où il a été écrit.
  ///
  /// `consumed_at` reçoit l'heure murale du téléphone, sans son décalage :
  /// « 22:24 ». Postgres, dont la colonne est en temps universel, la relit
  /// donc comme « 22:24 UTC » et la rend telle quelle. La convertir en heure
  /// locale ajoute le décalage une seconde fois — un dîner noté à 22 h 24 à
  /// Paris devenait 0 h 24, le lendemain — et c'est ainsi qu'un repas du soir
  /// cochait la case du jour suivant dans le planificateur, et s'affichait
  /// deux heures trop tard dans le journal.
  ///
  /// On rend donc les chiffres tels qu'ils ont été écrits. Le jour où la
  /// colonne portera du vrai temps universel, c'est ici que la conversion
  /// reviendra, et à un seul endroit.
  static DateTime? wall(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final at = DateTime.tryParse(raw);
    if (at == null) return null;
    return DateTime(at.year, at.month, at.day, at.hour, at.minute, at.second);
  }

  static const _weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  /// "Dimanche 7 septembre". Falls back to the weekday and the day number,
  /// which the dictionary always has.
  static String full(DateTime date, String lang) {
    try {
      final out = DateFormat.MMMMEEEEd(lang).format(date);
      return out.isEmpty ? _plain(date, lang) : '${out[0].toUpperCase()}${out.substring(1)}';
    } catch (_) {
      return _plain(date, lang);
    }
  }

  /// The two or three letters of a weekday, for a strip of days.
  static String short(DateTime date, String lang) {
    try {
      final out = DateFormat.E(lang).format(date);
      if (out.isEmpty) return _letters(date, lang);
      return out.substring(0, out.length >= 3 ? 3 : out.length).toUpperCase();
    } catch (_) {
      return _letters(date, lang);
    }
  }

  static String _plain(DateTime date, String lang) {
    final weekday = _weekdays[date.weekday - 1].tr(lang);
    final cap = weekday.isEmpty ? weekday : '${weekday[0].toUpperCase()}${weekday.substring(1)}';
    return 'home_date'.tr(lang).replaceAll('{d}', cap).replaceAll('{n}', '${date.day}');
  }

  static String _letters(DateTime date, String lang) {
    final weekday = _weekdays[date.weekday - 1].tr(lang);
    return weekday.isEmpty ? '' : weekday.substring(0, weekday.length >= 3 ? 3 : weekday.length).toUpperCase();
  }
}
