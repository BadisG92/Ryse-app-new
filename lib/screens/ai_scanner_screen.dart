import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../design/design.dart';
import '../services/localization_service.dart';
import 'ai_analysis_screen.dart';
import '../services/translations.dart';
import '../services/paywall_service.dart';
import 'dart:io';

class AIScannerScreen extends StatefulWidget {
  final bool isFromDashboard;
  final String? mealName;
  final String? mealId;

  const AIScannerScreen({
    super.key,
    this.isFromDashboard = false,
    this.mealName,
    this.mealId,
  });

  @override
  State<AIScannerScreen> createState() => _AIScannerScreenState();
}

class _AIScannerScreenState extends State<AIScannerScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  String? _errorMessage;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  /// La photo qu'on vient de prendre. Tant qu'elle est là, l'écran montre
  /// l'image figée et demande son détail au lieu de pousser une page.
  XFile? _shot;
  final TextEditingController _note = TextEditingController();
  static const int _maxNoteLength = 500;


  @override
  void initState() {
    super.initState();
    if (kDebugMode) debugPrint('🔥 [FLUX AI] 📸 ===== VERSION AVEC ZOOM ET NOTE =====');
    if (kDebugMode) debugPrint('🔥 [FLUX AI] 📸 PAS d\'écran de choix - Caméra DIRECTE !');

    // Vérifier le Premium après que le widget soit monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPremiumAccess();
    });
  }

  /// Le scanner est une fonctionnalité de l'abonnement.
  Future<void> _checkPremiumAccess() async {
    final canAccess = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.scanner,
    );

    if (!canAccess) {
      // Sans abonnement, le paywall a été montré puis refermé.
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    // Si accès autorisé, initialiser la caméra
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (kDebugMode) debugPrint('🔥 [FLUX AI] 📹 Initialisation caméra native');
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'error_camera_not_available'.tr(LocalizationService.instance.currentLanguageCode);
          _isLoading = false;
        });
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController?.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 [FLUX AI] ❌ Erreur caméra: $e');
      // Quitter l'écran pendant l'initialisation faisait lever ce setState.
      if (!mounted) return;
      setState(() {
        _errorMessage = '${'error_camera'.tr(LocalizationService.instance.currentLanguageCode)}: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (kDebugMode) debugPrint('🔥 [FLUX AI] 📸 Prise de photo');
    if (_cameraController == null || !(_cameraController?.value.isInitialized ?? false)) {
      return;
    }

    try {
      final image = await _cameraController?.takePicture();
      if (image == null || !mounted) return;
      RyzeFeedback.confirm();
      setState(() => _shot = image);
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 [FLUX AI] ❌ Erreur photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_generic'.tr(LocalizationService.instance.currentLanguageCode))),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    if (kDebugMode) debugPrint('🔥 [FLUX AI] 🖼️ Ouverture galerie');
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        RyzeFeedback.confirm();
        setState(() => _shot = image);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 [FLUX AI] ❌ Erreur galerie: $e');
    }
  }

  /// Reprendre : l'image figée s'en va, le viseur revient.
  void _retake() {
    RyzeFeedback.tap();
    setState(() {
      _shot = null;
      _note.clear();
    });
  }

  /// Envoyer la photo au coach. L'écran d'analyse est celui que le chat
  /// utilise aussi : un seul endroit à corriger quand il évolue.
  void _analyse() {
    final shot = _shot;
    if (shot == null) return;
    RyzeFeedback.confirm();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AIAnalysisScreen(
          imagePath: shot.path,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          isFromDashboard: widget.isFromDashboard,
          mealName: widget.mealName,
          mealId: widget.mealId,
        ),
      ),
    );
  }

  void _toggleFlash() {
    if (_cameraController != null) {
      _cameraController?.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch
      );
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return _buildCameraScreen();
  }

  Widget _buildLoadingScreen() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Scaffold(
      backgroundColor: RyzeColors.ink,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: RyzeColors.surf, strokeWidth: 2),
            ),
            SizedBox(height: context.vw(4.6)),
            Text(
              'camera_initializing'.tr(lang),
              style: RyzeText.body(context, 3.6, color: RyzeColors.surf.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  /// Pas de caméra. Ce n'est pas une impasse : une photo de la galerie fait
  /// exactement le même travail.
  Widget _buildErrorScreen() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Scaffold(
      backgroundColor: RyzeColors.ink,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.vw(8)),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: context.vw(2.1)),
                  child: Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: context.vw(10.8),
                      height: context.vw(10.8),
                      decoration: BoxDecoration(
                        color: RyzeColors.surf.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.x, size: context.vw(4.6), color: RyzeColors.surf),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Icon(LucideIcons.cameraOff, size: context.vw(12.3), color: RyzeColors.surf.withValues(alpha: 0.5)),
              SizedBox(height: context.vw(4.6)),
              Text(
                _errorMessage ?? '',
                textAlign: TextAlign.center,
                style: RyzeText.body(context, 3.9, color: RyzeColors.surf.withValues(alpha: 0.85)),
              ),
              SizedBox(height: context.vw(7.7)),
              Pressable(
                onTap: _pickFromGallery,
                child: Container(
                  height: context.vw(13.3),
                  padding: EdgeInsets.symmetric(horizontal: context.vw(6.2)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: RyzeColors.paper,
                    borderRadius: BorderRadius.circular(RyzeRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.image, size: context.vw(4.6), color: RyzeColors.ink),
                      SizedBox(width: context.vw(2.6)),
                      Text(
                        'select_image_from_files'.tr(lang),
                        style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCameraScreen() {
    final lang = LocalizationService.instance.currentLanguageCode;
    final shot = _shot;

    return RyzeCameraShell(
      controller: _cameraController,
      ready: _isCameraInitialized && _cameraController != null && shot == null,
      title: 'scan_dish'.tr(lang),
      hint: 'scan_dish_hint'.tr(lang),
      onClose: () => Navigator.pop(context),
      rightIcon: shot == null ? (_isFlashOn ? LucideIcons.zap : LucideIcons.zapOff) : null,
      rightLabel: 'flash'.tr(lang),
      rightAction: shot == null ? _toggleFlash : null,
      shutter: shot == null ? _takePicture : null,
      leftIcon: shot == null ? LucideIcons.image : null,
      leftLabel: 'gallery'.tr(lang),
      leftAction: shot == null ? _pickFromGallery : null,
      // Le pincement pour zoomer appartient au viseur : il le tient pour
      // toutes les caméras, celle du code-barres comprise.
      overlay: shot == null ? null : Positioned.fill(child: Image.file(File(shot.path), fit: BoxFit.cover)),
      footer: shot == null ? null : _NoteBar(controller: _note, maxLength: _maxNoteLength, lang: lang, onRetake: _retake, onSend: _analyse),
    );
  }
}

/// Ce qui remplace l'écran de preview : une ligne pour préciser ce que la
/// photo ne dit pas, et les deux suites possibles. La question est facultative,
/// donc « Analyser » n'attend rien pour être pressé.
class _NoteBar extends StatelessWidget {
  const _NoteBar({
    required this.controller,
    required this.maxLength,
    required this.lang,
    required this.onRetake,
    required this.onSend,
  });

  final TextEditingController controller;
  final int maxLength;
  final String lang;
  final VoidCallback onRetake;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    // Le viseur vit dans le corps d'un `Scaffold`, qui se redimensionne au
    // clavier et retire `viewInsets` de son `MediaQuery` : l'ajouter ici
    // n'ajoutait rien, et laissait croire que la barre s'en occupait.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.vw(4.1)),
      child: Container(
        padding: EdgeInsets.all(context.vw(4.1)),
        decoration: BoxDecoration(
          color: RyzeColors.paper,
          borderRadius: BorderRadius.circular(RyzeRadius.lg),
          boxShadow: RyzeShadow.lift,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'add_details_optional'.tr(lang),
              style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute),
            ),
            SizedBox(height: context.vw(2.1)),
            Container(
              decoration: BoxDecoration(
                color: RyzeColors.surf,
                borderRadius: BorderRadius.circular(RyzeRadius.sm),
                border: Border.all(color: RyzeColors.line),
              ),
              child: TextField(
                controller: controller,
                maxLength: maxLength,
                maxLines: 2,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: RyzeText.body(context, 3.6),
                cursorColor: RyzeColors.ink,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'note_placeholder'.tr(lang),
                  hintStyle: RyzeText.body(context, 3.6, color: RyzeColors.mute2),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: context.vw(3.6), vertical: context.vw(3.1)),
                ),
              ),
            ),
            SizedBox(height: context.vw(3.6)),
            Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: onRetake,
                    child: Container(
                      height: context.vw(13.3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: RyzeColors.surf,
                        borderRadius: BorderRadius.circular(RyzeRadius.sm),
                        border: Border.all(color: RyzeColors.line),
                      ),
                      child: Text('retake'.tr(lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                    ),
                  ),
                ),
                SizedBox(width: context.vw(3.1)),
                Expanded(
                  flex: 2,
                  child: Pressable(
                    onTap: onSend,
                    child: Container(
                      height: context.vw(13.3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: RyzeColors.ink,
                        borderRadius: BorderRadius.circular(RyzeRadius.sm),
                        boxShadow: RyzeShadow.soft,
                      ),
                      child: Text('analyze'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
