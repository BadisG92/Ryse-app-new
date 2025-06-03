import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';

class SportCardio extends StatelessWidget {
  const SportCardio({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Bloc "Cette semaine" avec statistiques
            _buildWeeklyStats(),
            
            const SizedBox(height: 16),
            
            // 2. Bloc "Choisir une activité"
            _buildSessionFormats(context),
            
            const SizedBox(height: 16),
            
            // 3. Bloc "Dernière séance enregistrée"
            _buildLastSession(),
            
            const SizedBox(height: 16),
            
            // 4. Bloc "Vos séances de la semaine"
            _buildWeekSessions(),
            
            const SizedBox(height: 16),
            
            // 5. Footer / CTA
            _buildHistoryAccess(context),
            
            // Padding bottom pour éviter la coupure
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStats() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette semaine',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildWeeklyCard(
                    title: '90.5 km',
                    subtitle: 'Distance',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWeeklyCard(
                    title: '10h40',
                    subtitle: 'Temps',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWeeklyCard(
                    title: '1860',
                    subtitle: 'Calories',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCard({
    required String title,
    required String subtitle,
  }) {
    // Formatage intelligent pour les distances > 100 km
    String displayTitle = title;
    if (subtitle == 'Distance' && title.contains('km')) {
      final numericPart = title.replaceAll(' km', '');
      final distance = double.tryParse(numericPart);
      if (distance != null && distance >= 100) {
        displayTitle = '${distance.round()} km';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionFormats(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisir une activité',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildActivityCard(
                  icon: LucideIcons.activity,
                  title: 'Course à pied',
                  activityType: 'running',
                  context: context,
                ),
                _buildActivityCard(
                  icon: LucideIcons.bike,
                  title: 'Vélo',
                  activityType: 'bike',
                  context: context,
                ),
                _buildActivityCard(
                  icon: LucideIcons.footprints,
                  title: 'Marche',
                  activityType: 'walking',
                  context: context,
                ),
                _buildActivityCard(
                  icon: LucideIcons.flame,
                  title: 'HIIT',
                  activityType: 'hiit',
                  context: context,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String activityType,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () => _showActivityFormatsModal(context, activityType, title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Données des formats pour chaque activité
  Map<String, List<Map<String, dynamic>>> get activityFormats => {
    'running': [
      {'icon': LucideIcons.activity, 'title': 'Course libre', 'description': 'Séance libre sans contrainte', 'trackable': true, 'configurable': false},
      {'icon': LucideIcons.target, 'title': 'Objectif distance', 'description': 'Atteindre une distance que tu définis', 'trackable': true, 'configurable': true, 'configType': 'distance'},
      {'icon': LucideIcons.clock, 'title': 'Objectif durée', 'description': 'Courir pendant une durée que tu choisis', 'trackable': true, 'configurable': true, 'configType': 'duration'},
      {'icon': LucideIcons.zap, 'title': 'Fractionné débutant', 'description': '4x 1min rapide / 2min récup', 'trackable': true, 'configurable': false},
      {'icon': LucideIcons.flame, 'title': 'Fractionné avancé', 'description': '6x 2min rapide / 1min récup', 'trackable': true, 'configurable': false},
    ],
    'bike': [
      {'icon': LucideIcons.bike, 'title': 'Vélo libre', 'description': 'Sortie vélo libre', 'trackable': true, 'configurable': false},
      {'icon': LucideIcons.target, 'title': 'Objectif distance', 'description': 'Distance à atteindre que tu définis', 'trackable': true, 'configurable': true, 'configType': 'distance'},
      {'icon': LucideIcons.clock, 'title': 'Objectif durée', 'description': 'Durée que tu choisis', 'trackable': true, 'configurable': true, 'configType': 'duration'},
      {'icon': LucideIcons.mountain, 'title': 'Côtes', 'description': 'Entraînement en dénivelé', 'trackable': true, 'configurable': false},
    ],
    'walking': [
      {'icon': LucideIcons.footprints, 'title': 'Marche libre', 'description': 'Promenade libre', 'trackable': true, 'configurable': false},
      {'icon': LucideIcons.target, 'title': 'Objectif distance', 'description': 'Distance à parcourir que tu définis', 'trackable': true, 'configurable': true, 'configType': 'distance'},
      {'icon': LucideIcons.clock, 'title': 'Objectif durée', 'description': 'Durée que tu choisis', 'trackable': true, 'configurable': true, 'configType': 'duration'},
      {'icon': LucideIcons.trendingUp, 'title': 'Marche rapide', 'description': 'Allure soutenue', 'trackable': true, 'configurable': false},
    ],
    'hiit': [
      {'icon': LucideIcons.flame, 'title': 'HIIT débutant', 'description': '15 min - 30s effort / 30s repos', 'trackable': false, 'configurable': false},
      {'icon': LucideIcons.zap, 'title': 'HIIT intense', 'description': '20 min - 45s effort / 15s repos', 'trackable': false, 'configurable': false},
      {'icon': LucideIcons.target, 'title': 'Tabata', 'description': '4 min - 20s effort / 10s repos', 'trackable': false, 'configurable': false},
      {'icon': LucideIcons.timer, 'title': 'HIIT personnalisé', 'description': 'Créer son propre timing', 'trackable': false, 'configurable': true, 'configType': 'hiit'},
    ],
  };

  void _showActivityFormatsModal(BuildContext context, String activityType, String activityTitle) {
    final formats = activityFormats[activityType] ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              
              const SizedBox(height: 24),
              
              Text(
                'Choisir un format de séance',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              Text(
                activityTitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Formats pour cette activité
              ...formats.map((format) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildModalFormat(
                  icon: format['icon'],
                  title: format['title'],
                  description: format['description'],
                  onTap: () {
                    Navigator.pop(context);
                    if (format['configurable'] == true) {
                      _showConfigurationModal(context, format, activityTitle);
                    } else {
                      _showRecordingChoiceModal(context, format['title'], format['trackable']);
                    }
                  },
                ),
              )).toList(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfigurationModal(BuildContext context, Map<String, dynamic> format, String activityTitle) {
    final TextEditingController controller = TextEditingController();
    String configTitle = '';
    String configHint = '';
    String configUnit = '';
    
    switch (format['configType']) {
      case 'distance':
        configTitle = 'Quelle distance veux-tu parcourir ?';
        configHint = 'Ex: 5';
        configUnit = 'km';
        break;
      case 'duration':
        configTitle = 'Combien de temps veux-tu t\'entraîner ?';
        configHint = 'Ex: 30';
        configUnit = 'min';
        break;
      case 'hiit':
        configTitle = 'Paramètres de ton HIIT';
        configHint = 'Durée totale en minutes';
        configUnit = 'min';
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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
                
                const SizedBox(height: 24),
                
                Text(
                  configTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                Text(
                  '${format['title']} - $activityTitle',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Champ de saisie
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: configHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF0B132B)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        configUnit,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Bouton valider
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        Navigator.pop(context);
                        final configuredTitle = '${format['title']} - ${controller.text} $configUnit';
                        _showRecordingChoiceModal(context, configuredTitle, format['trackable']);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Valider',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecordingChoiceModal(BuildContext context, String formatTitle, bool trackable) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              
              const SizedBox(height: 24),
              
              const Text(
                'Comment veux-tu enregistrer cette séance ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              Text(
                formatTitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bouton démarrer (si trackable)
              if (trackable) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Démarrer le tracking live
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Démarrage du tracking pour $formatTitle')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.play, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Démarrer la séance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Bouton déclarer
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Ouvrir le formulaire de saisie manuelle
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ouverture du formulaire pour $formatTitle')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B132B),
                    side: const BorderSide(color: Color(0xFF0B132B)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.edit3, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Déclarer la séance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastSession() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dernière séance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Icône activité
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.activity,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Informations principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Course à pied',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Il y a 2 jours',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bouton détails
                TextButton(
                  onPressed: () {
                    // TODO: Voir les détails de la séance
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0B132B),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text(
                    'Voir les détails',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Grille des données
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSessionStat(
                          icon: LucideIcons.clock,
                          label: 'Durée',
                          value: '28 min',
                        ),
                      ),
                      Expanded(
                        child: _buildSessionStat(
                          icon: LucideIcons.mapPin,
                          label: 'Distance',
                          value: '5.2 km',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSessionStat(
                          icon: LucideIcons.activity,
                          label: 'Allure',
                          value: '5:23 /km',
                        ),
                      ),
                      Expanded(
                        child: _buildSessionStat(
                          icon: LucideIcons.zap,
                          label: 'Vitesse moy.',
                          value: '11.2 km/h',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSessionStat(
                    icon: LucideIcons.flame,
                    label: 'Calories',
                    value: '320 kcal',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekSessions() {
    final weekSessions = [
      {
        'icon': LucideIcons.activity,
        'activity': 'Course à pied',
        'day': 'Lundi',
        'distance': '5.2 km',
        'duration': '28 min',
        'calories': '320 kcal',
      },
      {
        'icon': LucideIcons.footprints,
        'activity': 'Marche rapide',
        'day': 'Mercredi',
        'distance': '3.1 km',
        'duration': '25 min',
        'calories': '160 kcal',
      },
      {
        'icon': LucideIcons.bike,
        'activity': 'Vélo',
        'day': 'Vendredi',
        'distance': '12.0 km',
        'duration': '40 min',
        'calories': '450 kcal',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Vos séances de la semaine',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Liste des séances
        ...weekSessions.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;
          final isLast = index == weekSessions.length - 1;
          
          return Column(
            children: [
              _buildWeekSessionItem(
                icon: session['icon'] as IconData,
                activity: session['activity'] as String,
                day: session['day'] as String,
                distance: session['distance'] as String,
                duration: session['duration'] as String,
                calories: session['calories'] as String,
              ),
              if (!isLast) ...[
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 1,
                  color: const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWeekSessionItem({
    required IconData icon,
    required String activity,
    required String day,
    required String distance,
    required String duration,
    required String calories,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Icône à gauche
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF0B132B),
          ),
          
          const SizedBox(width: 12),
          
          // Informations au centre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$distance • $duration • $calories',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          
          // Jour à droite
          Text(
            day,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryAccess(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          // TODO: Ouvrir le journal cardio
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendar,
              size: 16,
              color: Color(0xFF0B132B),
            ),
            SizedBox(width: 8),
            Text(
              'Voir tout mon journal cardio',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0B132B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalFormat({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
} 