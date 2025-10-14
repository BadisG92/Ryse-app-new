import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/exercise_ai_analysis_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

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
  bool _isLoading = false;
  bool _isExpanded = true;
  String? _analysisText;
  DateTime? _analysisTimestamp;
  bool _hasNewSessions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCachedAnalysis();
  }

  @override
  void didUpdateWidget(ExerciseAiAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le nombre de séances a changé, on revérifie
    if (oldWidget.sessionHistory.length != widget.sessionHistory.length) {
      _checkForNewSessions();
    }
  }

  Future<void> _checkForNewSessions() async {
    final cached = await ExerciseAiAnalysisService.getCachedAnalysis(
      userId: widget.userId,
      exerciseName: widget.exerciseName,
    );

    if (cached != null) {
      final hasNew = await ExerciseAiAnalysisService.hasNewSessions(
        userId: widget.userId,
        exerciseName: widget.exerciseName,
        currentSessionCount: widget.sessionHistory.length,
      );

      if (mounted) {
        setState(() {
          _hasNewSessions = hasNew;
        });
      }
    }
  }

  Future<void> _loadCachedAnalysis() async {
    final cached = await ExerciseAiAnalysisService.getCachedAnalysis(
      userId: widget.userId,
      exerciseName: widget.exerciseName,
    );

    if (cached != null) {
      setState(() {
        _analysisText = cached.text;
        _analysisTimestamp = cached.timestamp;
      });

      // Vérifier si de nouvelles séances ont été ajoutées
      final hasNew = await ExerciseAiAnalysisService.hasNewSessions(
        userId: widget.userId,
        exerciseName: widget.exerciseName,
        currentSessionCount: widget.sessionHistory.length,
      );

      if (hasNew) {
        setState(() {
          _hasNewSessions = true;
        });
      }
    }
  }

  Future<void> _generateAnalysis() async {
    if (!mounted) return;

    final locService = context.read<LocalizationService>();
    final languageCode = locService.currentLanguageCode;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analysis = await ExerciseAiAnalysisService.generateAnalysis(
        exerciseName: widget.exerciseName,
        sessionHistory: widget.sessionHistory,
        languageCode: languageCode,
      );

      await ExerciseAiAnalysisService.cacheAnalysis(
        userId: widget.userId,
        exerciseName: widget.exerciseName,
        analysisText: analysis,
        sessionCount: widget.sessionHistory.length,
      );

      if (!mounted) return;

      setState(() {
        _analysisText = analysis;
        _analysisTimestamp = DateTime.now();
        _hasNewSessions = false;
        _isExpanded = true;
      });
    } catch (e) {
      debugPrint('Error generating analysis: $e');

      if (!mounted) return;

      // Gérer différents types d'erreurs
      String errorMsg;
      if (e.toString().contains('API key expired')) {
        errorMsg = languageCode == 'fr'
            ? '⚠️ Clé API expirée. Veuillez contacter le support.'
            : '⚠️ API key expired. Please contact support.';
      } else if (e.toString().contains('sessions are required')) {
        errorMsg = languageCode == 'fr'
            ? '⚠️ Au moins 3 séances sont nécessaires'
            : '⚠️ At least 3 sessions are required';
      } else {
        errorMsg = languageCode == 'fr'
            ? '⚠️ Erreur lors de la génération. Réessayez.'
            : '⚠️ Generation error. Please retry.';
      }

      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getTimeAgo(DateTime timestamp, String languageCode) {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return languageCode == 'fr'
          ? 'Il y a ${minutes}min'
          : '${minutes}min ago';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return languageCode == 'fr'
          ? 'Il y a ${hours}h'
          : '${hours}h ago';
    } else {
      final days = diff.inDays;
      return languageCode == 'fr'
          ? 'Il y a ${days}j'
          : '${days}d ago';
    }
  }

  /// Construit le texte formaté avec support du markdown pour **gras**
  /// et ajoute automatiquement "Analyse :" et "Recommandations" en gras
  Widget _buildFormattedText(String text) {
    final spans = <TextSpan>[];

    // Supprimer les préambules type "Analyse de ta progression sur..." au début
    text = text.replaceAll(RegExp(r'^Analyse de ta progression sur [^:]+:\s*', multiLine: false), '');
    text = text.replaceAll(RegExp(r'^Analysis of your progression on [^:]+:\s*', multiLine: false), '');

    // Ajouter "Analyse :" en gras au début si pas déjà présent
    if (!text.startsWith('**Analyse') && !text.startsWith('**Analysis')) {
      if (text.startsWith('Analyse :') || text.startsWith('Analyse:')) {
        // Si "Analyse :" existe déjà, le mettre en gras
        text = text.replaceFirst(RegExp(r'^Analyse\s*:'), '**Analyse** :');
      } else if (text.startsWith('Analysis :') || text.startsWith('Analysis:')) {
        text = text.replaceFirst(RegExp(r'^Analysis\s*:'), '**Analysis** :');
      } else {
        // Sinon, ajouter "Analyse :" au début
        // Détecter la langue (si "Recommandations" ou "Recommendations")
        if (text.contains('Recommandations')) {
          text = '**Analyse** :\n\n$text';
        } else {
          text = '**Analysis** :\n\n$text';
        }
      }
    }

    // Entourer "Recommandations" avec ** et ajouter : s'il manque
    text = text.replaceAll(RegExp(r'(?<!\*\*)Recommandations(?!\*\*)(?!\s*:)'), '**Recommandations** :');
    text = text.replaceAll(RegExp(r'(?<!\*\*)Recommendations(?!\*\*)(?!\s*:)'), '**Recommendations** :');
    // Si déjà en gras mais sans :
    text = text.replaceAll(RegExp(r'\*\*Recommandations\*\*(?!\s*:)'), '**Recommandations** :');
    text = text.replaceAll(RegExp(r'\*\*Recommendations\*\*(?!\s*:)'), '**Recommendations** :');

    // Ajouter des bullet points avant chaque recommandation
    // Détecte les lignes après "Recommandations :" qui commencent par une majuscule et ne sont pas vides
    final lines = text.split('\n');
    bool afterRecommandations = false;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Détecter si on est après "Recommandations :"
      if (line.contains('**Recommandations**') || line.contains('**Recommendations**')) {
        afterRecommandations = true;
        continue;
      }

      // Si on est après recommandations et que la ligne commence par une lettre majuscule et ne commence pas déjà par •
      if (afterRecommandations && line.isNotEmpty && !line.startsWith('•') && RegExp(r'^[A-ZÀÂÄÇÉÈÊËÏÎÔÙÛÜ]').hasMatch(line)) {
        lines[i] = '• ${lines[i].trimLeft()}';
      }
    }
    text = lines.join('\n');

    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Ajouter le texte avant le match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(
            fontSize: 14,
            height: 1.7,
            color: Color(0xFF334155),
            letterSpacing: 0.2,
          ),
        ));
      }

      // Ajouter le texte en gras (sans les **)
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          fontSize: 15,
          height: 1.7,
          color: Color(0xFF0B132B),
          letterSpacing: 0.2,
          fontWeight: FontWeight.w700,
        ),
      ));

      lastIndex = match.end;
    }

    // Ajouter le reste du texte
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(
          fontSize: 14,
          height: 1.7,
          color: Color(0xFF334155),
          letterSpacing: 0.2,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) {
        final languageCode = locService.currentLanguageCode;

        // État erreur : Message d'erreur
        if (_errorMessage != null && !_isLoading) {
          return _buildErrorState(languageCode);
        }

        // État 1 : Bouton initial (pas d'analyse en cache)
        if (_analysisText == null && !_isLoading) {
          return _buildInitialButton(languageCode);
        }

        // État 2 : Loading
        if (_isLoading) {
          return _buildLoadingState(languageCode);
        }

        // État 3 : Affichage de l'analyse
        if (_analysisText != null) {
          return _buildAnalysisCard(languageCode);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInitialButton(String languageCode) {
    // Si moins de 3 séances, afficher le message informatif
    final hasMinimumSessions = widget.sessionHistory.length >= 3;

    if (!hasMinimumSessions) {
      return _buildUnavailableState(languageCode);
    }

    // Si 3 séances ou plus, afficher le bouton d'analyse
    return GestureDetector(
      onTap: _generateAnalysis,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
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
              'analyze_with_ai'.tr(languageCode),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableState(String languageCode) {
    final sessionsNeeded = 3 - widget.sessionHistory.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Logo Ryze en bleu (sans cercle, même style que le header)
            SvgPicture.asset(
              'assets/images/logo_solo.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF0B132B),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ai_performance_analysis'.tr(languageCode),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ai_analysis_unavailable'.tr(languageCode),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    languageCode == 'fr'
                        ? 'Encore ${sessionsNeeded} séance${sessionsNeeded > 1 ? 's' : ''} à faire'
                        : '${sessionsNeeded} more session${sessionsNeeded > 1 ? 's' : ''} to go',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String languageCode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.red.shade700,
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String languageCode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo animé
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'analysis_in_progress'.tr(languageCode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  languageCode == 'fr'
                      ? 'Le Coach Ryze analyse vos performances...'
                      : 'Coach Ryze is analyzing your performance...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(String languageCode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header premium avec gradient
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Logo Ryze en blanc sur fond gradient
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/logo_solo.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Titre en blanc
                  Expanded(
                    child: Text(
                      'ai_analysis'.tr(languageCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Bouton refresh stylé (TEMPORAIRE: toujours visible pour les tests)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      color: Colors.white,
                      onPressed: _generateAnalysis,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Icon expand/collapse stylé
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu (si expanded)
          if (_isExpanded) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texte de l'analyse avec support markdown pour gras
                  _buildFormattedText(_analysisText!),

                  // Timestamp stylé
                  if (_analysisTimestamp != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(_analysisTimestamp!, languageCode),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
