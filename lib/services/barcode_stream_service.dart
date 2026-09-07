import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'mlkit_barcode_service.dart';

/// Reads barcodes from the live frames instead of from a photograph.
///
/// The app already ran ML Kit on device, in well under half a second, but it
/// only ever fed it a still picture taken with a shutter button: the user had
/// to aim, press, wait, and try again on a miss. Every reader people have used
/// simply fires when the code enters the frame. This does that.
///
/// It is deliberately defensive. Frame formats differ between iOS and Android
/// and between devices, and a viewfinder that throws is worse than one that
/// asks for a tap: on any failure it reports itself unavailable and the host
/// keeps its shutter.
class BarcodeStreamService {
  BarcodeStreamService(this._controller);

  final CameraController _controller;

  bool _running = false;
  bool _busy = false;
  bool _stopped = false;

  /// How many frames were handed over without a single readable one. After a
  /// while the host can offer the manual way rather than let the user aim on.
  int _misses = 0;

  /// True once a frame has been converted without throwing. Until then the
  /// host must not hide its shutter.
  bool get healthy => _converted;
  bool _converted = false;

  int get misses => _misses;

  /// Starts reading. [onCode] fires once, on the first valid code; the stream
  /// stops itself immediately after. [onUnavailable] means this device cannot
  /// stream to ML Kit and the shutter has to stay.
  Future<void> start({
    required void Function(String code) onCode,
    required VoidCallback onUnavailable,
  }) async {
    if (_running || !_controller.value.isInitialized) return;
    _running = true;
    try {
      await _controller.startImageStream((image) async {
        if (_busy || _stopped) return;
        _busy = true;
        try {
          final input = _toInputImage(image);
          if (input == null) {
            // A format we cannot describe to ML Kit: give up on streaming
            // rather than burn the battery on frames that will never read.
            _busy = false;
            await stop();
            onUnavailable();
            return;
          }
          _converted = true;
          final codes = await MLKitBarcodeService.scanner.processImage(input);
          final code = codes
              .map((b) => b.rawValue)
              .firstWhere((value) => value != null && value.trim().length >= 8, orElse: () => null);
          if (code != null && !_stopped) {
            _stopped = true;
            await stop();
            onCode(code.trim());
          } else {
            _misses++;
          }
        } catch (e) {
          _misses++;
          if (kDebugMode) debugPrint('⚠️ [BARCODE STREAM] $e');
          // Repeated conversion failures mean this path will not work here.
          if (!_converted && _misses > 8) {
            await stop();
            onUnavailable();
          }
        } finally {
          _busy = false;
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [BARCODE STREAM] démarrage impossible: $e');
      _running = false;
      onUnavailable();
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    try {
      if (_controller.value.isStreamingImages) await _controller.stopImageStream();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [BARCODE STREAM] arrêt: $e');
    }
  }

  /// The frame, described the way ML Kit expects it on this platform. iOS
  /// hands over one BGRA plane; Android hands over YUV planes, of which the
  /// first is the one ML Kit reads as NV21 on the devices that support it.
  InputImage? _toInputImage(CameraImage image) {
    final rotation = InputImageRotationValue.fromRawValue(_controller.description.sensorOrientation);
    if (rotation == null) return null;

    if (Platform.isIOS) {
      if (image.format.group != ImageFormatGroup.bgra8888 || image.planes.length != 1) return null;
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    if (image.format.group != ImageFormatGroup.nv21 && image.format.group != ImageFormatGroup.yuv420) return null;
    final bytes = image.planes.length == 1
        ? image.planes.first.bytes
        : _concat(image.planes.map((p) => p.bytes));
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  static Uint8List _concat(Iterable<Uint8List> parts) {
    final total = parts.fold<int>(0, (sum, p) => sum + p.length);
    final out = Uint8List(total);
    var offset = 0;
    for (final part in parts) {
      out.setAll(offset, part);
      offset += part.length;
    }
    return out;
  }
}
