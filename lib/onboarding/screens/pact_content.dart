import 'package:flutter/material.dart';

import '../onboarding_strings.dart';
import '../onboarding_theme.dart';
import '../widgets/hold_to_sign.dart';
import '../widgets/onb_widgets.dart';

/// The pact card, the hold-to-sign control and the sparks.
class PactContent extends StatefulWidget {
  const PactContent({super.key, required this.s, required this.firstName, required this.dayName, required this.signed, required this.onSigned});
  final OnbStrings s;
  final String firstName;
  final String dayName;
  final bool signed;
  final VoidCallback onSigned;

  @override
  State<PactContent> createState() => _PactContentState();
}

class _PactContentState extends State<PactContent> {
  bool _burst = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final signed = widget.signed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PopIn(
          delay: const Duration(milliseconds: 300),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(context.vw(5.4), context.vw(5.4), context.vw(5.4), context.vw(5)),
                decoration: BoxDecoration(
                  color: OnbColors.surf,
                  borderRadius: BorderRadius.circular(context.vw(5)),
                  border: Border.all(color: OnbColors.line),
                  boxShadow: [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.08), blurRadius: context.vw(6), offset: Offset(0, context.vw(2)))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: context.vw(24)),
                      child: Text(s.t('pact_h'), style: OnbText.display(context, 6.2, height: 1.1, letterSpacingEm: -0.025)),
                    ),
                    SizedBox(height: context.vw(2.4)),
                    Text(s.t('pact_p1'), style: OnbText.body(context, 3.8, height: 1.5)),
                    SizedBox(height: context.vw(2)),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: s.t('pact_p2_pre')),
                        TextSpan(
                            text: s.t('pact_p2_bold', {'day': widget.dayName}), style: const TextStyle(color: OnbColors.accInk, fontWeight: FontWeight.w600)),
                        TextSpan(text: s.t('pact_p2_post')),
                      ]),
                      style: OnbText.body(context, 3.8, color: OnbColors.mute, height: 1.5),
                    ),
                    SizedBox(height: context.vw(4.6)),
                    Container(height: 1, color: OnbColors.line),
                    SizedBox(height: context.vw(3.6)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.t('pact_signed_by'), style: OnbText.body(context, 2.8, color: OnbColors.mute)),
                              AnimatedOpacity(
                                opacity: signed ? 1 : 0,
                                duration: const Duration(milliseconds: 500),
                                child: AnimatedSlide(
                                  offset: signed ? Offset.zero : const Offset(0, 0.3),
                                  duration: const Duration(milliseconds: 500),
                                  curve: OnbCurves.spring,
                                  child: Text(widget.firstName, style: OnbText.display(context, 5, letterSpacingEm: -0.02)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: context.vw(14),
                          height: context.vw(8),
                          child: Stack(
                            children: [
                              const CoachAvatar(OnbAssets.sportAvatar, sizeVw: 8),
                              Positioned(left: context.vw(5.4), child: const CoachAvatar(OnbAssets.nutriAvatar, sizeVw: 8)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: context.vw(5),
                top: context.vw(4.6),
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: signed ? 1 : 2.2,
                    duration: const Duration(milliseconds: 450),
                    curve: const Cubic(0.2, 1.4, 0.3, 1),
                    child: AnimatedOpacity(
                      opacity: signed ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Transform.rotate(
                        angle: -0.17,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: context.vw(2.8), vertical: context.vw(1.4)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            border: Border.all(color: OnbColors.accInk, width: 2.5),
                            borderRadius: BorderRadius.circular(context.vw(1.6)),
                          ),
                          child: Text(s.t('stamp').toUpperCase(),
                              style: OnbText.display(context, 5, weight: FontWeight.w900, color: OnbColors.accInk, letterSpacingEm: 0.06, height: 1)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.vh(2)),
        PopIn(
          delay: const Duration(milliseconds: 450),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              HoldToSign(
                label: s.t('hold_label'),
                doneLabel: s.t('hold_done'),
                done: signed,
                onDone: () {
                  setState(() => _burst = true);
                  widget.onSigned();
                },
              ),
              if (_burst) Positioned.fill(child: SparkBurst(key: UniqueKey())),
            ],
          ),
        ),
      ],
    );
  }
}
