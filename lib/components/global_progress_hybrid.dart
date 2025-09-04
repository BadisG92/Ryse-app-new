import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'ui/global_progress_models.dart';
import 'ui/global_progress_widgets.dart';
import '../services/dashboard_service.dart';
import '../services/progress_service.dart';
import '../providers/goals_notifier.dart';

class GlobalProgress extends StatefulWidget {
  const GlobalProgress({super.key});

  @override
  State<GlobalProgress> createState() => _GlobalProgressState();
}

class _GlobalProgressState extends State<GlobalProgress> {
  
  // État des données (chargées depuis ProgressService)
  WeightProgress _weightProgress = GlobalProgressData.weightProgress;
  WeeklyBalance _weeklyBalance = GlobalProgressData.weeklyBalance;
  List<TrackingDay> _trackingDays = GlobalProgressData.weeklyTracking;
  HeaderStats _headerStats = GlobalProgressData.headerStats;
  List<AIRecommendation> _aiRecommendations = GlobalProgressData.aiRecommendations;
  int _completedGoals = 0;
  int _totalGoals = 0;
  bool _loadingObjectives = true;
  bool _loadingProgress = true;
  String get _objectivesText => _loadingObjectives ? '...' : '$_completedGoals/$_totalGoals objectifs';

  @override
  void initState() {
    super.initState();
    _loadObjectives();
    _loadProgressData();
    // Forcer la mise à jour du compteur d'objectifs
    DashboardService.refreshGoalsNotifier();
  }

  Future<void> _loadObjectives() async {
    try {
      final goals = await DashboardService.getDailyGoals();
      final completed = goals.where((g) => g.completed).length;
      setState(() {
        _completedGoals = completed;
        _totalGoals = goals.length;
        _loadingObjectives = false;
      });
    } catch (e) {
      setState(() => _loadingObjectives = false);
    }
  }

  Future<void> _loadProgressData() async {
    try {
      print('🔄 Chargement des données de progression depuis ProgressService...');
      
      // Charger toutes les données en parallèle
      final results = await Future.wait([
        ProgressService.getWeeklyBalance(),
        ProgressService.getWeeklyTracking(),
        ProgressService.getHeaderStats(),
        ProgressService.getAIRecommendations(),
      ]);
      
      setState(() {
        _weeklyBalance = results[0] as WeeklyBalance;
        _trackingDays = results[1] as List<TrackingDay>;
        _headerStats = results[2] as HeaderStats;
        _aiRecommendations = results[3] as List<AIRecommendation>;
        _loadingProgress = false;
      });
      
      print('✅ Données de progression chargées:');
      print('   - Bilan hebdomadaire: ${_weeklyBalance.items.length} items');
      print('   - Tracking: ${_trackingDays.length} jours');
      print('   - Recommandations IA: ${_aiRecommendations.length} items');
      
      // Debug du bilan hebdomadaire
      for (final item in _weeklyBalance.items) {
        print('   - ${item.label}: ${item.achieved}/${item.target} ${item.unit}');
      }
      
    } catch (e) {
      print('❌ Erreur lors du chargement des données de progression: $e');
      setState(() => _loadingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec bandeau identique aux pages sport/nutrition
            _buildHeader(),
            
            // Corps principal avec scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Section d'évolution du poids avec graphique
                    GlobalProgressSectionBuilder.buildWeightSection(
                      _weightProgress,
                      _onEditWeight,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Section du bilan global hebdomadaire
                    _loadingProgress 
                      ? _buildLoadingSection() 
                      : GlobalProgressSectionBuilder.buildBalanceSection(_weeklyBalance),
                    
                    const SizedBox(height: 16),
                    
                    // Section de tracking hebdomadaire (nutrition + sport)
                    _loadingProgress 
                      ? _buildLoadingSection() 
                      : GlobalProgressSectionBuilder.buildTrackingSection(_trackingDays),
                    
                    const SizedBox(height: 16),
                    
                    // Section des recommandations IA
                    _loadingProgress 
                      ? _buildLoadingSection() 
                      : GlobalProgressSectionBuilder.buildAISection(_aiRecommendations),
                    
                    // Espace en bas pour éviter que le contenu soit coupé
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bandeau streak/XP remplace le titre
          Container(
            width: double.infinity,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBannerItem(LucideIcons.flame, _headerStats.dailyStreak),
                _buildBannerSeparator(),
                ValueListenableBuilder<GoalsSummary>(
                  valueListenable: GoalsNotifier.instance,
                  builder: (context, summary, _) {
                    return _buildBannerItem(LucideIcons.target, summary.toString());
                  },
                ),
                _buildBannerSeparator(),
                _buildBannerItemWithLogo(_headerStats.currentStatus),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBannerItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBannerSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('•', style: TextStyle(color: Colors.white60, fontSize: 14)),
    );
  }

  Widget _buildBannerItemWithLogo(String text) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/logo_seul.svg',
          width: 16,
          height: 16,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  // Action d'édition du poids (garde l'intégration)
  void _onEditWeight() {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWeightEditBottomSheet(),
    );
  }

  // Bottom sheet d'édition du poids (garde l'intégration)
  Widget _buildWeightEditBottomSheet() {
    double currentWeight = _weightProgress.currentWeight;
    final TextEditingController weightController = 
        TextEditingController(text: currentWeight.toStringAsFixed(1));

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle pour fermer
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // En-tête
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Modifier le poids',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          
          // Formulaire de poids
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Champ de saisie
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Poids actuel (kg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0B132B)),
                      ),
                    ),
                    onChanged: (value) {
                      final parsedWeight = double.tryParse(value);
                      if (parsedWeight != null) {
                        currentWeight = parsedWeight;
                      }
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Informations contextuelles
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Poids initial : ${_weightProgress.initialWeight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          'Objectif : ${_weightProgress.targetWeight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Bouton de sauvegarde
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateWeight(currentWeight);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B132B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mise à jour du poids (garde l'intégration)
  void _updateWeight(double newWeight) {
    HapticFeedback.lightImpact();
    
    setState(() {
      // Créer une nouvelle entrée de poids
      final newEntry = WeightEntry(
        date: DateTime.now(),
        weight: newWeight,
      );

      // Mettre à jour la progression de poids
      final updatedEntries = List<WeightEntry>.from(_weightProgress.entries)
        ..add(newEntry);

      _weightProgress = WeightProgress(
        currentWeight: newWeight,
        previousWeight: _weightProgress.currentWeight, // L'ancien devient le précédent
        initialWeight: _weightProgress.initialWeight,
        targetWeight: _weightProgress.targetWeight,
        entries: updatedEntries,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Poids mis à jour : ${newWeight.toStringAsFixed(1)} kg'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF0B132B),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des données...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 
