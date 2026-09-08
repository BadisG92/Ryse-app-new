import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/design.dart';
import '../services/exercise_ai_analysis_service.dart';
import '../services/localization_service.dart';
import '../services/paywall_service.dart';
import '../services/translations.dart';

/// L'analyse d'un exercice par Coach Ryze.
///
/// Elle vit sous la courbe de la page de progression : la courbe montre ce
/// qui s'est passé, l'analyse dit quoi en faire. Quatre états — pas assez de
/// séances, prêt à lancer, en cours, le résultat — et un seul bouton à la
/// fois. L'ambre est réservé à ce que Ryze rend : le titre, la puce de
/// chaque recommandation.
///
/// L'analyse est une fonctionnalité de l'abonnement
/// (`PaywallContext.exerciseAnalysis`).
class ExerciseAiAnalysisWidget extends StatefulWidget {
  final String exerciseName;
  final String userId;
  final List<Map<String, dynamic>> sessionHistory;

  const ExerciseAiAnalysisWidget({
    super.key,
    required this.exerciseName,
    required this.userId,
    required this.sessionHistory,
  });

  @override
  State<ExerciseAiAnalysisWidget> createState() => _ExerciseAiAnalysisWidgetState();
}

class _ExerciseAiAnalysisWidgetState extends State<ExerciseAiAnalysisWidget> {
  /// En dessous, l'IA n'a rien à lire : trois séances font une tendance.
  static const int _minSessions = 3;

