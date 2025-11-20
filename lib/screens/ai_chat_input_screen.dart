import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_svg/flutter_svg.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import 'ai_analysis_screen.dart';
import '../services/gemini_analysis_service_v2.dart';
import '../models/ai_analysis_models.dart';
import '../components/ui/coach_ryze_avatar.dart';
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
  double _speechConfidence = 0;

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
            _speechConfidence = result.confidence;

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
    final locService = context.watch<LocalizationService>();
    final isBottomSheet = Navigator.of(context).canPop();

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isBottomSheet
            ? const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              )
            : BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle pour bottom sheet
          if (isBottomSheet) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],

          // Header style bilan nutritionnel
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Texte à gauche
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'describe_meal'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'coach_will_analyze'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Avatar Coach Ryze Chat (sans pomme) à droite - taille xxxlarge
                const CoachRyzeAvatar(
                  type: CoachRyzeAvatarType.nutritionChat,
                  size: CoachRyzeAvatarSize.xxxlarge, // 180px - Comme bilan nutritionnel
                  withShadow: false,
                ),
              ],
            ),
          ),

          // Zone de texte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _errorMessage != null
                              ? Colors.red.shade300
                              : _isListening
                                  ? const Color(0xFF0B132B)
                                  : const Color(0xFFE2E8F0),
                          width: _isListening ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: 3,
                              maxLength: 500,
                              enabled: !_isAnalyzing && !_isListening,
                              decoration: InputDecoration(
                                hintText: _isListening
                                    ? (locService.currentLanguageCode == 'fr'
                                        ? 'Parlez maintenant...'
                                        : 'Speak now...')
                                    : 'ai_chat_hint'.tr(locService.currentLanguageCode),
                                hintStyle: TextStyle(
                                  color: _isListening
                                      ? const Color(0xFF0B132B)
                                      : const Color(0xFF94A3B8),
                                  fontSize: 14,
                                  fontWeight: _isListening ? FontWeight.w500 : FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                counterText: '',
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A1A),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _analyzeText(),
                            ),
                          ),
                          // Bouton microphone
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: _isAnalyzing ? null : _toggleListening,
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: _isListening
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF10B981), // Vert emerald-500
                                              Color(0xFF059669), // Vert emerald-600
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: _isListening ? null : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    LucideIcons.mic,
                                    color: _isListening
                                        ? Colors.white
                                        : (_speechEnabled
                                            ? const Color(0xFF0B132B)
                                            : const Color(0xFF94A3B8)),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Indicateur d'écoute animé
                    if (_isListening)
                      Positioned(
                        bottom: 4,
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 2,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF0B132B).withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Compteur de caractères
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _textController,
                        builder: (context, value, child) {
                          return Text(
                            '${value.text.length}/500',
                            style: TextStyle(
                              fontSize: 12,
                              color: value.text.length > 450
                                  ? Colors.orange
                                  : const Color(0xFF94A3B8),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Message d'erreur
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),


          // Boutons d'action
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Row(
              children: [
                // Bouton Annuler
                Expanded(
                  child: TextButton(
                    onPressed: _isAnalyzing ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'cancel'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton Analyser
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isAnalyzing ? null : _analyzeText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _isAnalyzing ? 0 : 4,
                    ),
                    child: _isAnalyzing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/logo_solo.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'analyze_meal'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Padding bottom pour les appareils sans bottom bar
          if (!isBottomSheet)
            SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );

    if (isBottomSheet) {
      return content;
    } else {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('ai_chat_title'.tr(locService.currentLanguageCode)),
          backgroundColor: const Color(0xFF0B132B),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: content,
        ),
      );
    }
  }
}