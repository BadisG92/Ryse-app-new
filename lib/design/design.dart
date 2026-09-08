/// Ryze design system.
///
/// One import for tokens, type, motion and the components the v2 onboarding
/// established. The rest of the app is brought to this system page by page;
/// the onboarding keeps its `Onb*` names as aliases of these.
///
/// Layers:
/// - tokens.dart   colours, radii, spacing, shadows, assets
/// - type.dart     Archivo + Instrument Sans, viewport sizing
/// - motion.dart   curves, durations, PopIn / TypingDots / SlideSwapText
/// - ryze_logo     the mark and the wordmark as vector geometry
/// - logo_draw     the launch animation that writes them
/// - nav_bar       the bar of the app, four tabs and the two coaches
/// - feedback      what the phone answers: haptics and the system click
/// - sheet         the sheet of the system, its rows and its groups
/// - segmented     two or three pages of the same subject
/// - undo_bar      what the app says after a write, and how to take it back
/// - macro_rail    one macro nutrient against its goal
/// - glass_row     the day's water, as glasses you fill and empty
/// - day_instrument the one number of the day and its amber gauge
/// - meal_timeline the day's meals as one line, opening in place
/// - chat         le mobilier des conversations avec Ryze
/// - components    background grid, buttons, top bar, coach avatars, cards,
///                 choice cards and chips, rulers and wheels, chapter card,
///                 hold-to-sign, projection chart, week strip, proposal card
library;

export 'tokens.dart';
export 'type.dart';
export 'motion.dart';
export 'ryze_logo.dart';
export 'logo_draw.dart';
export 'mark.dart';
export 'nav_bar.dart';
export 'feedback.dart';
export 'sheet.dart';
export 'segmented.dart';
export 'undo_bar.dart';
export 'macro_rail.dart';
export 'glass_row.dart';
export 'camera_shell.dart';
export 'day_chip.dart';
export 'day_instrument.dart';
export 'sticky_total.dart';
export 'meal_timeline.dart';
export 'chat.dart';

export '../onboarding/widgets/onb_widgets.dart';
export '../onboarding/widgets/choices.dart';
export '../onboarding/widgets/pickers.dart';
export '../onboarding/widgets/chapter_card.dart';
export '../onboarding/widgets/hold_to_sign.dart';
export '../onboarding/widgets/projection_chart.dart';
export '../components/weekly_planner/week_strip.dart';
export '../components/weekly_planner/proposal_card.dart';
