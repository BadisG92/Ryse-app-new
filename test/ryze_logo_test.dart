import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/components/ui/ryze_intro.dart';
import 'package:ryze_app/design/ryze_logo.dart';

/// The lockup is drawn as filled paths, and the counters of the R and the e are
/// contours inside their own letter. They only stay hollow if those contours
/// wind against their outline, because the paths carry no explicit fill rule.
/// Nothing in the code says so out loud, so it is asserted here instead.
void main() {
  const box = Rect.fromLTWH(0, 0, 312, 367);

  test('the counters of the R and the e are holes, not ink', () {
    final word = RyzeLogo.word(box);
    final contours = word.computeMetrics().toList();
    expect(contours.length, 6, reason: 'R + its counter, y, z, e + its counter');

    final holes = <int, Rect>{};
    for (var i = 0; i < contours.length; i++) {
      final bounds = contours[i].extractPath(0, contours[i].length).getBounds();
      // a counter is a contour that sits inside another one
      for (var j = 0; j < contours.length; j++) {
        if (i == j) continue;
        final outer = contours[j].extractPath(0, contours[j].length).getBounds();
        if (outer.contains(bounds.topLeft) && outer.contains(bounds.bottomRight)) {
          holes[i] = bounds;
        }
      }
    }
    expect(holes.length, 2, reason: 'exactly two counters');

    for (final entry in holes.entries) {
      expect(
        word.contains(entry.value.center),
        isFalse,
        reason: 'contour ${entry.key} is filled: the letter would be a solid blob',
      );
    }
  });

  test('the mark is solid, and its arm anchor sits inside it', () {
    final parts = RyzeLogo.markParts(box);
    expect(parts.length, 2, reason: 'the dot, then the rise');

    final mark = Path();
    for (final part in parts) {
      mark.addPath(part.shape, Offset.zero);
    }
    final anchor = RyzeLogo.armAnchor(box);
    expect(mark.contains(anchor), isTrue, reason: 'the opening grows from the arm, not from a hollow');

    // and the disc that is supposed to fit inside it really does
    final r = RyzeLogo.armRadius(box);
    for (var a = 0; a < 16; a++) {
      final t = a * math.pi / 8;
      final p = anchor + Offset(r * 0.95 * math.cos(t), r * 0.95 * math.sin(t));
      expect(mark.contains(p), isTrue, reason: 'the inscribed disc leaks out at angle $a');
    }
  });

  _ink();
}

/// Le mot doit être encré jusqu'à son dernier pixel.
///
/// L'encre est posée par un dégradé : opaque à gauche de `front - soft`,
/// transparent à `front`. Le front s'arrêtait au bord droit du mot, donc les
/// douze derniers pour cent — la moitié du « e » final — restaient sous la
/// partie fondue et n'étaient jamais complètement écrits. Pas seulement au
/// moment de la pause : jamais.
void _ink() {
  const left = 0.0;
  const width = 312.0;
  const soft = width * 0.12;

  test('à la fin du tracé, le mot entier est opaque', () {
    final opaqueEdge = inkFront(1, left, width, soft) - soft;
    expect(opaqueEdge, greaterThanOrEqualTo(left + width));
  });

  test('au départ, rien n’est encore encré', () {
    expect(inkFront(0, left, width, soft), lessThanOrEqualTo(left));
  });

  test('à mi-parcours, le front est dans le mot', () {
    final front = inkFront(0.5, left, width, soft);
    expect(front, greaterThan(left));
    expect(front, lessThan(left + width));
  });
}
