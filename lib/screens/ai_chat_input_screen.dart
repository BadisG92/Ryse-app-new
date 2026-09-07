import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_svg/flutter_svg.dart';
import '../design/design.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import 'ai_analysis_screen.dart';
import '../services/gemini_analysis_service_v2.dart';
import '../services/paywall_service.dart';
import '../services/feature_trial_service.dart';
import '../services/subscription_service.dart';

class AIChatInputScreen extends StatefulWidget {
  final bool isFromDashboard;
  final String? mealName;
  final String? mealId;

  const AIChatInputScreen({
    super.key,
    this.isFromDashboard = false,
    this.mealName,
    this.mealId,
  });

  // Static method pour afficher comme bottom sheet
  static void showAsBottomSheet(
    BuildContext context, {
    bool isFromDashboard = false,
    String? mealName,
    String? mealId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AIChatInputScreen(
        isFromDashboard: isFromDashboard,
        mealName: mealName,
        mealId: mealId,
      ),
    );
  }

  @override
  State<AIChatInputScreen> createState() => _AIChatInputScreenState();
}

class _AIChatInputScreenState extends State<AIChatInputScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isAnalyzing = false;
  String? _errorMessage;

  // Speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;

  // Suggestions supprimées pour simplifier l'interface

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  /// Initialiser le speech to text
  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _errorMessage = 'Erreur de reconnaissance vocale';
        });
      },
    );
    setState(() {});
  }

  /// Démarrer/arrêter l'écoute
  void _toggleListening() async {
    if (!_speechEnabled) {
      setState(() {
        _errorMessage = LocalizationService.instance.currentLanguageCode == 'fr'
            ? 'Reconnaissance vocale non disponible'
            : 'Speech recognition not available';
      });
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
        _errorMessage = null;
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;

            // Si la confiance est élevée et que l'utilisateur a fini de parler
            if (result.finalResult && result.confidence > 0.8) {
              _isListening = false;
            }
          });
        },
        // Utiliser la langue de l'app
        localeId: LocalizationService.instance.currentLanguageCode == 'fr'
            ? 'fr_FR'
            : 'en_US',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = LocalizationService.instance.currentLanguageCode == 'fr'
            ? 'Veuillez décrire votre repas'
            : 'Please describe your meal';
      });
      return;
    }

    // Vérifier l'accès (Premium ou 1er essai gratuit)
    // Ne PAS marquer comme utilisé ici - on le fera seulement si l'analyse réussit
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.chatInput,
      markAsUsed: false, // ← Ne pas marquer maintenant
    );

    if (!canUse) {
      // Le paywall s'est affiché automatiquement
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      // Analyser le texte avec Gemini
      final result = await GeminiAnalysisServiceV2.analyzeTextDescription(
        text,
        userNote: null, // Pas de note additionnelle dans ce mode
      );

      if (!mounted) return;

      if (result.success && result.detectedFoods.isNotEmpty) {
        // ✅ Marquer le trial comme utilisé UNIQUEMENT si l'analyse a réussi
        if (!SubscriptionService.instance.isPremium) {
          await FeatureTrialService.instance.markFeatureAsUsed(
            FeatureTrialService.keyChat,
          );
          debugPrint('✅ Chat Coach trial marked as used after successful analysis');
        }

        // Naviguer vers AIAnalysisScreen avec les résultats
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AIAnalysisScreen(
              imagePath: null, // Pas d'image dans ce mode
              note: text, // Le texte saisi devient la "note"
              isFromDashboard: widget.isFromDashboard,
              mealName: widget.mealName,
              mealId: widget.mealId,
              isFromTextInput: true, // Nouveau flag pour différencier
              analysisResult: result, // Passer directement les résultats
            ),
          ),
        );
      } else {
        // Utiliser les messages d'erreur conviviaux depuis les traductions
        String errorKey = result.error ?? 'gemini_analysis_failed';

        // Si l'erreur est un message technique, chercher la clé de traduction
        final Map<String, String> errorKeyMap = {
          'gemini_not_configured': 'gemini_not_configured',
          'gemini_no_response': 'gemini_no_response',
          'gemini_no_foods_detected': 'gemini_no_foods_detected',
          'gemini_analysis_failed': 'gemini_analysis_failed',
        };

        // Si l'erreur correspond à une clé, utiliser la traduction
        String finalError = errorKey;
        if (errorKeyMap.containsKey(errorKey)) {
          finalError = errorKey.tr(LocalizationService.instance.currentLanguageCode);
        }

        setState(() {
          _errorMessage = finalError;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = LocalizationService.instance.currentLanguageCode == 'fr'
              ? 'Erreur lors de l\'analyse'
              : 'Error during analysis';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final isSheet = Navigator.of(context).canPop();
    final gutter = context.vw(5.1);

    final content = Container(
      decoration: BoxDecoration(
        color: RyzeColors.paper,
        borderRadius: isSheet
            ? const BorderRadius.vertical(top: Radius.circular(RyzeRadius.lg))
            : BorderRadius.circular(RyzeRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isSheet) ...[
            SizedBox(height: context.vw(2.6)),
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, context.vw(4.6), gutter, context.vw(1)),
            child: Text('describe_meal'.tr(lang), style: RyzeText.body(context, 5.1, weight: FontWeight.w600)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Text('coach_will_analyze'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute)),
          ),
          SizedBox(height: context.vw(4.6)),

          // Ce qu'on dit au coach. La dictée est à côté du champ, en encre :
          // c'est un outil de saisie, pas une fonction à part.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Container(
              decoration: BoxDecoration(
                color: RyzeColors.surf,
                borderRadius: BorderRadius.circular(RyzeRadius.md),
                border: Border.all(color: _isListening ? RyzeColors.ink : RyzeColors.line, width: _isListening ? 1.5 : 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      autofocus: !_isListening,
                      maxLines: 4,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      style: RyzeText.body(context, 3.9, height: 1.45),
                      cursorColor: RyzeColors.ink,
                      onSubmitted: (_) => _analyzeText(),
                      decoration: InputDecoration(
                        hintText: 'chat_meal_placeholder'.tr(lang),
                        hintStyle: RyzeText.body(context, 3.9, color: RyzeColors.mute2),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(3.6), context.vw(2.1), context.vw(3.6)),
                      ),
                    ),
                  ),
                  if (_speechEnabled)
                    Padding(
                      padding: EdgeInsets.only(right: context.vw(2.6), bottom: context.vw(2.6)),
                      child: Pressable(
                        onTap: _isAnalyzing ? null : _toggleListening,
                        child: AnimatedContainer(
                          duration: RyzeDurations.tap,
                          curve: RyzeCurves.out,
                          width: context.vw(10.8),
                          height: context.vw(10.8),
                          decoration: BoxDecoration(
                            color: _isListening ? RyzeColors.ink : RyzeColors.paper,
                            shape: BoxShape.circle,
                            border: Border.all(color: _isListening ? RyzeColors.ink : RyzeColors.line),
                          ),
                          child: Icon(
                            _isListening ? LucideIcons.audioLines : LucideIcons.mic,
                            size: context.vw(4.6),
                            color: _isListening ? RyzeColors.surf : RyzeColors.mute,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_isListening)
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, context.vw(2.1), gutter, 0),
              child: Text(
                'chat_listening'.tr(lang),
                style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.accInk),
              ),
            ),

          if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, context.vw(2.6), gutter, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: context.vw(3.6), color: RyzeColors.danger),
                  SizedBox(width: context.vw(2.1)),
                  Expanded(
                    child: Text(_errorMessage!, style: RyzeText.body(context, 3.2, color: RyzeColors.danger)),
                  ),
                ],
              ),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(gutter, context.vw(4.6), gutter, MediaQuery.of(context).viewInsets.bottom + context.vw(4.6)),
            child: Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: _isAnalyzing ? null : () => Navigator.pop(context),
                    child: Container(
                      height: context.vw(13.3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: RyzeColors.surf,
                        borderRadius: BorderRadius.circular(RyzeRadius.sm),
                        border: Border.all(color: RyzeColors.line),
                      ),
                      child: Text('cancel'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                    ),
                  ),
                ),
                SizedBox(width: context.vw(3.1)),
                Expanded(
                  flex: 2,
                  child: Pressable(
                    onTap: _isAnalyzing ? null : _analyzeText,
                    child: Container(
                      height: context.vw(13.3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: RyzeColors.ink,
                        borderRadius: BorderRadius.circular(RyzeRadius.sm),
                        boxShadow: RyzeShadow.soft,
                      ),
                      child: _isAnalyzing
                          ? SizedBox(
                              width: context.vw(4.6),
                              height: context.vw(4.6),
                              child: const CircularProgressIndicator(strokeWidth: 2, color: RyzeColors.surf),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/logo_solo.svg',
                                  width: context.vw(4.6),
                                  height: context.vw(4.6),
                                  colorFilter: const ColorFilter.mode(RyzeColors.surf, BlendMode.srcIn),
                                ),
                                SizedBox(width: context.vw(2.6)),
                                Text(
                                  'analyze_meal'.tr(lang),
                                  style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isSheet) SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );

    if (isSheet) return content;
    return Scaffold(
      backgroundColor: RyzeColors.paper,
      body: SafeArea(child: SingleChildScrollView(child: content)),
    );
  }
}