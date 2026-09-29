import 'dart:math' as math;

/// Une case de la grille : ce que la journée est devenue.
enum ArcCell {
  /// Deux repas et l'eau : la journée est tenue.
  held,

  /// Tenue, avec une séance en plus : la case est plus foncée.
  trained,

  /// Ratée, mais un joker l'a sauvée : un jour de gel, qui compte.
  joker,

  /// En cours : aujourd'hui, ou hier tant qu'il est encore rattrapable.
  pending,
}

/// La saison telle que l'app la connaît avant d'avoir parlé à la base.
///
/// La base est la seule à décider (`arc_state()`) ; ces dates ne servent qu'à
/// ce qui doit s'afficher sans elle : la ligne du paywall, et les rappels
/// posés avant la première réponse.
class ArcSeason {
  ArcSeason._();

  static final DateTime opens = DateTime(2026, 10, 1);
  static final DateTime lastStart = DateTime(2026, 12, 21);
  static final DateTime ends = DateTime(2027, 3, 20);

  /// Le nombre de jours à tenir.
  static const int length = 90;

  /// Les repas qu'une journée demande (deux moments différents).
  static const int mealsNeeded = 2;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// La saison est en cours ce jour-là.
  static bool isOpen(DateTime now) {
    final d = _day(now);
    return !d.isBefore(opens) && !d.isAfter(ends);
  }

  /// Une série qui commence ce jour-là peut encore gagner.
  static bool canStartToWin(DateTime now) => !_day(now).isAfter(lastStart);
}

class ArcToday {
  const ArcToday({required this.held, required this.meals, required this.waterMl, required this.waterGoalMl, required this.trained});

  final bool held;
  final int meals;
  final int waterMl;
  final int waterGoalMl;
  final bool trained;

  int get mealsMissing => math.max(0, ArcSeason.mealsNeeded - meals);
  int get waterMissingMl => math.max(0, waterGoalMl - waterMl);

  factory ArcToday.fromJson(Map<String, dynamic> j) => ArcToday(
        held: j['held'] == true,
        meals: _int(j['meals']),
        waterMl: _int(j['water_ml']),
        waterGoalMl: _int(j['water_goal'], 2000),
        trained: j['trained'] == true,
      );

  Map<String, dynamic> toJson() => {'held': held, 'meals': meals, 'water_ml': waterMl, 'water_goal': waterGoalMl, 'trained': trained};
}

/// Hier n'est pas complet, et il est encore temps.
class ArcGrace {
  const ArcGrace({required this.day, required this.meals, required this.waterMl, required this.waterGoalMl, required this.deadline});

  final DateTime day;
  final int meals;
  final int waterMl;
  final int waterGoalMl;

  /// Le lendemain midi, heure locale.
  final DateTime deadline;

  int get mealsMissing => math.max(0, ArcSeason.mealsNeeded - meals);
  int get waterMissingMl => math.max(0, waterGoalMl - waterMl);

  factory ArcGrace.fromJson(Map<String, dynamic> j) => ArcGrace(
        day: _date(j['day'])!,
        meals: _int(j['meals']),
        waterMl: _int(j['water_ml']),
        waterGoalMl: _int(j['water_goal'], 2000),
        deadline: DateTime.parse(j['deadline'] as String).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        'day': _ymd(day),
        'meals': meals,
        'water_ml': waterMl,
        'water_goal': waterGoalMl,
        'deadline': deadline.toUtc().toIso8601String(),
      };
}

/// La dernière série perdue.
class ArcBreak {
  const ArcBreak({required this.day, required this.lost});

  /// La journée ratée qui l'a arrêtée.
  final DateTime day;

  /// Sa longueur au moment de l'arrêt.
  final int lost;
}

/// Le Winter Arc d'un utilisateur, tel que `arc_state()` le rend.
///
/// L'app ne recalcule rien : elle lit. La seule chose qu'elle en déduit est
/// la façon de l'afficher.
class ArcState {
  const ArcState({
    required this.phase,
    required this.today,
    required this.streak,
    required this.streakStart,
    required this.cells,
    required this.jokers,
    required this.best,
    required this.wonOn,
    required this.eligible,
    required this.lastValid,
    required this.lastBreak,
    required this.lastJoker,
    required this.todayStatus,
    required this.grace,
  });

  /// `soon` avant le 1er octobre, `open` pendant la saison, `ended` après.
  final String phase;
  final DateTime today;

  /// Les cases validées de la série en cours (tenues et jokers).
  final int streak;
  final DateTime? streakStart;

  /// La série case par case, du premier jour à aujourd'hui. Vide tant
  /// qu'aucune journée n'est tenue.
  final List<ArcCell> cells;
  final int jokers;
  final int best;
  final DateTime? wonOn;

