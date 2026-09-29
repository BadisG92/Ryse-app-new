import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../components/nutrition_recipes_hybrid.dart';
import '../design/design.dart';
import '../services/app_navigator.dart';
import '../services/localization_service.dart';
import '../services/ryze_dates.dart';
import '../services/translations.dart';
import 'nutrition_history_page.dart';
import 'nutrition_today_page.dart';

/// The Nutrition tab: today, the history, and the dishes the user keeps.
///
/// The permanent band that used to sit above these three pages is gone. It
/// repeated the calories, the water, the sport and the streak that the pages
/// below already show, and none of it could be pressed. What is left is the
/// date, three positions, and the page itself on the onboarding's paper.
class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  late final PageController _pages;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Arriver depuis la feuille du Winter Arc, c'est arriver sur l'historique.
    final asked = AppNavigator().requestedNutritionPage.value;
    AppNavigator().requestedNutritionPage.value = null;
    _index = asked ?? 0;
    _pages = PageController(initialPage: _index);
    AppNavigator().requestedNutritionPage.addListener(_onRequested);
  }

  /// Une demande qui arrive alors que l'onglet est déjà ouvert.
  void _onRequested() {
    final asked = AppNavigator().requestedNutritionPage.value;
    if (asked == null || !mounted) return;
    AppNavigator().requestedNutritionPage.value = null;
    _go(asked);
  }

  @override
  void dispose() {
    AppNavigator().requestedNutritionPage.removeListener(_onRequested);
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
      value: RyzeColors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                      Text(
                        date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RyzeText.body(context, 3.6, weight: FontWeight.w600),
                      ),
                      SizedBox(height: context.vw(3.1)),
                      RyzeSegmented(
                        labels: [
                          'nutri_page_today'.tr(lang),
                          'nutri_page_history'.tr(lang),
                          'nutri_page_recipes'.tr(lang),
                        ],
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
                    children: const [
                      NutritionTodayPage(),
                      NutritionHistoryPage(),
                      NutritionRecipesHybrid(),
                    ],
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
