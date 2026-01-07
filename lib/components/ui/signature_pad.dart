import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A signature pad widget that allows users to draw their signature
class SignaturePad extends StatefulWidget {
  final Color penColor;
  final double penStrokeWidth;
  final Color backgroundColor;
  final VoidCallback? onSignatureChanged;

  const SignaturePad({
    super.key,
    this.penColor = const Color(0xFF0B132B),
    this.penStrokeWidth = 3.0,
    this.backgroundColor = Colors.white,
    this.onSignatureChanged,
  });

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  bool get isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;
  bool get isNotEmpty => !isEmpty;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    widget.onSignatureChanged?.call();
  }

  /// Export signature as image bytes (PNG)
  Future<ui.Image?> toImage() async {
    if (isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = context.size ?? const Size(300, 150);

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw signature
    final paint = Paint()
      ..color = widget.penColor
      ..strokeWidth = widget.penStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.length > 1) {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(size.width.toInt(), size.height.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _currentStroke = [details.localPosition];
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _currentStroke.add(details.localPosition);
        });
      },
      onPanEnd: (details) {
        setState(() {
          if (_currentStroke.isNotEmpty) {
            _strokes.add(List.from(_currentStroke));
            _currentStroke.clear();
          }
        });
        widget.onSignatureChanged?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _SignaturePainter(
            strokes: _strokes,
            currentStroke: _currentStroke,
            penColor: widget.penColor,
            penStrokeWidth: widget.penStrokeWidth,
            backgroundColor: widget.backgroundColor,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color penColor;
  final double penStrokeWidth;
  final Color backgroundColor;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.penColor,
    required this.penStrokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    // Signature line at bottom
    final linePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(size.width - 20, size.height - 20),
      linePaint,
    );

    // Strokes
    final paint = Paint()
      ..color = penColor
      ..strokeWidth = penStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    // Current stroke
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> stroke, Paint paint) {
    if (stroke.length < 2) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, paint.strokeWidth / 2, paint);
      }
      return;
    }

    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
    for (int i = 1; i < stroke.length; i++) {
      path.lineTo(stroke[i].dx, stroke[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}

/// Dialog for capturing signature
class SignatureDialog extends StatefulWidget {
  final String title;
  final String confirmText;
  final String clearText;

  const SignatureDialog({
    super.key,
    this.title = 'Votre signature',
    this.confirmText = 'Confirmer',
    this.clearText = 'Effacer',
  });

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final GlobalKey<SignaturePadState> _signatureKey = GlobalKey();
  bool _hasSignature = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B132B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SignaturePad(
                key: _signatureKey,
                onSignatureChanged: () {
                  setState(() {
                    _hasSignature = _signatureKey.currentState?.isNotEmpty ?? false;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _signatureKey.currentState?.clear();
                    },
                    child: Text(
                      widget.clearText,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasSignature
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(widget.confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