  bool _loading = false;
  ExerciseAnalysis? _analysis;
  DateTime? _timestamp;
  bool _hasNewSessions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  @override
  void didUpdateWidget(ExerciseAiAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseName != widget.exerciseName || oldWidget.sessionHistory.length != widget.sessionHistory.length) {
      _loadCached();
    }
  }

  Future<void> _loadCached() async {
    try {
      final cached = await ExerciseAiAnalysisService.getCachedAnalysis(
        userId: widget.userId,
        exerciseName: widget.exerciseName,
      );
      if (!mounted) return;
      if (cached != null) {
        final fresh = await ExerciseAiAnalysisService.hasNewSessions(
          userId: widget.userId,
          exerciseName: widget.exerciseName,
          currentSessionCount: widget.sessionHistory.length,
        );
        if (!mounted) return;
        setState(() {
          _analysis = cached.analysis;
          _timestamp = cached.timestamp;
          _hasNewSessions = fresh;
        });
      } else {
        setState(() {
          _analysis = null;
          _timestamp = null;
          _hasNewSessions = false;
        });
      }
    } catch (_) {
      // Une analyse absente n'est pas une erreur : le bouton reste.
    }
  }

  Future<void> _generate() async {
    if (!mounted || _loading) return;
    final lang = LocalizationService.instance.currentLanguageCode;

    // L'essai n'est pas consommé ici : seulement si l'analyse aboutit.
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.exerciseAnalysis,
    );
    if (!canUse || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final analysis = await ExerciseAiAnalysisService.generateAnalysis(
        exerciseName: widget.exerciseName,
        sessionHistory: widget.sessionHistory,
        languageCode: lang,
      );
      await ExerciseAiAnalysisService.cacheAnalysis(
        userId: widget.userId,
        exerciseName: widget.exerciseName,
        analysis: analysis,
        sessionCount: widget.sessionHistory.length,
      );
      if (!mounted) return;
      RyzeFeedback.success();
      setState(() {
        _analysis = analysis;
        _timestamp = DateTime.now();
        _hasNewSessions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _messageFor(e, lang));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _messageFor(Object e, String lang) {
    final s = e.toString().toLowerCase();
    if (s.contains('api key') || s.contains('quota') || s.contains('billing')) return 'ai_analysis_error_service'.tr(lang);
    if (s.contains('sessions are required') || s.contains('not enough data')) return 'ai_analysis_error_data'.tr(lang);
    if (s.contains('network') || s.contains('connection') || s.contains('timeout')) return 'ai_analysis_error_network'.tr(lang);
    return 'ai_analysis_error_generic'.tr(lang);
  }

  static String _ago(DateTime t, String lang) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return 'ago_minutes'.tr(lang).replaceAll('{n}', '${d.inMinutes}');
    if (d.inHours < 24) return 'ago_hours'.tr(lang).replaceAll('{n}', '${d.inHours}');
    return 'ago_days'.tr(lang).replaceAll('{n}', '${d.inDays}');
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final enough = widget.sessionHistory.length >= _minSessions;

    return Container(
      padding: EdgeInsets.all(context.vw(4.1)),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: context.vw(9.7),
                height: context.vw(9.7),
                decoration: BoxDecoration(color: RyzeColors.acc, shape: BoxShape.circle),
                child: Center(child: RyzeMark(size: context.vw(5.6), color: RyzeColors.surf)),
              ),
              SizedBox(width: context.vw(3.1)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ai_performance_analysis'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                    if (_timestamp != null && _analysis != null)
                      Text(_ago(_timestamp!, lang), style: RyzeText.body(context, 2.9, color: RyzeColors.mute)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.vw(3.6)),
          if (!enough)
            Text(
              'ai_analysis_needs_more'.tr(lang).replaceAll('{n}', '${_minSessions - widget.sessionHistory.length}'),
              style: RyzeText.body(context, 3.4, color: RyzeColors.mute, height: 1.4),
            )
          else if (_loading)
            _Busy(label: 'analysis_in_progress'.tr(lang))
          else ...[
            if (_error != null) ...[
              Text(_error!, style: RyzeText.body(context, 3.4, color: RyzeColors.danger, height: 1.4)),
              SizedBox(height: context.vw(3.1)),
              _Button(label: 'ai_analysis_retry'.tr(lang), onTap: _generate),
            ] else if (_analysis == null)
              _Button(label: 'analyze_with_ai'.tr(lang), leading: RyzeMark(size: context.vw(5), color: RyzeColors.surf), onTap: _generate)
            else ...[
              Text(_analysis!.analysis, style: RyzeText.body(context, 3.4, height: 1.5)),
              if (_analysis!.recommendations.isNotEmpty) ...[
                SizedBox(height: context.vw(4.1)),
                Text('ai_analysis_recommendations'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
                SizedBox(height: context.vw(2.1)),
                for (final r in _analysis!.recommendations) _Reco(reco: r),
              ],
              if (_hasNewSessions) ...[
                SizedBox(height: context.vw(3.6)),
                Text('ai_analysis_new_sessions'.tr(lang), style: RyzeText.body(context, 3.1, color: RyzeColors.accInk)),
              ],
              SizedBox(height: context.vw(3.1)),
              _Button(label: 'ai_analysis_again'.tr(lang), ghost: true, onTap: _generate),
            ],
          ],
        ],
      ),
    );
  }
}

class _Reco extends StatelessWidget {
  const _Reco({required this.reco});

  final ExerciseRecommendation reco;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(2.6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(top: context.vw(1.5), right: context.vw(2.6)),
            decoration: BoxDecoration(color: RyzeColors.acc, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reco.title, style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                if (reco.description.trim().isNotEmpty)
                  Text(reco.description, style: RyzeText.body(context, 3.1, color: RyzeColors.mute, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: context.vw(4.6),
          height: context.vw(4.6),
          child: CircularProgressIndicator(color: RyzeColors.accInk, strokeWidth: 2),
        ),
        SizedBox(width: context.vw(3.1)),
        Text(label, style: RyzeText.body(context, 3.4, color: RyzeColors.mute)),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap, this.leading, this.ghost = false});

  final String label;
  final VoidCallback onTap;

  /// Ce qui précède le libellé : le signe de Ryze quand c'est lui qui agit.
  final Widget? leading;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: context.vw(12.3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ghost ? Colors.transparent : RyzeColors.ink,
          borderRadius: BorderRadius.circular(RyzeRadius.sm),
          border: ghost ? Border.all(color: RyzeColors.idle) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: context.vw(2.1)),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: ghost ? RyzeColors.ink : RyzeColors.surf),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
