import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mark.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// Le moment où Ryze réfléchit : plein cadre sur l'encre, la marque en ambre
/// au centre, et une onde qui part d'elle toutes les deux secondes.
///
/// L'onde est la seule chose qui bouge. Elle ne prétend pas mesurer une
/// progression — l'appel dure ce qu'il dure, et une barre qui avance sans rien
/// savoir serait un mensonge de plus.
///
/// C'est la seule attente longue de l'application : l'analyse de la journée
/// l'utilise, la lecture d'une photo aussi. Chacune l'avait écrite de son
/// côté — l'une avec cette onde, l'autre avec une roulette de 20 pixels au
/// milieu d'un écran vide, qui se lisait comme une page grise.
class RyzeBusy extends StatefulWidget {
  const RyzeBusy({super.key, required this.message, this.subject, this.trailing, this.background});

  /// Ce que Ryze est en train de faire, en une ligne.
  final String message;

  /// Ce qu'on regarde pendant l'attente — la photo qu'on analyse. Posée
  /// au-dessus de la marque, à sa taille réelle.
  final Widget? subject;

  /// Sous le message : de quoi sortir, quand l'attente n'est pas un passage
  /// obligé.
  final Widget? trailing;

  /// Le sol de l'attente. Nul quand elle s'incruste sur autre chose — la
  /// photo qu'on est en train de lire, par exemple, qui vaut mieux qu'un
  /// carré d'encre par-dessus elle.
  final Color? background;

  @override
  State<RyzeBusy> createState() => _RyzeBusyState();
}

class _RyzeBusyState extends State<RyzeBusy> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  /// L'arrivée. Sans elle, l'attente tombe d'un coup — un écran clair devient
  /// un mur d'encre en une image, et c'est ce saut qu'on voit, pas la marque.
  late final AnimationController _in = AnimationController(vsync: this, duration: RyzeDurations.enter)..forward();

  @override
  void dispose() {
    _in.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ring = context.vw(34);

    final content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.subject != null) ...[
              widget.subject!,
              SizedBox(height: context.vw(5.1)),
            ],
            SizedBox(
              width: ring,
              height: ring,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!still)
                        for (final offset in const [0.0, 0.5])
                          Builder(
                            builder: (context) {
                              final t = (_c.value + offset) % 1;
                              return Opacity(
                                opacity: (1 - t) * 0.30,
                                child: Container(
                                  width: ring * (0.34 + t * 0.66),
                                  height: ring * (0.34 + t * 0.66),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: RyzeColors.acc, width: 1.2),
                                  ),
                                ),
                              );
                            },
                          ),
                      child!,
                    ],
                  );
                },
                child: RyzeMark(size: context.vw(11), color: RyzeColors.acc),
              ),
            ),
            SizedBox(height: context.vw(4.6)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.vw(10)),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: RyzeText.body(context, 3.9, color: RyzeColors.surf.withValues(alpha: 0.78)),
              ),
            ),
            if (widget.trailing != null) ...[
              SizedBox(height: context.vw(6.2)),
              widget.trailing!,
            ],
          ],
        ),
    );

    final ground = widget.background;
    final body = ground == null ? content : ColoredBox(color: ground, child: content);

    // Le sol est sombre : les icônes de la barre d'état doivent passer en
    // clair, sinon l'heure et la batterie s'écrivent en presque-noir sur
    // l'encre et disparaissent.
    //
    // Et le style par défaut est posé ici, parce que cette attente est
    // parfois montrée dans un `OverlayEntry` — l'analyse de la journée — où
    // il n'y a aucun Material au-dessus. Sans lui, Flutter écrit ses textes
    // avec son style de secours : souligné d'un double trait jaune. C'est
    // exactement la tête qu'avait l'écran « Coach Ryze lit ta journée ».
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DefaultTextStyle(
        style: RyzeText.body(context, 3.9, color: RyzeColors.surf),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _in, curve: RyzeCurves.out),
          child: body,
        ),
      ),
    );
  }
}