  /// La série en cours (ou celle qui commencerait aujourd'hui) peut gagner.
  final bool eligible;
  final DateTime? lastValid;
  final ArcBreak? lastBreak;
  final DateTime? lastJoker;
  final ArcToday? todayStatus;
  final ArcGrace? grace;

  bool get isSoon => phase == 'soon';
  bool get isOpen => phase == 'open';
  bool get isEnded => phase == 'ended';
  bool get won => wonOn != null;
  bool get todayHeld => todayStatus?.held ?? false;

  /// Le numéro de la case d'aujourd'hui.
  int get dayNumber => cells.isEmpty ? 1 : cells.length;

  /// Hier est incomplet, rattrapable, et il y a une série à sauver.
  bool get rescuable => grace != null && streak > 0;

  /// Le jour où la série atteindra 90, si rien ne la coupe. Avant
  /// l'ouverture, celle qui partirait le premier jour.
  ///
  /// En jours de calendrier et non en durée : 89 fois 24 heures traversent le
  /// passage à l'heure d'hiver et tombent la veille à 23 h.
  DateTime get finishOn {
    final d = streakStart ?? (isSoon ? ArcSeason.opens : today);
    return DateTime(d.year, d.month, d.day + ArcSeason.length - 1);
  }

  /// Hier, tel que la grille le montre : null s'il n'est pas dans la série.
  ///
  /// Dès qu'une série existe, sa dernière case est aujourd'hui (tenue ou en
  /// cours) : hier est donc l'avant-dernière.
  ArcCell? get yesterdayCell => cells.length >= 2 ? cells[cells.length - 2] : null;

  static const Map<String, ArcCell> _codes = {
    'h': ArcCell.held,
    't': ArcCell.trained,
    'j': ArcCell.joker,
    'p': ArcCell.pending,
  };

  factory ArcState.fromJson(Map<String, dynamic> j) {
    final raw = (j['cells'] as String?) ?? '';
    final lb = j['last_break'];
    return ArcState(
      phase: (j['phase'] as String?) ?? 'soon',
      today: _date(j['today']) ?? DateTime.now(),
      streak: _int(j['streak']),
      streakStart: _date(j['streak_start']),
      cells: [for (final c in raw.split('')) if (_codes[c] != null) _codes[c]!],
      jokers: _int(j['jokers']),
      best: _int(j['best']),
      wonOn: _date(j['won_on']),
      eligible: j['eligible'] == true,
      lastValid: _date(j['last_valid']),
      lastBreak: lb is Map<String, dynamic> && _date(lb['day']) != null ? ArcBreak(day: _date(lb['day'])!, lost: _int(lb['lost'])) : null,
      lastJoker: _date(j['last_joker']),
      todayStatus: j['today_status'] is Map<String, dynamic> ? ArcToday.fromJson(j['today_status'] as Map<String, dynamic>) : null,
      grace: j['grace'] is Map<String, dynamic> ? ArcGrace.fromJson(j['grace'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    const letters = {ArcCell.held: 'h', ArcCell.trained: 't', ArcCell.joker: 'j', ArcCell.pending: 'p'};
    return {
      'phase': phase,
      'today': _ymd(today),
      'streak': streak,
      'streak_start': streakStart == null ? null : _ymd(streakStart!),
      'cells': cells.map((c) => letters[c]).join(),
      'jokers': jokers,
      'best': best,
      'won_on': wonOn == null ? null : _ymd(wonOn!),
      'eligible': eligible,
      'last_valid': lastValid == null ? null : _ymd(lastValid!),
      'last_break': lastBreak == null ? null : {'day': _ymd(lastBreak!.day), 'lost': lastBreak!.lost},
      'last_joker': lastJoker == null ? null : _ymd(lastJoker!),
      'today_status': todayStatus?.toJson(),
      'grace': grace?.toJson(),
    };
  }

  /// Ce que le mode démo montre : une série de douze jours, la même que la
  /// flamme de démo de l'accueil.
  factory ArcState.demo(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return ArcState(
      phase: 'open',
      today: today,
      streak: 12,
      streakStart: DateTime(today.year, today.month, today.day - 12),
      cells: [
        for (var i = 0; i < 12; i++) (i % 3 == 1) ? ArcCell.trained : ArcCell.held,
        ArcCell.pending,
      ],
      jokers: 0,
      best: 12,
      wonOn: null,
      eligible: true,
      lastValid: DateTime(today.year, today.month, today.day - 1),
      lastBreak: null,
      lastJoker: null,
      todayStatus: const ArcToday(held: false, meals: 1, waterMl: 1500, waterGoalMl: 2000, trained: false),
      grace: null,
    );
  }
}

int _int(Object? v, [int fallback = 0]) => v is num ? v.round() : fallback;

DateTime? _date(Object? v) {
  if (v is! String || v.length < 10) return null;
  final d = DateTime.tryParse(v.substring(0, 10));
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
