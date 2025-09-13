import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../models/nutrition_models.dart';
import '../services/gemini_analysis_service.dart';
import '../services/gemini_analysis_service_v2.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../models/ai_analysis_models.dart';
import '../services/food_entries_service.dart';
import '../services/auth_service.dart';

class AIScannerScreen extends StatefulWidget {
  final bool isFromDashboard;
  final String? mealName; // Pour flux depuis journal
  final String? mealId;   // Pour flux depuis journal
  
  const AIScannerScreen({
    super.key,
    this.isFromDashboard = false,
    this.mealName,
    this.mealId,
  });

  @override
  State<AIScannerScreen> createState() => _AIScannerScreenState();
}

class _AIScannerScreenState extends State<AIScannerScreen> with WidgetsBindingObserver {
  bool isAnalyzing = false;
  bool hasResult = false;
  bool isCameraInitialized = false;
  bool isFlashOn = false;
  bool showNoteInput = false;
  String? errorMessage;
  AIAnalysisResult? _analysisResult;
  String _aiNote = '';
  
  // Contrôleur pour le nom de l'aliment modifiable
  final TextEditingController _mealNameController = TextEditingController();
  // Contrôleur pour la note IA
  final TextEditingController _noteController = TextEditingController();
  
  static const int maxNoteLength = 140;
  
  // Animation de chargement IA
  int _loadingPhase = 0;
  
