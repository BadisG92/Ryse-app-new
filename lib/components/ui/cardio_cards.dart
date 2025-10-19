import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'cardio_models.dart';
import 'custom_card.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';

// Card de statistique hebdomadaire
class WeeklyStatCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const WeeklyStatCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
      height: 85,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: _buildValueWithUnit(displayTitle),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValueWithUnit(String value) {
    // Séparer la valeur de l'unité (ex: "12.5 km" -> "12.5" + "km")
    final parts = value.split(' ');
    if (parts.length >= 2) {
      final mainValue = parts[0];
      final unit = parts.sublist(1).join(' ');

      // Calculer la taille de police dynamiquement selon la longueur du nombre
      // Réduction des tailles pour que 233 kcal passe dans la boîte
      double fontSize = 20;
      if (mainValue.length >= 6) {
        fontSize = 12; // Très grands nombres (6+ chiffres)
      } else if (mainValue.length >= 5) {
        fontSize = 14; // Grands nombres (5 chiffres)
      } else if (mainValue.length >= 4) {
        fontSize = 16; // Nombres moyens (4 chiffres)
      } else if (mainValue.length >= 3) {
        fontSize = 18; // Nombres à 3 chiffres (comme 233)
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              mainValue,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B132B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      // Pas d'unité, calculer la taille dynamiquement aussi
      double fontSize = 20;
      if (value.length >= 6) {
        fontSize = 12;
      } else if (value.length >= 5) {
        fontSize = 14;
      } else if (value.length >= 4) {
        fontSize = 16;
      } else if (value.length >= 3) {
        fontSize = 18;
      }

      return Flexible(
        child: Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0B132B),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

// Card d'activité pour la sélection
class ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
}

// Card de session pour l'affichage des détails
class SessionCard extends StatelessWidget {
  final CardioSession session;
  final VoidCallback? onDetailsTap;

  const SessionCard({
    super.key,
    required this.session,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'session_last_session'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Informations principales
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.activityTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.timeAgo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
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
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, _) => SessionStatItem(
                            icon: LucideIcons.clock,
                            label: 'session_stat_duration'.tr(locService.currentLanguageCode),
                            value: session.durationText,
                          ),
                        ),
                      ),
                      if (session.distance != null)
                        Expanded(
                          child: Consumer<LocalizationService>(
                            builder: (context, locService, _) => SessionStatItem(
                              icon: LucideIcons.mapPin,
                              label: 'session_stat_distance'.tr(locService.currentLanguageCode),
                              value: session.distanceText,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (session.pace != null)
                        Expanded(
                          child: Consumer<LocalizationService>(
                            builder: (context, locService, _) => SessionStatItem(
                              icon: LucideIcons.activity,
                              label: 'session_stat_pace'.tr(locService.currentLanguageCode),
                              value: session.paceText,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, _) => SessionStatItem(
                            icon: LucideIcons.flame,
                            label: 'session_stat_calories'.tr(locService.currentLanguageCode),
                            value: session.caloriesText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Item de statistique de session
class SessionStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const SessionStatItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

// Item de session pour la liste hebdomadaire
class WeekSessionItem extends StatelessWidget {
  final CardioSession session;

  const WeekSessionItem({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Icône à gauche
          Icon(
            session.activityIcon,
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
                  session.activityTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.distanceText} • ${session.durationText} • ${session.caloriesText}',
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
            _getDayText(session.date),
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

  String _getDayText(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Aujourd\'hui';
    if (difference == 1) return 'Hier';
    
    final weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return weekDays[date.weekday - 1];
  }
}

// Card de format d'activité pour les modals
class ActivityFormatCard extends StatelessWidget {
  final ActivityFormat format;
  final VoidCallback onTap;

  const ActivityFormatCard({
    super.key,
    required this.format,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                format.icon,
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
                    format.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    format.description,
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
