import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/haptic_service.dart';
import '../onboarding_theme.dart';
import 'onb_widgets.dart';

/// Selectable card. Selected = ink fill wiping in from the left, white text.
class OnbOptionCard extends StatefulWidget {
  const OnbOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.selected,
    required this.onTap,
    this.index = 0,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final int index;
  final bool dense;

  @override
  State<OnbOptionCard> createState() => _OnbOptionCardState();
}

class _OnbOptionCardState extends State<OnbOptionCard> with SingleTickerProviderStateMixin {
  // a visible sweep: ease-out over ~half a second, the page waits for it before turning
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 480), value: widget.selected ? 1 : 0);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: OnbCurves.out);

  @override
  void didUpdateWidget(covariant OnbOptionCard old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      widget.selected ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = widget.dense ? context.vw(3.3) : context.vw(4.2);
    final radius = BorderRadius.circular(context.vw(widget.dense ? 3.8 : 4.4));
    return PopIn(
      delay: Duration(milliseconds: 320 + widget.index * 65),
      child: GestureDetector(
        onTap: () {
          HapticService.instance.lightImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _a,
          builder: (context, _) {
            final t = _a.value;
            final fg = Color.lerp(OnbColors.ink, Colors.white, t)!;
            final sub = Color.lerp(OnbColors.mute, Colors.white.withValues(alpha: 0.72), t)!;
            return Container(
              decoration: BoxDecoration(
                color: OnbColors.surf,
                borderRadius: radius,
                border: Border.all(color: OnbColors.line),
                boxShadow: [
                  BoxShadow(
                      color: OnbColors.ink.withValues(alpha: 0.05 + 0.3 * t),
                      blurRadius: context.vw(2.4 + 1.2 * t),
                      offset: Offset(0, context.vw(0.8 + 0.6 * t))),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(widthFactor: t.clamp(0.0, 1.0), child: const ColoredBox(color: OnbColors.ink)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad + context.vw(0.2), vertical: pad),
                    child: Row(
                      children: [
                        if (widget.icon != null) ...[
                          Container(
                            width: context.vw(11),
                            height: context.vw(11),
                            decoration: BoxDecoration(
                              color: Color.lerp(OnbColors.paper2, Colors.white.withValues(alpha: 0.14), t),
                              borderRadius: BorderRadius.circular(context.vw(3.4)),
                            ),
                            child: Icon(widget.icon, size: context.vw(5.4), color: fg),
                          ),
                          SizedBox(width: context.vw(3.4)),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title, style: OnbText.body(context, widget.dense ? 3.8 : 4.1, weight: FontWeight.w600, color: fg, height: 1.2)),
                              if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                                SizedBox(height: context.vw(0.5)),
                                Text(widget.subtitle!, style: OnbText.body(context, 3.1, color: sub, height: 1.25)),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: context.vw(2)),
                        Container(
                          width: context.vw(6.2),
                          height: context.vw(6.2),
                          decoration: BoxDecoration(
                            color: Color.lerp(OnbColors.surf, Colors.white, t),
                            shape: BoxShape.circle,
                            border: Border.all(color: Color.lerp(OnbColors.ink.withValues(alpha: 0.18), Colors.white, t)!, width: 1.5),
                          ),
                          child: Transform.scale(
                            scale: 0.4 + 0.6 * t,
                            child: Opacity(opacity: t.clamp(0.0, 1.0), child: Icon(LucideIcons.check, size: context.vw(3.2), color: OnbColors.ink)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pill chip. Selected = ink.
class OnbChip extends StatelessWidget {
  const OnbChip({super.key, required this.label, required this.selected, required this.onTap, this.index = 0});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return PopIn(
      delay: Duration(milliseconds: 320 + index * 45),
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () {
          HapticService.instance.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: OnbCurves.spring,
          padding: EdgeInsets.symmetric(horizontal: context.vw(4.2), vertical: context.vw(2.9)),
          decoration: BoxDecoration(
            color: selected ? OnbColors.ink : OnbColors.surf,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? OnbColors.ink : OnbColors.line),
            boxShadow:
                selected ? [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.35), blurRadius: context.vw(2.6), offset: Offset(0, context.vw(1)))] : null,
          ),
          child: Text(label, style: OnbText.body(context, 3.7, weight: FontWeight.w600, color: selected ? Colors.white : OnbColors.ink, height: 1.2)),
        ),
      ),
    );
  }
}

/// Seven day tiles. `value` is 1..7 (Monday..Sunday) or null.
class OnbDayPicker extends StatelessWidget {
  const OnbDayPicker({super.key, required this.shortNames, required this.fullNames, required this.value, required this.onChanged});
  final List<String> shortNames;
  final List<String> fullNames;
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) SizedBox(width: context.vw(1.5)),
              Expanded(
                child: PopIn(
                  delay: Duration(milliseconds: 320 + i * 40),
                  duration: const Duration(milliseconds: 500),
                  child: GestureDetector(
                    onTap: () {
                      HapticService.instance.lightImpact();
                      onChanged(i + 1);
                    },
                    child: AnimatedScale(
                      scale: value == i + 1 ? 1.06 : 1,
                      duration: const Duration(milliseconds: 280),
                      curve: OnbCurves.spring,
                      child: AnimatedSlide(
                        offset: value == i + 1 ? const Offset(0, -0.06) : Offset.zero,
                        duration: const Duration(milliseconds: 280),
                        curve: OnbCurves.spring,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          height: context.vw(15.5),
                          decoration: BoxDecoration(
                            color: value == i + 1 ? OnbColors.ink : OnbColors.surf,
                            borderRadius: BorderRadius.circular(context.vw(3.4)),
                            border: Border.all(color: value == i + 1 ? OnbColors.ink : OnbColors.line),
                            boxShadow: value == i + 1
                                ? [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.4), blurRadius: context.vw(5), offset: Offset(0, context.vw(2)))]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(shortNames[i],
                                  style: OnbText.display(context, 4.6, color: value == i + 1 ? Colors.white : OnbColors.ink, letterSpacingEm: -0.01)),
                              SizedBox(height: context.vw(0.8)),
                              Text(fullNames[i].substring(0, 3),
                                  style: OnbText.body(context, 2.5,
                                      weight: FontWeight.w500, color: value == i + 1 ? Colors.white.withValues(alpha: 0.7) : OnbColors.mute)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: context.vh(2)),
        SizedBox(
          height: context.vw(8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(value == null ? '' : fullNames[value! - 1],
                key: ValueKey(value), style: OnbText.display(context, 6, letterSpacingEm: -0.02), textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}

class OnbPersonalityOption {
  const OnbPersonalityOption({required this.key, required this.emoji, required this.label, required this.sample});
  final String key;
  final String emoji;
  final String label;
  final String sample;
}

/// Five tone tiles + preview bubble that streams the sample sentence.
class OnbPersonalityGrid extends StatelessWidget {
  const OnbPersonalityGrid({super.key, required this.options, required this.value, required this.hint, required this.onChanged});
  final List<OnbPersonalityOption> options;
  final String? value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = options.where((o) => o.key == value).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) SizedBox(width: context.vw(1.8)),
              Expanded(
                child: PopIn(
                  delay: Duration(milliseconds: 320 + i * 45),
                  duration: const Duration(milliseconds: 500),
                  child: GestureDetector(
                    onTap: () {
                      HapticService.instance.lightImpact();
                      onChanged(options[i].key);
                    },
                    child: AnimatedSlide(
                      offset: value == options[i].key ? const Offset(0, -0.05) : Offset.zero,
                      duration: const Duration(milliseconds: 280),
                      curve: OnbCurves.spring,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        padding: EdgeInsets.symmetric(vertical: context.vw(3.2), horizontal: context.vw(0.8)),
                        decoration: BoxDecoration(
                          color: value == options[i].key ? OnbColors.ink : OnbColors.surf,
                          borderRadius: BorderRadius.circular(context.vw(3.6)),
                          border: Border.all(color: value == options[i].key ? OnbColors.ink : OnbColors.line),
                          boxShadow: value == options[i].key
                              ? [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.4), blurRadius: context.vw(3.6), offset: Offset(0, context.vw(1.4)))]
                              : null,
                        ),
                        child: Column(
                          children: [
                            AnimatedScale(
                              scale: value == options[i].key ? 1.15 : 1,
                              duration: const Duration(milliseconds: 280),
                              child: Opacity(
                                  opacity: value == options[i].key ? 1 : 0.6,
                                  child: Text(options[i].emoji, style: TextStyle(fontSize: context.vw(6.2), height: 1))),
                            ),
                            SizedBox(height: context.vw(1.4)),
                            Text(
                              options[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: OnbText.body(context, 2.8,
                                  weight: FontWeight.w600, color: value == options[i].key ? Colors.white : OnbColors.mute, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: context.vh(2)),
        PopIn(
          delay: const Duration(milliseconds: 500),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: context.vw(16)),
            padding: EdgeInsets.fromLTRB(context.vw(5.4), context.vw(4.2), context.vw(4.6), context.vw(4.2)),
            decoration: BoxDecoration(
              color: OnbColors.ink,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.vw(4.6)),
                topRight: Radius.circular(context.vw(4.6)),
                bottomRight: Radius.circular(context.vw(4.6)),
                bottomLeft: Radius.circular(context.vw(1.4)),
              ),
            ),
            child: selected == null
                ? Text(hint, style: OnbText.body(context, 3.9, color: Colors.white.withValues(alpha: 0.6)))
                : WordStream(selected.sample, key: ValueKey(selected.key), style: OnbText.body(context, 3.9, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
