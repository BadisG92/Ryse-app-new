import 'dart:ui';

/// One shape of the Ryze mark, and the path a pen takes to lay it down.
///
/// [shape] is the form itself; [skeleton] runs along its middle, and [nib] is
/// wide enough to cover the shape from that line. Sweeping the nib along the
/// skeleton and keeping only what it has passed over draws the shape the way a
/// hand would, instead of outlining a silhouette that is already readable
/// before a single stroke is finished.
class RyzeLogoPart {
  const RyzeLogoPart(this.shape, this.skeleton, this.nib);

  final Path shape;
  final Path skeleton;
  final double nib;
}

/// The Ryze lockup as vector geometry: the mark (the dot and the rise) and the
/// wordmark in the brand's own letterforms.
///
/// Generated from `assets/images/logo_ryze.svg`, the vertical lockup drawn on a
/// 312 x 367 canvas. The SVG stays the source of truth; this file exists so the
/// mark can be *drawn* rather than displayed, and so the name can be placed in
/// the mark's own proportions.
///
/// The mark's two skeletons are the medial axes of their own outlines, computed
/// from the brand file. The name is a single path: a hand writes it in eight
/// separate strokes, and animating those joins reads as a stutter rather than
/// as writing, so the name arrives as one block instead.
class RyzeLogo {
  RyzeLogo._();

  /// The canvas the paths are drawn in.
  static const Size lockup = Size(312, 367);

  /// Ink of the two halves inside [lockup], for laying out a tighter frame.
  static const Rect markBounds = Rect.fromLTRB(95.6, 20.4, 232.5, 218.3);
  static const Rect wordBounds = Rect.fromLTRB(18, 236, 306.3, 355.3);

  /// The dot, then the rise: a pen sets the dot down before sweeping the curve.
  static List<RyzeLogoPart> markParts(Rect box) {
    final double s = box.height / 367;
    double x(double v) => box.left + v * box.width / 312;
    double y(double v) => box.top + v * box.height / 367;
    return [
      // the dot
      RyzeLogoPart(
        Path()
          ..moveTo(x(132.7), y(22.5))
          ..cubicTo(x(127.4), y(24.5), x(121.4), y(29.1), x(117.9), y(33.8))
          ..cubicTo(x(109.3), y(45.5), x(110), y(63.7), x(119.5), y(74.8))
          ..cubicTo(x(124.2), y(80.2), x(133.9), y(85), x(141.7), y(85.7))
          ..cubicTo(x(156.6), y(87.1), x(171.2), y(77.4), x(175.2), y(63.6))
          ..cubicTo(x(175.9), y(61.3), x(176.4), y(56.3), x(176.4), y(52.4))
          ..cubicTo(x(176.4), y(39.2), x(168.4), y(27.6), x(156), y(22.9))
          ..cubicTo(x(150), y(20.6), x(138.4), y(20.4), x(132.7), y(22.5))
          ..close(),
        Path()
          ..moveTo(x(114.15), y(30.47))
          ..lineTo(x(125.92), y(39.46))
          ..lineTo(x(144.24), y(53.22))
          ..lineTo(x(162.48), y(67.19))
          ..lineTo(x(174.37), y(76.07)),
        72 * s,
      ),
      // the rise
      RyzeLogoPart(
        Path()
          ..moveTo(x(217.7), y(55))
          ..cubicTo(x(215.8), y(56.6), x(210.5), y(63.5), x(205.9), y(70.2))
          ..cubicTo(x(190.2), y(93.2), x(179.7), y(102), x(153), y(114.7))
          ..cubicTo(x(135.1), y(123.2), x(129.2), y(127), x(120.1), y(135.6))
          ..cubicTo(x(103.7), y(151), x(95.6), y(173.2), x(97.4), y(197.5))
          ..cubicTo(x(98.5), y(211.7), x(102.6), y(218.3), x(109.3), y(216.6))
          ..cubicTo(x(110.7), y(216.3), x(114.9), y(212.9), x(118.7), y(209.1))
          ..cubicTo(x(132.1), y(195.6), x(148.9), y(180.4), x(156.6), y(174.8))
          ..cubicTo(x(161), y(171.7), x(171), y(165.7), x(178.9), y(161.5))
          ..cubicTo(x(207.7), y(146.3), x(216.2), y(138), x(225.5), y(116.3))
          ..cubicTo(x(230.7), y(104.3), x(232.5), y(94), x(232.5), y(76))
          ..cubicTo(x(232.5), y(62.2), x(232.3), y(60.1), x(230.4), y(56.5))
          ..cubicTo(x(228.6), y(53.1), x(227.8), y(52.5), x(224.8), y(52.2))
          ..cubicTo(x(222), y(52), x(220.5), y(52.5), x(217.7), y(55))
          ..close(),
        Path()
          ..moveTo(x(101.22), y(219.93))
          ..lineTo(x(106.48), y(208.04))
          ..lineTo(x(110.78), y(196.82))
          ..lineTo(x(116.43), y(185.11))
          ..lineTo(x(123.05), y(174.25))
          ..lineTo(x(130.93), y(163.98))
          ..lineTo(x(140.33), y(154.94))
          ..lineTo(x(150.82), y(147.01))
          ..lineTo(x(162.03), y(139.97))
          ..lineTo(x(174.05), y(133.01))
          ..lineTo(x(185.1), y(125.86))
          ..lineTo(x(194.97), y(117.43))
          ..lineTo(x(203.44), y(107.75))
          ..lineTo(x(210.57), y(96.99))
          ..lineTo(x(215.99), y(85.36))
          ..lineTo(x(220.37), y(72.75))
          ..lineTo(x(224.37), y(60.87))
          ..lineTo(x(230.23), y(48.69)),
        70 * s,
      ),
    ];
  }

