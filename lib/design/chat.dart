import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'feedback.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';
import 'undo_bar.dart';
import '../onboarding/widgets/onb_widgets.dart';

/// Le mobilier des conversations avec Ryze.
///
/// Il y en a deux dans l'application — le coach et le planificateur — et
/// chacune s'était dessiné la sienne : deux barres Material, deux bulles, deux
/// champs de saisie, deux façons de faire les trois points. C'est le même
/// personnage qui parle ; il doit avoir la même voix et le même décor.
///
/// La règle des couleurs de l'application tient ici sans rien changer :
/// **l'encre est ce que dit l'utilisateur**, le papier ce que Ryze répond, et
/// la marque signe chacune de ses prises de parole.

/// La tête d'une conversation : le retour, le buste, le nom, une action.
///
/// Elle remplace l'`AppBar` Material. Même silhouette que l'en-tête d'une
/// séance : un cercle de papier à gauche, le titre au centre gauche, le reste
/// à droite — rien qui ressemble à un écran d'un autre système.
class RyzeChatHeader extends StatelessWidget {
  const RyzeChatHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.avatars,
    this.onBack,
    this.trailing,
  });

  final String title;

  /// Une ligne muette sous le nom : « écrit… », un compte, une date.
  final String? subtitle;

  /// Les bustes de qui parle. Deux quand la conversation couvre les deux
  /// domaines — ils se chevauchent, comme sur la pilule de la barre du bas.
  final List<String> avatars;

  /// Nul pour fermer par le geste système seulement.
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(2.1), context.vw(4.1), context.vw(2.6)),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        border: Border(bottom: BorderSide(color: RyzeColors.line)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Semantics(
              button: true,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              child: Pressable(
                onTap: onBack!,
                child: Container(
                  width: context.vw(9.7),
                  height: context.vw(9.7),
                  decoration: const BoxDecoration(color: RyzeColors.paper2, shape: BoxShape.circle),
                  child: Icon(LucideIcons.arrowLeft, size: context.vw(4.6), color: RyzeColors.ink),
                ),
              ),
            ),
            SizedBox(width: context.vw(3.1)),
          ],
          _Busts(avatars: avatars),
          SizedBox(width: context.vw(2.6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RyzeText.display(context, 4.4, weight: FontWeight.w600),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: context.vw(2.1)), trailing!],
        ],
      ),
    );
  }
}

/// Un ou deux bustes. À deux, ils se chevauchent d'un tiers et le second
/// passe devant — le même geste que la pilule de la barre du bas, pour que
/// « les coachs » se reconnaisse d'un écran à l'autre.
class _Busts extends StatelessWidget {
  const _Busts({required this.avatars});

  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    if (avatars.length == 1) return CoachAvatar(avatars.first, sizeVw: 9.2);
    final overlap = context.vw(3.1);
    return SizedBox(
      width: context.vw(9.2) * avatars.length - overlap * (avatars.length - 1),
      height: context.vw(9.2),
      child: Stack(
        children: [
          for (var i = 0; i < avatars.length; i++)
            Positioned(
              left: i * (context.vw(9.2) - overlap),
              child: CoachAvatar(avatars[i], sizeVw: 9.2),
            ),
        ],
      ),
    );
  }
}

/// Un message. L'encre à droite pour l'utilisateur, le papier à gauche pour
/// Ryze, avec sa marque au-dessus.
///
/// Un appui long copie le texte : c'est le geste que tout le monde connaît, et
/// il évitait un menu de plus.
class RyzeBubble extends StatelessWidget {
  const RyzeBubble({
    super.key,
    required this.text,
    required this.mine,
    this.streaming = false,
    this.copyLabel,
    this.footer,
    this.avatar,
  });

  final String text;

  /// Vrai quand c'est l'utilisateur qui parle.
  final bool mine;

  /// La réponse arrive encore : un curseur bat en fin de ligne.
  final bool streaming;

  /// Le mot dit après une copie. Nul pour interdire la copie.
  final String? copyLabel;

  /// Ce qui se glisse sous le texte, dans la bulle : des boutons, une carte.
  final Widget? footer;

