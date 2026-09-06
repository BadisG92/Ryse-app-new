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
/// - components    background grid, buttons, top bar, coach avatars, cards,
///                 choice cards and chips, rulers and wheels, chapter card,
///                 hold-to-sign, projection chart, week strip, proposal card
library;

export 'tokens.dart';
export 'type.dart';
export 'motion.dart';

export '../onboarding/widgets/onb_widgets.dart';
export '../onboarding/widgets/choices.dart';
export '../onboarding/widgets/pickers.dart';
export '../onboarding/widgets/chapter_card.dart';
export '../onboarding/widgets/hold_to_sign.dart';
export '../onboarding/widgets/projection_chart.dart';
export '../components/weekly_planner/week_strip.dart';
export '../components/weekly_planner/proposal_card.dart';
