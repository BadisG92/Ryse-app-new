import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget personnalisé pour les champs de saisie numérique
/// Ajoute automatiquement un bouton "Done" sur iOS pour fermer le clavier
class NumericTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final InputDecoration? decoration;
  final bool allowDecimals;
  final double? minValue;
  final double? maxValue;
  final FocusNode? focusNode;

  const NumericTextField({
    super.key,
    this.controller,
    this.hintText,
    this.style,
    this.textAlign = TextAlign.start,
    this.enabled = true,
    this.onChanged,
    this.onEditingComplete,
    this.decoration,
    this.allowDecimals = true,
    this.minValue,
    this.maxValue,
    this.focusNode,
  });

  @override
  State<NumericTextField> createState() => _NumericTextFieldState();
}

class _NumericTextFieldState extends State<NumericTextField> {
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && Platform.isIOS) {
      _showDoneButton();
    } else {
      _removeOverlay();
    }
  }

  void _showDoneButton() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 0,
        right: 0,
        child: _DoneButtonToolbar(
          onPressed: () {
            _focusNode.unfocus();
            widget.onEditingComplete?.call();
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.allowDecimals,
        signed: widget.minValue != null && widget.minValue! < 0,
      ),
      inputFormatters: _buildInputFormatters(),
      style: widget.style,
      textAlign: widget.textAlign,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
          ),
    );
  }

  List<TextInputFormatter> _buildInputFormatters() {
    final formatters = <TextInputFormatter>[];

    if (widget.allowDecimals) {
      // Permettre les décimales avec point ou virgule
      formatters.add(TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text.replaceAll(',', '.');
        if (text.isEmpty) return newValue;
        
        // Vérifier que c'est un nombre valide
        final number = double.tryParse(text);
        if (number == null) return oldValue;
        
        // Vérifier les limites
        if (widget.minValue != null && number < widget.minValue!) return oldValue;
        if (widget.maxValue != null && number > widget.maxValue!) return oldValue;
        
        return newValue.copyWith(text: text);
      }));
    } else {
      // Seulement les entiers
      formatters.add(FilteringTextInputFormatter.digitsOnly);
      formatters.add(TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        
        final number = int.tryParse(newValue.text);
        if (number == null) return oldValue;
        
        // Vérifier les limites
        if (widget.minValue != null && number < widget.minValue!) return oldValue;
        if (widget.maxValue != null && number > widget.maxValue!) return oldValue;
        
        return newValue;
      }));
    }

    return formatters;
  }
}

/// Toolbar avec bouton Done
class _DoneButtonToolbar extends StatelessWidget {
  final VoidCallback onPressed;

  const _DoneButtonToolbar({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onPressed,
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