  /// Le buste de qui parle, à gauche de la bulle.
  ///
  /// C'était la marque de Ryze — un logo collé contre chaque bulle, ce qui
  /// fait signature d'entreprise et non conversation. Une conversation a des
  /// visages.
  ///
  /// Le message ne porte pas son domaine en base : dans le planificateur on
  /// sait lequel des deux parle parce que la conversation est d'un mode, dans
  /// le chat du coach on ne le sait pas et c'est le coach de la nutrition qui
  /// tient la ligne — c'est lui la voix du quotidien, le coach du sport ayant
  /// ses propres entrées, la séance et l'analyse, où il apparaît seul.
  final String? avatar;

  void _copy(BuildContext context) {
    if (copyLabel == null || text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    RyzeFeedback.confirm();
    RyzeUndo.note(context, message: copyLabel!);
  }

  /// Ryze écrit en gras avec des astérisques — c'est ce que le modèle rend, et
  /// les deux conversations le lisaient chacune de son côté. Sans ce passage,
  /// la bulle afficherait les astérisques.
  static final RegExp _bold = RegExp(r'\*\*(.+?)\*\*', dotAll: true);

  static List<InlineSpan> _spans(String raw) {
    final out = <InlineSpan>[];
    var at = 0;
    for (final m in _bold.allMatches(raw)) {
      if (m.start > at) out.add(TextSpan(text: raw.substring(at, m.start)));
      out.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      at = m.end;
    }
    if (at < raw.length) out.add(TextSpan(text: raw.substring(at)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
      decoration: BoxDecoration(
        color: mine ? RyzeColors.ink : RyzeColors.surf,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(RyzeRadius.md),
          topRight: const Radius.circular(RyzeRadius.md),
          bottomLeft: Radius.circular(mine ? RyzeRadius.md : RyzeRadius.xs),
          bottomRight: Radius.circular(mine ? RyzeRadius.xs : RyzeRadius.md),
        ),
        border: mine ? null : Border.all(color: RyzeColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                ..._spans(text),
                if (streaming)
                  TextSpan(
                    text: ' ▋',
                    style: TextStyle(color: RyzeColors.acc.withValues(alpha: 0.9)),
                  ),
              ],
            ),
            style: RyzeText.body(context, 3.6, height: 1.5, color: mine ? RyzeColors.surf : RyzeColors.ink),
          ),
          if (footer != null) ...[SizedBox(height: context.vw(3.1)), footer!],
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(3.1)),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine && avatar != null) ...[
            Padding(
              padding: EdgeInsets.only(top: context.vw(1.5), right: context.vw(2.1)),
              child: CoachAvatar(avatar!, sizeVw: 7.2),
            ),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.vw(mine ? 78 : 82)),
              child: GestureDetector(
                onLongPress: copyLabel == null ? null : () => _copy(context),
                child: bubble,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ryze réfléchit : sa marque, puis les trois points, dans une bulle vide.
class RyzeThinking extends StatelessWidget {
  const RyzeThinking({super.key, this.avatar});

  /// Le meme buste que les bulles de cette conversation, ou rien.
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(3.1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (avatar != null)
            Padding(
              padding: EdgeInsets.only(top: context.vw(1.5), right: context.vw(2.1)),
              child: CoachAvatar(avatar!, sizeVw: 7.2),
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.vw(4.6), vertical: context.vw(3.6)),
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(RyzeRadius.md),
                topRight: Radius.circular(RyzeRadius.md),
                bottomLeft: Radius.circular(RyzeRadius.xs),
                bottomRight: Radius.circular(RyzeRadius.md),
              ),
              border: Border.all(color: RyzeColors.line),
            ),
            child: const TypingDots(),
          ),
        ],
      ),
    );
  }
}

/// La coupure entre deux jours : un trait, une date, un trait.
class RyzeChatDay extends StatelessWidget {
  const RyzeChatDay({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.vw(3.1)),
      child: Row(
        children: [
          Expanded(child: Divider(color: RyzeColors.line, height: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.vw(3.1)),
            child: Text(label, style: RyzeText.body(context, 2.9, weight: FontWeight.w600, color: RyzeColors.mute2)),
          ),
          Expanded(child: Divider(color: RyzeColors.line, height: 1)),
        ],
      ),
    );
  }
}

