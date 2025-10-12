import 'package:flutter/material.dart';
import 'dart:async';

/// Interface vocale moderne et non-invasive pour l'enregistrement des séries
/// Retourne les widgets (floating button + bottom bar) à placer dans un Stack parent
class ModernVoiceInput extends StatefulWidget {
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final VoidCallback onCancel;
  final bool isListening;
  final String recognizedText;
  final bool hasError; // État d'erreur (bouton rouge)
  final int retryCount; // Compteur de retry pour affichage

  const ModernVoiceInput({
    super.key,
    required this.onStartListening,
    required this.onStopListening,
    required this.onCancel,
    required this.isListening,
    required this.recognizedText,
    this.hasError = false,
    this.retryCount = 0,
  });

  @override
  State<ModernVoiceInput> createState() => _ModernVoiceInputState();
}

class _ModernVoiceInputState extends State<ModernVoiceInput>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<Offset> _slideAnimation;

  Timer? _autoStopTimer;

  @override
  void initState() {
    super.initState();

    // Slide animation pour la bottom bar
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Caché en dessous
      end: Offset.zero, // Visible
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Pulse animation pour le micro
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Wave animation pour l'indicateur
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ModernVoiceInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Quand l'écoute démarre
    if (widget.isListening && !oldWidget.isListening) {
      _slideController.forward();
      _startAutoStopTimer();
    }

    // Quand l'écoute s'arrête
    if (!widget.isListening && oldWidget.isListening) {
      _slideController.reverse();
      _cancelAutoStopTimer();
    }
  }

  void _startAutoStopTimer() {
    _cancelAutoStopTimer();
    _autoStopTimer = Timer(const Duration(seconds: 5), () {
      if (widget.isListening) {
        widget.onStopListening();
      }
    });
  }

  void _cancelAutoStopTimer() {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _cancelAutoStopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Retourne un Fragment contenant les 2 éléments positionnés
    return Stack(
      children: [
        // 1) BOTTOM BAR (visible si listening OU error avec message)
        if (widget.isListening || (widget.hasError && widget.recognizedText.isNotEmpty))
          _buildBottomBar(),

        // 2) FLOATING BUTTON (toujours visible)
        _buildFloatingButton(),
      ],
    );
  }

  /// 🎤 Floating Mic Button (BAS-DROITE)
  Widget _buildFloatingButton() {
    return Positioned(
      right: 20,   // ← À DROITE
      bottom: 90,  // ← EN BAS (au-dessus bouton "Terminer")
      child: GestureDetector(
        onTap: () {
          if (widget.isListening) {
            widget.onCancel();
          } else {
            widget.onStartListening();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isListening ? 70 : (widget.hasError ? 65 : 60),
          height: widget.isListening ? 70 : (widget.hasError ? 65 : 60),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Error: Rouge | Listening: Vert | Inactif: Bleu
            color: widget.hasError
                ? Colors.red  // Rouge pour erreur (retry)
                : (widget.isListening
                    ? const Color(0xFF10B981)  // Vert accent (en cours)
                    : const Color(0xFF0B132B)),  // Bleu primaire (inactif)
            boxShadow: [
              BoxShadow(
                color: (widget.hasError
                        ? Colors.red
                        : (widget.isListening
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0B132B)))
                    .withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: widget.hasError ? 3 : (widget.isListening ? 4 : 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                widget.isListening ? Icons.stop : Icons.mic,
                size: widget.isListening ? 32 : 28,
                color: Colors.white,
              ),
              // Badge retry count en haut à droite si error
              if (widget.hasError && widget.retryCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.retryCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 Bottom Bar (slide from bottom)
  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,  // ← EN BAS DE L'ÉCRAN
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Rouge foncé si erreur, sinon bleu-gris normal
            color: widget.hasError
                ? const Color(0xFF7F1D1D)  // Rouge foncé (error)
                : const Color(0xFF1E293B),  // Bleu-gris (normal)
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.hasError
                    ? Colors.red.withOpacity(0.3)
                    : Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // A) Micro animé (vert si listening, rouge si error)
                widget.hasError ? _buildErrorMic() : _buildPulsingMic(),

                const SizedBox(width: 16),

                // B) Texte (+ waveform seulement si listening, pas si error)
                Expanded(
                  child: widget.hasError
                      ? _buildErrorText()
                      : _buildTextAndWaveform(),
                ),

                // C) Bouton close (droite)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎤 Micro pulsing vert accent
  Widget _buildPulsingMic() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.1).animate(_pulseController),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10B981),  // Vert accent
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  /// ❌ Micro rouge statique (mode erreur)
  Widget _buildErrorMic() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.mic_off,
        size: 24,
        color: Colors.white,
      ),
    );
  }

  /// ❌ Texte d'erreur (sans waveform)
  Widget _buildErrorText() {
    return Text(
      widget.recognizedText,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 📝 Texte reconnu + waveform
  Widget _buildTextAndWaveform() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Texte reconnu ou placeholder
        Text(
          widget.recognizedText.isEmpty
              ? 'Dites : "80 kilos 10 reps"'
              : widget.recognizedText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.recognizedText.isEmpty
                ? Colors.white60
                : Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Waveform + "Écoute..."
        Row(
          children: [
            // 3 barres animées
            _buildWaveformBars(),
            const SizedBox(width: 8),
            const Text(
              'Écoute...',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF10B981),  // Vert accent
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 〰️ Waveform animé (3 barres)
  Widget _buildWaveformBars() {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(right: 2),
          width: 3,
          height: 12 + (index * 4).toDouble(), // [12, 16, 20]
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),  // Vert accent
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
