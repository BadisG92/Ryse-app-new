import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/localization_service.dart';
import '../services/weekly_bilan_service.dart';

/// Weekly Contract "Pacte" Screen
/// Simple, beautiful contract with Coach Ryze
class WeeklyContractScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const WeeklyContractScreen({
    super.key,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<WeeklyContractScreen> createState() => _WeeklyContractScreenState();
}

class _WeeklyContractScreenState extends State<WeeklyContractScreen> {
  int? _selectedDay; // 1=Monday, 7=Sunday
  bool _isSaving = false;

  final List<_DayOption> _days = [
    _DayOption(1, 'L', 'M', 'M', 'Lundi', 'Monday', 'Montag'),
    _DayOption(2, 'M', 'T', 'D', 'Mardi', 'Tuesday', 'Dienstag'),
    _DayOption(3, 'M', 'W', 'M', 'Mercredi', 'Wednesday', 'Mittwoch'),
    _DayOption(4, 'J', 'T', 'D', 'Jeudi', 'Thursday', 'Donnerstag'),
    _DayOption(5, 'V', 'F', 'F', 'Vendredi', 'Friday', 'Freitag'),
    _DayOption(6, 'S', 'S', 'S', 'Samedi', 'Saturday', 'Samstag'),
    _DayOption(7, 'D', 'S', 'S', 'Dimanche', 'Sunday', 'Sonntag'),
  ];

  Future<void> _saveAndComplete() async {
    if (_selectedDay == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('users').update({
          'weekly_bilan_day': _selectedDay,
          'weekly_bilan_enabled': true,
        }).eq('id', user.id);

        // Save to WeeklyBilanService
        await WeeklyBilanService.instance.setBilanDay(_selectedDay!);

        if (kDebugMode) {
          debugPrint('✅ Weekly bilan enabled for day $_selectedDay');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving weekly bilan: $e');
    }

    if (mounted) {
      widget.onComplete();
    }
  }


  @override
  Widget build(BuildContext context) {
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;
    final isFr = lang == 'fr';
    final isDe = lang == 'de';
    final screenHeight = MediaQuery.of(context).size.height;
    // Adapter la taille de l'image selon l'écran
    final imageHeight = screenHeight < 700 ? 120.0 : 160.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        120, // Espace pour le bouton fixe en bas
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Title at top
                        Text(
                          isFr ? 'Notre Pacte' : isDe ? 'Unser Pakt' : 'Our Pact',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Coach Ryze duo image (sport + nutrition)
                        Image.asset(
                          'assets/images/coach_ryze_contract.png',
                          height: imageHeight,
                        ),
                        const SizedBox(height: 24),

                        // Coach commitment
                        Text(
                          isFr
                              ? '"Nous, tes Coach Ryze, on s\'engage à te suivre, te motiver, et jamais te juger."'
                              : isDe
                                  ? '"Wir, deine Coach Ryze, verpflichten uns, dich zu begleiten, zu motivieren und niemals zu verurteilen."'
                                  : '"We, your Coach Ryze team, commit to following you, motivating you, and never judging you."',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0B132B),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // User commitment
                        Text(
                          isFr
                              ? '"En échange, tu nous donnes 5 min chaque semaine."'
                              : isDe
                                  ? '"Im Gegenzug gibst du uns 5 Min pro Woche."'
                                  : '"In return, you give us 5 min each week."',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Divider
                        Container(
                          width: 60,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Day selection title
                        Text(
                          isFr ? 'Notre jour de check-in' : isDe ? 'Unser Check-in Tag' : 'Our check-in day',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Day selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _days.map((day) {
                            final isSelected = _selectedDay == day.value;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedDay = day.value),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                              colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: isSelected ? null : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? null
                                          : Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        isFr ? day.shortFr : isDe ? day.shortDe : day.shortEn,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // Selected day label
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _selectedDay != null
                              ? Text(
                                  isFr
                                      ? _days[_selectedDay! - 1].fullFr
                                      : isDe
                                          ? _days[_selectedDay! - 1].fullDe
                                          : _days[_selectedDay! - 1].fullEn,
                                  key: ValueKey(_selectedDay),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                )
                              : const SizedBox(height: 20),
                        ),

                        // Spacer flexible pour pousser le contenu vers le haut sur grands écrans
                        const Spacer(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Sign button - fixe en bas
            Container(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: _selectedDay != null && !_isSaving
                    ? _saveAndComplete
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _selectedDay != null && !_isSaving
                        ? const LinearGradient(
                            colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                          )
                        : null,
                    color: _selectedDay == null || _isSaving
                        ? const Color(0xFFF1F5F9)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _selectedDay != null && !_isSaving
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0B132B).withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isFr
                                ? '🤝  Je signe avec Ryze'
                                : isDe
                                    ? '🤝  Ich unterschreibe mit Ryze'
                                    : '🤝  I sign with Ryze',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: _selectedDay != null
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayOption {
  final int value;
  final String shortFr;
  final String shortEn;
  final String shortDe;
  final String fullFr;
  final String fullEn;
  final String fullDe;

  _DayOption(this.value, this.shortFr, this.shortEn, this.shortDe, this.fullFr, this.fullEn, this.fullDe);
}
