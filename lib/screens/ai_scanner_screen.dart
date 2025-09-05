import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../models/nutrition_models.dart';
import '../components/ui/nutrition_widgets.dart';

class AIScannerScreen extends StatefulWidget {
  final bool isFromDashboard;
  
  const AIScannerScreen({
    super.key,
    this.isFromDashboard = false,
  });

  @override
  State<AIScannerScreen> createState() => _AIScannerScreenState();
}

class _AIScannerScreenState extends State<AIScannerScreen> with WidgetsBindingObserver {
  bool isAnalyzing = false;
  bool hasResult = false;
  bool isCameraInitialized = false;
  bool isFlashOn = false;
  String? errorMessage;
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final ImagePicker _imagePicker = ImagePicker();
  File? _capturedImage;

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
        setState(() {
          errorMessage = 'Permission caméra requise pour scanner les aliments';
        });
        return;
      }

      // Obtenir les caméras disponibles
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          errorMessage = 'Aucune caméra disponible sur cet appareil';
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
      setState(() {
        errorMessage = 'Erreur d\'initialisation de la caméra: $e';
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
        child: hasResult ? _buildResultScreen() : _buildCameraScreen(),
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
            child: const Column(
              children: [
                Icon(
                  LucideIcons.camera,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Prenez une photo de votre plat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Assurez-vous que le plat soit bien visible et éclairé',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
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
                child: const Text(
                  'Réessayer',
                  style: TextStyle(color: Colors.white),
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
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
        });
        _analyzeImage();
      }
    } catch (e) {
      print('Erreur sélection image: $e');
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
      setState(() {
        _capturedImage = File(image.path);
      });
      
      _analyzeImage();
    } catch (e) {
      setState(() {
        isAnalyzing = false;
      });
      print('Erreur prise de photo: $e');
    }
  }

  Future<void> _analyzeImage() async {
    // Simulation de l'analyse IA (à remplacer par une vraie API)
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      isAnalyzing = false;
      hasResult = true;
    });
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
                const Expanded(
                  child: Text(
                    'Aliments détectés',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
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
            child: _capturedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _capturedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.image,
                          size: 48,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Photo analysée',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
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
                const Text(
                  'Aliments détectés :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Aliments détectés (mockés - à remplacer par vraie IA)
                _buildDetectedFood(
                  name: 'Saumon grillé',
                  confidence: 95,
                  calories: 206,
                  quantity: '150g',
                ),
                const SizedBox(height: 12),
                _buildDetectedFood(
                  name: 'Riz basmati',
                  confidence: 88,
                  calories: 130,
                  quantity: '100g',
                ),
                const SizedBox(height: 12),
                _buildDetectedFood(
                  name: 'Brocolis',
                  confidence: 92,
                  calories: 25,
                  quantity: '80g',
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
                    onPressed: () {
                      // Si on vient du dashboard, déclencher la sélection de repas
                      if (widget.isFromDashboard) {
                        // Créer un FoodItem représentant tous les aliments détectés
                        final allFoods = FoodItem(
                          name: 'Aliments détectés', // Nom générique pour tous les aliments
                          calories: 361, // Total des calories des aliments détectés (206+130+25)
                          proteins: 54.0, // Estimation basée sur les calories (15% de 361 kcal)
                          carbs: 45.0, // Estimation basée sur les calories (50% de 361 kcal)
                          fats: 13.0, // Estimation basée sur les calories (35% de 361 kcal)
                          portion: 'Plat complet',
                        );
                        
                        // Fermer l'écran actuel et ouvrir la sélection de repas
                        Navigator.pop(context);
                        _handleDashboardFoodValidation(allFoods);
                      } else {
                        // Flux normal du journal
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Aliments ajoutés au repas'),
                            backgroundColor: Color(0xFF0B132B),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ajouter tous les aliments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        hasResult = false;
                        isAnalyzing = false;
                        _capturedImage = null;
                      });
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
                    child: const Text(
                      'Reprendre une photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B132B),
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
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
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

  void _editDetectedFood(String name, int baseCalories, String currentQuantity) {
    final quantity = double.tryParse(currentQuantity.replaceAll('g', '')) ?? 100;
    final calories = (baseCalories * quantity / 100).round();
    
    // Calcul des macronutriments (valeurs approximatives basées sur les calories)
    final protein = (calories * 0.15 / 4); // 15% des calories en protéines
    final carbs = (calories * 0.55 / 4); // 55% des calories en glucides  
    final fat = (calories * 0.30 / 9); // 30% des calories en lipides

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

  void _handleDashboardFoodValidation(FoodItem foodItem) {
    // Fermer d'abord l'écran AI Scanner
    Navigator.pop(context);
    
    // Attendre un délai pour que la fermeture soit complète puis utiliser le flux spécialisé
    Future.delayed(const Duration(milliseconds: 100), () {
      if (context.mounted) {
        NutritionQuickActionsSection.showMealSelectionWithDetectedFood(context, foodItem);
      }
    });
  }
}