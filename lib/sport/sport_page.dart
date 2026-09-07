import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../design/design.dart';
import '../services/localization_service.dart';
import '../services/ryze_dates.dart';
import '../services/translations.dart';
import '../services/workout_session_store.dart';
import 'sport_history_page.dart';
import 'sport_programs_page.dart';
import 'sport_today_page.dart';

/// L'onglet Sport : aujourd'hui, l'historique, les programmes.
///
/// Le calque exact de l'onglet Nutrition — la date, trois positions, la page
/// sur le papier. Le bandeau navy, le triple onglet fait main et le
/// tableau de bord à cinq cartes ont disparu : la journée sportive se lit
/// comme une seule chose, cardio et musculation distingués par la forme.
class SportPage extends StatefulWidget {
  const SportPage({super.key});

  @override
  State<SportPage> createState() => _SportPageState();
}

class _SportPageState extends State<SportPage> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Une séance gardée sur le téléphone repart dès qu'on ouvre l'onglet.
    WorkoutSessionStore.instance.syncPending();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) {
    setState(() => _index = index);
    _pages.animateToPage(index, duration: RyzeDurations.enter, curve: RyzeCurves.out);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    final date = RyzeDates.full(DateTime.now(), lang);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          const OnbBackground(scene: false),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, context.vw(1.5), gutter, context.vw(3.1)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(date, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                      SizedBox(height: context.vw(3.1)),
                      RyzeSegmented(
                        labels: ['sport_page_today'.tr(lang), 'sport_page_history'.tr(lang), 'sport_page_programs'.tr(lang)],
                        index: _index,
                        onChanged: _go,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: const [SportTodayPage(), SportHistoryPage(), SportProgramsPage()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