  List<String> _getLoadingPhases(String languageCode) {
    return [
      'ai_analysis_phases_0'.tr(languageCode),
      'ai_analysis_phases_1'.tr(languageCode),
      'ai_analysis_phases_2'.tr(languageCode),
      'ai_analysis_phases_3'.tr(languageCode),
      'ai_analysis_phases_4'.tr(languageCode),
    ];
  }
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final ImagePicker _imagePicker = ImagePicker();
  File? _capturedImage;
  Uint8List? _capturedImageBytes; // Pour l'affichage web

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _mealNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Vérifier les permissions
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        setState(() {
          errorMessage = 'camera_permission_food_scan'.tr(locService.currentLanguageCode);
        });
        return;
      }

      // Obtenir les caméras disponibles
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        setState(() {
          errorMessage = 'no_camera_available'.tr(locService.currentLanguageCode);
        });
        return;
      }

      // Initialiser le contrôleur de caméra avec la caméra arrière
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      setState(() {
        isCameraInitialized = true;
        errorMessage = null;
      });
    } catch (e) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      setState(() {
        errorMessage = 'camera_initialization_error'.tr(locService.currentLanguageCode) + ': $e';
        isCameraInitialized = false;
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    
    try {
      setState(() {
        isFlashOn = !isFlashOn;
      });
      
      await _cameraController!.setFlashMode(
        isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      print('Erreur toggle flash: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: hasResult 
            ? _buildResultScreen() 
            : isAnalyzing 
                ? _buildAILoadingScreen() 
                : Stack(
                    children: [
                      _buildCameraScreen(),
                      if (showNoteInput) _buildNoteInputOverlay(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Stack(
      children: [
        // Vue caméra ou message d'erreur
        if (errorMessage != null)
          _buildErrorView()
        else if (isCameraInitialized && _cameraController != null)
          _buildCameraPreview()
        else
          _buildLoadingView(),
        
        // Header
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    LucideIcons.chevronLeft,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _toggleFlash,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    isFlashOn ? LucideIcons.flashlight : LucideIcons.flashlightOff,
                    color: isFlashOn ? Colors.yellow : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Instructions
        Positioned(
          top: 100,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.camera,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'take_photo'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'make_sure_dish_visible'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Boutons de capture
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Bouton galerie
              GestureDetector(
                onTap: _pickImageFromGallery,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    LucideIcons.image,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              
              // Bouton capture principal
              GestureDetector(
                onTap: isCameraInitialized && !isAnalyzing ? _takePicture : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isAnalyzing ? Colors.grey : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: isAnalyzing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0B132B),
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(
                          LucideIcons.camera,
                          color: Colors.black,
                          size: 32,
                        ),
                ),
              ),
              
              // Bouton switch caméra
              GestureDetector(
                onTap: _switchCamera,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    LucideIcons.rotateCw,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Initialisation de la caméra...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.cameraOff,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    locService.currentLanguageCode == 'fr' ? 'Réessayer' : 'Try again',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    try {
      await _cameraController?.dispose();
      
      final currentCamera = _cameraController?.description;
      final newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection != currentCamera?.lensDirection,
        orElse: () => _cameras!.first,
      );
      
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      print('Erreur changement de caméra: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Sur web, on affiche un debug message pour comprendre le problème
      if (kIsWeb) {
        print('🌐 Tentative de sélection d\'image sur web...');
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      print('📷 Image sélectionnée: ${image?.path ?? "aucune"}');
      
      if (image != null) {
        if (kIsWeb) {
          // Sur web, on utilise directement l'objet XFile
          print('🌐 Traitement image web: ${image.name}, taille: ${await image.length()} bytes');
          
          // Lire les bytes pour l'analyse et l'affichage
          final bytes = await image.readAsBytes();
          print('📊 Bytes lus: ${bytes.length}');
          
          // Sauvegarder pour l'affichage web
          setState(() {
            _capturedImage = File(image.path); // Garde pour compatibilité
            _capturedImageBytes = Uint8List.fromList(bytes); // Pour l'affichage web
          });
          
          // Sauvegarder les bytes pour l'analyse après la note
          _capturedImageBytes = bytes;
          _showNoteInputOverlay();
        } else {
          // Sur mobile, utilisation normale
          print('📱 Traitement image mobile: ${image.path}');
          setState(() {
            _capturedImage = File(image.path);
          });
          _showNoteInputOverlay();
        }
      } else {
        print('❌ Aucune image sélectionnée');
        _showErrorSnackbar('Aucune image sélectionnée');
      }
    } catch (e) {
      print('❌ Erreur sélection image: $e');
      _showErrorSnackbar('Erreur lors de la sélection: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        isAnalyzing = true;
      });

      final XFile image = await _cameraController!.takePicture();
      
      if (kIsWeb) {
        // Sur web, sauvegarder aussi les bytes
        final bytes = await image.readAsBytes();
        setState(() {
          _capturedImage = File(image.path);
          _capturedImageBytes = Uint8List.fromList(bytes);
        });
        _capturedImageBytes = bytes;
      } else {
        // Sur mobile
        setState(() {
          _capturedImage = File(image.path);
          _capturedImageBytes = null;
        });
      }
      _showNoteInputOverlay();
    } catch (e) {
      setState(() {
        isAnalyzing = false;
      });
      print('Erreur prise de photo: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_capturedImage == null) return;

    try {
      if (mounted) {
        setState(() {
          _loadingPhase = 0;
        });
      }

      // Démarrer l'animation de chargement
      _startLoadingAnimation();

      // Validate image file first
      final validationError = await GeminiAnalysisService.validateImageFile(_capturedImage!);
      if (validationError != null) {
        if (mounted) {
          setState(() {
            isAnalyzing = false;
            errorMessage = validationError;
          });
        }
        return;
      }

      // Analyze image with Gemini service (with fallback to mock data)
      final result = await GeminiAnalysisService.analyzeImageWithFallback(_capturedImage!);
      
      if (mounted) {
        setState(() {
          isAnalyzing = false;
          _analysisResult = result;
          
          if (result.success && result.detectedFoods.isNotEmpty) {
            hasResult = true;
            errorMessage = null;
            // Mettre à jour le nom du repas avec le nom généré par l'IA
            final locService = Provider.of<LocalizationService>(context, listen: false);
            _mealNameController.text = result.mealName ?? 'ai_detected_dish'.tr(locService.currentLanguageCode);
          } else {
            hasResult = false;
            errorMessage = result.error?.contains('API') == true 
                ? 'ai_service_overloaded'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode)
                : 'Aucun aliment détecté dans cette image';
          }
        });
      }

    } catch (e) {
      setState(() {
        isAnalyzing = false;
        hasResult = false;
        errorMessage = 'Erreur lors de l\'analyse: $e';
      });
    }
  }

  /// Écran de chargement IA animé avec phases
  Widget _buildAILoadingScreen() {
    return Container(
      color: const Color(0xFF0B132B),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isAnalyzing = false;
                      hasResult = false;
                      _capturedImage = null;
                      _capturedImageBytes = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white24,
                    ),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      'ai_analysis_in_progress'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Robot IA animé
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1500),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Icon(
                            LucideIcons.brain,
                            size: 64,
                            color: Colors.white.withOpacity(0.8 + (0.2 * value)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Phase actuelle
                Consumer<LocalizationService>(
                  builder: (context, locService, child) {
                    final loadingPhases = _getLoadingPhases(locService.currentLanguageCode);
                    return Text(
                      _loadingPhase < loadingPhases.length 
                          ? loadingPhases[_loadingPhase]
                          : (locService.currentLanguageCode == 'fr' ? 'Finalisation...' : 'Finalizing...'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Indicateur de progression avec phases
                Container(
                  width: 280,
                  child: Column(
                    children: List.generate(_getLoadingPhases(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode).length, (index) {
                      final isCompleted = index < _loadingPhase;
                      final isCurrent = index == _loadingPhase;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            // Cercle de progression
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCompleted 
                                    ? const Color(0xFF0B132B) 
                                    : Colors.white24,
                                shape: BoxShape.circle,
                                border: isCurrent ? Border.all(
                                  color: const Color(0xFF0B132B),
                                  width: 2,
                                ) : null,
                              ),
                              child: isCompleted 
                                  ? const Icon(
                                      Icons.circle,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : isCurrent 
                                      ? Container(
                                          margin: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF0B132B),
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            // Texte de la phase
                            Expanded(
                              child: Consumer<LocalizationService>(
                                builder: (context, locService, child) {
                                  final loadingPhases = _getLoadingPhases(locService.currentLanguageCode);
                                  return Text(
                                    loadingPhases[index],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isCompleted 
                                          ? Colors.white
                                          : isCurrent 
                                              ? Colors.white
                                              : Colors.white54,
                                      fontWeight: isCompleted || isCurrent ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Barre de progression globale
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: (_loadingPhase + 1) / _getLoadingPhases(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode).length,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF0B132B), const Color(0xFF1A1A2E)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    '${((_loadingPhase + 1) / _getLoadingPhases(locService.currentLanguageCode).length * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' ? 'Aliments détectés' : 'Detected foods',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Nom du plat modifiable (visible seulement quand on a un résultat)
          if (hasResult && _analysisResult != null && _analysisResult!.success)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' ? 'Nom du plat' : 'Dish name',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mealNameController,
                    decoration: InputDecoration(
                      hintText: 'ai_detected_dish_name'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.pencil, size: 16),
                        onPressed: () {
                          // Focus sur le champ pour édition
                          FocusScope.of(context).requestFocus();
                        },
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          
          // Photo analysée
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: _capturedImage != null || _capturedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb && _capturedImageBytes != null
                        ? Image.memory(
                            _capturedImageBytes!,
                            fit: BoxFit.cover,
                          )
                        : _capturedImage != null
                            ? Image.file(
                                _capturedImage!,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.image,
                          size: 48,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(height: 8),
                        Consumer<LocalizationService>(
                          builder: (context, locService, child) => Text(
                            'analyzed_photo'.tr(locService.currentLanguageCode),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Résultats de l'analyse
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    locService.currentLanguageCode == 'fr' ? 'Aliments détectés :' : 'Detected foods:',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Aliments détectés via IA
                if (_analysisResult != null && _analysisResult!.success)
                  ...(_analysisResult!.detectedFoods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final food = entry.value;
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        _buildDetectedFood(
                          name: food.name,
                          confidence: (food.confidence * 100).round(),
                          calories: food.calories,
                          quantity: '${food.estimatedQuantity.round()}g',
                        ),
                      ],
                    );
                  }).toList())
                else
                  Center(
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        locService.currentLanguageCode == 'fr' ? 'Aucun aliment détecté' : 'No food detected',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_analysisResult == null || !_analysisResult!.success || _analysisResult!.detectedFoods.isEmpty) {
                        return;
                      }

                      // Si on vient du dashboard, déclencher la sélection de repas
                      if (widget.mealName != null && widget.mealId != null) {
                        // Flux depuis le journal - ajouter directement au repas sélectionné
                        await _addFoodsToSpecificMeal(widget.mealName!, widget.mealId!);
                      } else if (widget.isFromDashboard) {
                        // Flux depuis le dashboard - demander la sélection du repas
                        await _addFoodsToJournalWithSelection();
                      } else {
                        // Flux normal du scanner - demander la sélection du repas
                        await _addFoodsToJournalWithSelection();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        locService.currentLanguageCode == 'fr' ? 'Ajouter tous les aliments' : 'Add all foods',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          hasResult = false;
                          isAnalyzing = false;
                          showNoteInput = false;
                          _capturedImage = null;
                          _capturedImageBytes = null;
                          _analysisResult = null;
                          _mealNameController.clear();
                          _noteController.clear();
                          _aiNote = '';
                          errorMessage = null;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Color(0xFF0B132B),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        locService.currentLanguageCode == 'fr' ? 'Reprendre une photo' : 'Take another photo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedFood({
    required String name,
    required int confidence,
    required int calories,
    required String quantity,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: confidence >= 90
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$confidence%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: confidence >= 90
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFCA8A04),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$calories kcal • $quantity',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _editDetectedFood(name, calories, quantity),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
              ),
              child: const Icon(
                LucideIcons.pencil,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editDetectedFood(String name, int calories, String currentQuantity) {
    final quantity = double.tryParse(currentQuantity.replaceAll('g', '')) ?? 100;
    
    // Trouver l'aliment correspondant dans les résultats pour avoir les vraies macros
    DetectedFood? matchedFood;
    if (_analysisResult != null && _analysisResult!.success) {
      try {
        matchedFood = _analysisResult!.detectedFoods.firstWhere((food) => food.name == name);
      } catch (e) {
        // Aliment non trouvé, utiliser des valeurs par défaut
      }
    }
    
    // Utiliser les macros de l'IA ou des valeurs approximatives
    final protein = matchedFood?.nutrition.proteins ?? (calories * 0.15 / 4);
    final carbs = matchedFood?.nutrition.carbs ?? (calories * 0.55 / 4);  
    final fat = matchedFood?.nutrition.fats ?? (calories * 0.30 / 9);

    EditableFoodDetailsBottomSheet.show(
      context,
      name: name,
      calories: calories,
      proteins: protein,
      glucides: carbs,
      lipides: fat,
      quantity: quantity,
      isModified: false,
      // Utiliser onFoodSaved au lieu de onFoodAdded pour juste enregistrer les modifications
      onFoodSaved: (foodItem) {
        // Ne rien faire - l'aliment est juste enregistré, pas ajouté au repas
        // L'ajout se fera via le bouton "Ajouter tous les aliments"
        print('Aliment ${foodItem.name} enregistré avec modifications');
      },
    );
  }


  /// Ajouter tous les aliments détectés à un repas spécifique (flux depuis journal)
  Future<void> _addFoodsToSpecificMeal(String mealName, String mealId) async {
    if (_analysisResult == null || !_analysisResult!.success || _analysisResult!.detectedFoods.isEmpty) {
      return;
    }

    try {
      // Obtenir l'utilisateur connecté
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: utilisateur non connecté'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
        return;
      }

      // Ajouter directement au repas comme un seul aliment personnalisé
      final success = await FoodEntriesService.addAIFoodEntry(
        userId: user.id,
        mealName: mealName,
        detectedFoods: _analysisResult!.detectedFoods,
        aiMealName: _mealNameController.text.isNotEmpty ? _mealNameController.text : 'Plat détecté par IA',
        consumedAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.pop(context);
        
        if (success) {
          final locService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_analysisResult!.mealName ?? "ai_dish".tr(locService.currentLanguageCode)} ajouté au $mealName'),
              backgroundColor: const Color(0xFF0B132B),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }

    } catch (e) {
      print('Erreur lors de l\'ajout au repas spécifique: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout au repas'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// Ajouter tous les aliments détectés avec sélection de repas
  Future<void> _addFoodsToJournalWithSelection() async {
    if (_analysisResult == null || !_analysisResult!.success || _analysisResult!.detectedFoods.isEmpty) {
      return;
    }

    try {
      // Obtenir l'utilisateur connecté
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: utilisateur non connecté'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
        return;
      }

      // Récupérer les repas existants pour aujourd'hui
      final allMeals = await FoodEntriesService.getFoodEntriesForDate(user.id, DateTime.now());
      
      // Filtrer seulement les repas qui ont des aliments (vrais repas existants)
      final existingMeals = allMeals.where((meal) => meal.items.isNotEmpty).toList();
      
      print('🍽️ Repas trouvés au total: ${allMeals.length}');
      print('🍽️ Repas avec aliments: ${existingMeals.length}');
      
      // Utiliser le widget de sélection de repas existant
      MealSelectionBottomSheet.show(
        context,
        foodName: _mealNameController.text.isNotEmpty ? _mealNameController.text : '${_analysisResult!.detectedFoods.length} aliment(s) détecté(s)',
        existingMeals: existingMeals,
        onExistingMealSelected: (Meal selectedMeal) async {
          await _addAIFoodToExistingMeal(selectedMeal, user.id);
        },
        onCreateNewMeal: () {
          NewMealTypeBottomSheet.show(
            context,
            onMealTypeSelected: (String mealType, String time) async {
              await _addAIFoodToNewMeal(mealType, user.id);
            },
          );
        },
      );

    } catch (e) {
      print('Erreur lors de l\'affichage de la sélection de repas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'affichage de la sélection de repas'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// Ajouter l'aliment IA à un repas existant
  Future<void> _addAIFoodToExistingMeal(Meal selectedMeal, String userId) async {
    try {
      final success = await FoodEntriesService.addAIFoodEntry(
        userId: userId,
        mealName: selectedMeal.name,
        detectedFoods: _analysisResult!.detectedFoods,
        aiMealName: _mealNameController.text.isNotEmpty ? _mealNameController.text : 'Plat détecté par IA',
        consumedAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.pop(context);
        
        if (success) {
          final locService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_analysisResult!.mealName ?? "ai_dish".tr(locService.currentLanguageCode)} ajouté au ${selectedMeal.name}'),
              backgroundColor: const Color(0xFF0B132B),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
      
    } catch (e) {
      print('Erreur lors de l\'ajout au repas existant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout au repas'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// Ajouter l'aliment IA à un nouveau repas
  Future<void> _addAIFoodToNewMeal(String mealType, String userId) async {
    try {
      final success = await FoodEntriesService.addAIFoodEntry(
        userId: userId,
        mealName: mealType,
        detectedFoods: _analysisResult!.detectedFoods,
        aiMealName: _mealNameController.text.isNotEmpty ? _mealNameController.text : 'Plat détecté par IA',
        consumedAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.pop(context);
        
        if (success) {
          final locService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_analysisResult!.mealName ?? "ai_dish".tr(locService.currentLanguageCode)} ajouté au $mealType'),
              backgroundColor: const Color(0xFF0B132B),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
      
    } catch (e) {
      print('Erreur lors de l\'ajout au nouveau repas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout au nouveau repas'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }


  /// Démarrer l'animation de chargement avec phases
  void _startLoadingAnimation() async {
    setState(() {
      _loadingPhase = 0;
    });
    
    // Avancer les phases automatiquement
    final locService = Provider.of<LocalizationService>(context, listen: false);
    for (int i = 0; i < _getLoadingPhases(locService.currentLanguageCode).length; i++) {
      if (mounted && isAnalyzing) {
        setState(() {
          _loadingPhase = i;
        });
        await Future.delayed(Duration(milliseconds: i == 0 ? 300 : 800)); // Premier délai plus court
      }
    }
  }

  /// Analyser une image à partir de bytes (pour le web)
  Future<void> _analyzeImageFromBytes(List<int> bytes) async {
    try {
      if (mounted) {
        setState(() {
          isAnalyzing = true;
          hasResult = false;
          errorMessage = null;
          _loadingPhase = 0;
        });
      }

      print('🔍 Début analyse image web: ${bytes.length} bytes');

      // Démarrer l'animation de chargement
      _startLoadingAnimation();

      // Convertir en Uint8List et analyser directement
      final Uint8List imageBytes = Uint8List.fromList(bytes);
      
      // Analyze image directly from bytes (Web compatible)
      final result = await GeminiAnalysisService.analyzeImageFromBytes(imageBytes);
      
      print('🤖 Résultat analyse: success=${result.success}, aliments=${result.detectedFoods.length}');
      
      if (mounted) {
        setState(() {
          isAnalyzing = false;
          _analysisResult = result;
          
          if (result.success && result.detectedFoods.isNotEmpty) {
            hasResult = true;
            errorMessage = null;
            // Mettre à jour le nom du repas avec le nom généré par l'IA
            final locService = Provider.of<LocalizationService>(context, listen: false);
            _mealNameController.text = result.mealName ?? 'ai_detected_dish'.tr(locService.currentLanguageCode);
          } else {
            hasResult = false;
            errorMessage = result.error?.contains('API') == true 
                ? 'ai_service_overloaded'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode)
                : 'Aucun aliment détecté dans cette image';
          }
        });
      }

    } catch (e) {
      print('❌ Erreur analyse image web: $e');
      if (mounted) {
        setState(() {
          isAnalyzing = false;
          hasResult = false;
          errorMessage = 'Le service IA est temporairement surchargé.\nMerci de réessayer dans quelques minutes.';
        });
      }
    }
  }

  /// Afficher l'overlay de saisie de note
  void _showNoteInputOverlay() {
    setState(() {
      showNoteInput = true;
    });
  }

  /// Construire l'overlay de saisie de note
  Widget _buildNoteInputOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titre
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'add_note_for_ai'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'describe_dish_for_accuracy'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Champ de saisie
                TextField(
                  controller: _noteController,
                  maxLength: maxNoteLength,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ex: Assiette de saumon 150g avec quinoa et haricots verts',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Boutons
                Row(
                  children: [
                    // Bouton Ignorer
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _skipNote,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, child) => Text(
                            'skip'.tr(locService.currentLanguageCode),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton Analyser
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _analyzeWithNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, child) => Text(
                            'analyze'.tr(locService.currentLanguageCode),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ignorer la saisie de note et procéder à l'analyse
  void _skipNote() {
    setState(() {
      showNoteInput = false;
      _aiNote = '';
      _noteController.clear();
    });
    _startAnalysis();
  }

  /// Analyser avec la note utilisateur
  void _analyzeWithNote() {
    setState(() {
      _aiNote = _noteController.text.trim();
      showNoteInput = false;
    });
    _startAnalysis();
  }

  /// Démarrer l'analyse avec ou sans note
  void _startAnalysis() {
    setState(() {
      isAnalyzing = true;
    });
    
    if (kIsWeb && _capturedImageBytes != null) {
      _analyzeImageFromBytesWithNote(_capturedImageBytes!);
    } else if (_capturedImage != null) {
      _analyzeImageWithNote();
    }
  }

  /// Analyser image avec note utilisateur
  Future<void> _analyzeImageWithNote() async {
    if (_capturedImage == null) return;

    try {
      if (mounted) {
        setState(() {
          _loadingPhase = 0;
        });
      }

      // Démarrer l'animation de chargement
      _startLoadingAnimation();

      // Validate image file first
      final validationError = await GeminiAnalysisServiceV2.validateImageFile(_capturedImage!);
      if (validationError != null) {
        if (mounted) {
          setState(() {
            isAnalyzing = false;
            errorMessage = validationError;
          });
        }
        return;
      }

      // Analyze image with Gemini service V2 (with user note)
      final result = await GeminiAnalysisServiceV2.analyzeImageWithFallback(
        _capturedImage!,
        userNote: _aiNote.isNotEmpty ? _aiNote : null,
      );
      
      if (mounted) {
        setState(() {
          isAnalyzing = false;
          _analysisResult = result;
          
          if (result.success && result.detectedFoods.isNotEmpty) {
            hasResult = true;
            errorMessage = null;
            // Mettre à jour le nom du repas avec le nom généré par l'IA
            final locService = Provider.of<LocalizationService>(context, listen: false);
            _mealNameController.text = result.mealName ?? 'ai_detected_dish'.tr(locService.currentLanguageCode);
          } else {
            hasResult = false;
            errorMessage = result.error?.contains('API') == true 
                ? 'ai_service_overloaded'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode)
                : 'Aucun aliment détecté dans cette image';
          }
        });
      }

    } catch (e) {
      setState(() {
        isAnalyzing = false;
        hasResult = false;
        errorMessage = 'Erreur lors de l\'analyse: $e';
      });
    }
  }

  /// Analyser image depuis bytes avec note utilisateur (pour web)
  Future<void> _analyzeImageFromBytesWithNote(List<int> bytes) async {
    try {
      if (mounted) {
        setState(() {
          isAnalyzing = true;
          hasResult = false;
          errorMessage = null;
          _loadingPhase = 0;
        });
      }

      print('🔍 Début analyse image web avec note: "${_aiNote}"');

      // Démarrer l'animation de chargement
      _startLoadingAnimation();

      // Convertir en Uint8List et analyser directement avec note
      final Uint8List imageBytes = Uint8List.fromList(bytes);
      
      // Analyze image directly from bytes with user note (Web compatible)
      final result = await GeminiAnalysisServiceV2.analyzeImageFromBytes(
        imageBytes,
        userNote: _aiNote.isNotEmpty ? _aiNote : null,
      );
      
      print('🤖 Résultat analyse avec note: success=${result.success}, aliments=${result.detectedFoods.length}');
      
      if (mounted) {
        setState(() {
          isAnalyzing = false;
          _analysisResult = result;
          
          if (result.success && result.detectedFoods.isNotEmpty) {
            hasResult = true;
            errorMessage = null;
            // Mettre à jour le nom du repas avec le nom généré par l'IA
            final locService = Provider.of<LocalizationService>(context, listen: false);
            _mealNameController.text = result.mealName ?? 'ai_detected_dish'.tr(locService.currentLanguageCode);
          } else {
            hasResult = false;
            errorMessage = result.error?.contains('API') == true 
                ? 'ai_service_overloaded'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode)
                : 'Aucun aliment détecté dans cette image';
          }
        });
      }

    } catch (e) {
      print('❌ Erreur analyse image web avec note: $e');
      if (mounted) {
        setState(() {
          isAnalyzing = false;
          hasResult = false;
          errorMessage = 'Le service IA est temporairement surchargé.\nMerci de réessayer dans quelques minutes.';
        });
      }
    }
  }

  /// Afficher un message d'erreur
  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}