  /// R, y, z and e as one shape.
  static Path word(Rect box) {
    double x(double v) => box.left + v * box.width / 312;
    double y(double v) => box.top + v * box.height / 367;
    return Path()
      // R
      ..moveTo(x(18), y(282))
      ..lineTo(x(18), y(328))
      ..lineTo(x(26.5), y(328))
      ..lineTo(x(35), y(328))
      ..lineTo(x(35), y(311.5))
      ..lineTo(x(35), y(295))
      ..lineTo(x(43.9), y(295))
      ..lineTo(x(52.8), y(295))
      ..lineTo(x(62.3), y(311.2))
      ..lineTo(x(71.7), y(327.5))
      ..lineTo(x(81.5), y(327.8))
      ..cubicTo(x(89.1), y(328), x(91.1), y(327.8), x(90.7), y(326.8))
      ..cubicTo(x(90.5), y(326.1), x(85.7), y(318), x(80.2), y(308.8))
      ..lineTo(x(70.2), y(292.2))
      ..lineTo(x(75.8), y(288.8))
      ..cubicTo(x(91.5), y(279.4), x(92.2), y(252.6), x(77), y(241.8))
      ..cubicTo(x(70.4), y(237), x(63.9), y(236), x(39.8), y(236))
      ..lineTo(x(18), y(236))
      ..lineTo(x(18), y(282))
      ..close()
      ..moveTo(x(63.8), y(252.3))
      ..cubicTo(x(70.5), y(255.9), x(72.9), y(267.6), x(68.4), y(274.6))
      ..cubicTo(x(65.1), y(279.6), x(60.3), y(281), x(47), y(281))
      ..lineTo(x(35), y(281))
      ..lineTo(x(35), y(265.2))
      ..lineTo(x(35), y(249.5))
      ..lineTo(x(47.7), y(250))
      ..cubicTo(x(57.4), y(250.4), x(61.3), y(251), x(63.8), y(252.3))
      ..close()
      // y
      ..moveTo(x(94), y(258.7))
      ..cubicTo(x(94), y(259.2), x(100.1), y(274.6), x(107.6), y(293))
      ..cubicTo(x(115.1), y(311.4), x(121.5), y(327.7), x(121.7), y(329.1))
      ..cubicTo(x(123), y(336.1), x(115.8), y(341.6), x(106.3), y(340.8))
      ..lineTo(x(101), y(340.3))
      ..lineTo(x(101), y(347))
      ..lineTo(x(101), y(353.7))
      ..lineTo(x(104.1), y(354.4))
      ..cubicTo(x(108.8), y(355.3), x(116), y(355.1), x(120.4), y(353.9))
      ..cubicTo(x(125.6), y(352.5), x(132.6), y(345.8), x(136), y(339))
      ..cubicTo(x(140.3), y(330.5), x(168), y(261.1), x(168), y(258.9))
      ..cubicTo(x(168), y(258.4), x(164), y(258), x(159.2), y(258))
      ..lineTo(x(150.4), y(258))
      ..lineTo(x(148.3), y(264.2))
      ..cubicTo(x(147.1), y(267.7), x(143.9), y(277), x(141), y(285))
      ..cubicTo(x(138.2), y(293), x(134.8), y(302.4), x(133.6), y(305.8))
      ..lineTo(x(131.3), y(312.2))
      ..lineTo(x(121.6), y(285.1))
      ..lineTo(x(111.8), y(258))
      ..lineTo(x(102.9), y(258))
      ..cubicTo(x(98), y(258), x(94), y(258.3), x(94), y(258.7))
      ..close()
      // z
      ..moveTo(x(176), y(265.1))
      ..lineTo(x(176), y(272.2))
      ..lineTo(x(194), y(271.8))
      ..cubicTo(x(203.9), y(271.6), x(212), y(271.6), x(212), y(271.8))
      ..cubicTo(x(212), y(272), x(203.4), y(282.4), x(183.1), y(306.3))
      ..lineTo(x(175.6), y(315.1))
      ..lineTo(x(175.7), y(321.3))
      ..lineTo(x(175.8), y(327.5))
      ..lineTo(x(204.9), y(327.8))
      ..lineTo(x(234), y(328))
      ..lineTo(x(234), y(321))
      ..lineTo(x(234), y(314))
      ..lineTo(x(215.5), y(313.8))
      ..lineTo(x(197), y(313.5))
      ..lineTo(x(207.7), y(301))
      ..cubicTo(x(213.6), y(294.1), x(221.9), y(284.4), x(226.2), y(279.5))
      ..lineTo(x(234), y(270.5))
      ..lineTo(x(234), y(264.2))
      ..lineTo(x(234), y(258))
      ..lineTo(x(205), y(258))
      ..lineTo(x(176), y(258))
      ..lineTo(x(176), y(265.1))
      ..close()
      // e
      ..moveTo(x(263.9), y(257.3))
      ..cubicTo(x(253.9), y(260.1), x(244.7), y(269.6), x(241.5), y(280.3))
      ..cubicTo(x(239.5), y(287), x(239.6), y(300.4), x(241.6), y(306.8))
      ..cubicTo(x(249.1), y(330), x(281.4), y(337.7), x(298.7), y(320.4))
      ..cubicTo(x(301.6), y(317.5), x(304), y(314.5), x(304), y(313.7))
      ..cubicTo(x(304), y(312.5), x(294.9), y(308), x(292.4), y(308))
      ..cubicTo(x(291.8), y(308), x(290.3), y(309.2), x(288.9), y(310.6))
      ..cubicTo(x(282.2), y(317.7), x(271.4), y(318.5), x(263.2), y(312.3))
      ..cubicTo(x(259.7), y(309.7), x(256), y(303.3), x(256), y(300))
      ..cubicTo(x(256), y(298), x(256.5), y(298), x(281.1), y(298))
      ..lineTo(x(306.3), y(298))
      ..lineTo(x(305.8), y(288.7))
      ..cubicTo(x(305), y(273.5), x(299.6), y(264.6), x(288.1), y(259.2))
      ..cubicTo(x(281.6), y(256.2), x(270.9), y(255.3), x(263.9), y(257.3))
      ..close()
      ..moveTo(x(282.7), y(271.6))
      ..cubicTo(x(286.7), y(274.6), x(289), y(278.1), x(289.7), y(282.3))
      ..lineTo(x(290.3), y(286))
      ..lineTo(x(273.1), y(286))
      ..cubicTo(x(254), y(286), x(254.3), y(286.1), x(257.9), y(279.2))
      ..cubicTo(x(260.1), y(274.9), x(263.4), y(271.6), x(267), y(270.1))
      ..cubicTo(x(270.8), y(268.5), x(279.7), y(269.4), x(282.7), y(271.6))
      ..close();
  }

  /// The finished lockup as one path.
  static Path all(Rect box) {
    final p = Path();
    for (final part in markParts(box)) {
      p.addPath(part.shape, Offset.zero);
    }
    return p..addPath(word(box), Offset.zero);
  }
}
