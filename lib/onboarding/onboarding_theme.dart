/// The onboarding's names for the design system. The tokens, type and motion
/// live in `lib/design/`; these aliases keep every `Onb*` reference working
/// without a visual change while the rest of the app is brought to the system.
library;

import '../design/tokens.dart';
import '../design/type.dart';
import '../design/motion.dart';

export '../design/tokens.dart';
export '../design/type.dart' show RyzeText, RyzeSizing;
export '../design/motion.dart' show RyzeCurves, RyzeDurations;

typedef OnbColors = RyzeColors;
typedef OnbCurves = RyzeCurves;
typedef OnbText = RyzeText;
typedef OnbAssets = RyzeAssets;