/// Ce qu'on peut dire sans écrire : des amorces en pastilles.
class RyzeChatChips extends StatelessWidget {
  const RyzeChatChips({super.key, required this.labels, required this.onTap});

  final List<String> labels;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.vw(2.1),
      runSpacing: context.vw(2.1),
      children: [
        for (final label in labels)
          Pressable(
            onTap: () {
              RyzeFeedback.select();
              onTap(label);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.vw(3.6), vertical: context.vw(2.1)),
              decoration: BoxDecoration(
                color: RyzeColors.surf,
                borderRadius: BorderRadius.circular(RyzeRadius.pill),
                border: Border.all(color: RyzeColors.ink),
              ),
              child: Text(label, style: RyzeText.body(context, 3.2, weight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}

/// La barre de saisie : le micro, le champ, l'envoi.
///
/// Le bouton d'envoi est en encre dès qu'il y a quelque chose à envoyer, et
/// gris sinon : l'état du bouton est la seule chose qui dise si le message
/// partira.
class RyzeChatInput extends StatelessWidget {
  const RyzeChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onSend,
    required this.canSend,
    this.busy = false,
    this.onMic,
    this.listening = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final VoidCallback onSend;

  /// Faux quand le champ est vide : le bouton reste gris.
  final bool canSend;

  /// Une réponse est en route : l'envoi se ferme le temps qu'elle arrive.
  final bool busy;

  /// Nul quand la dictée n'est pas disponible : le micro disparaît plutôt que
  /// de rester là sans rien faire.
  final VoidCallback? onMic;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;
    final active = canSend && !busy;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.vw(4.1),
        context.vw(2.6),
        context.vw(4.1),
        inset > 0 ? context.vw(2.6) : safe + context.vw(2.6),
      ),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        border: Border(top: BorderSide(color: RyzeColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (onMic != null) ...[
            Semantics(
              button: true,
              child: Pressable(
                onTap: onMic!,
                child: Container(
                  width: context.vw(11.3),
                  height: context.vw(11.3),
                  decoration: BoxDecoration(
                    color: listening ? RyzeColors.ink : RyzeColors.paper2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    listening ? LucideIcons.micOff : LucideIcons.mic,
                    size: context.vw(4.9),
                    color: listening ? RyzeColors.surf : RyzeColors.mute,
                  ),
                ),
              ),
            ),
            SizedBox(width: context.vw(2.6)),
          ],
          Expanded(
            child: Container(
              constraints: BoxConstraints(minHeight: context.vw(11.3)),
              padding: EdgeInsets.symmetric(horizontal: context.vw(4.1)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: RyzeColors.paper2,
                borderRadius: BorderRadius.circular(RyzeRadius.lg),
                border: Border.all(color: focusNode.hasFocus ? RyzeColors.ink : Colors.transparent, width: 1.5),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => active ? onSend() : null,
                style: RyzeText.body(context, 3.6, height: 1.4),
                cursorColor: RyzeColors.ink,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: RyzeText.body(context, 3.6, color: RyzeColors.mute2),
                  contentPadding: EdgeInsets.symmetric(vertical: context.vw(3.1)),
                ),
              ),
            ),
          ),
          SizedBox(width: context.vw(2.6)),
          Semantics(
            button: true,
            enabled: active,
            child: Pressable(
              onTap: active ? onSend : () {},
              child: AnimatedContainer(
                duration: RyzeDurations.tap,
                curve: RyzeCurves.out,
                width: context.vw(11.3),
                height: context.vw(11.3),
                decoration: BoxDecoration(
                  color: active ? RyzeColors.ink : RyzeColors.idle,
                  shape: BoxShape.circle,
                ),
                child: busy
                    ? Center(
                        child: SizedBox(
                          width: context.vw(4.4),
                          height: context.vw(4.4),
                          child: const CircularProgressIndicator(strokeWidth: 2, color: RyzeColors.surf),
                        ),
                      )
                    : Icon(LucideIcons.arrowUp, size: context.vw(4.9), color: RyzeColors.surf),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
