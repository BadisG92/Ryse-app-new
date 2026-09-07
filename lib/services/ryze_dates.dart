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
