import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Button widget for switching between camera lens types
class SwitchLensButton extends StatefulWidget {
  /// Construct a new [SwitchLensButton] instance.
  const SwitchLensButton({
    required this.controller,
    required this.currentLensType,
    required this.onLensTypeChanged,
    super.key,
  });

  /// Controller to get supported lenses
  final MobileScannerController controller;

  /// Current lens type
  final CameraLensType currentLensType;

  /// Callback when lens type changes
  final ValueChanged<CameraLensType> onLensTypeChanged;

  @override
  State<SwitchLensButton> createState() => _SwitchLensButtonState();
}

class _SwitchLensButtonState extends State<SwitchLensButton> {
  List<CameraLensType> _availableLenses = [
    CameraLensType.normal,
    CameraLensType.wide,
    CameraLensType.zoom,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadSupportedLenses());
  }

  Future<void> _loadSupportedLenses() async {
    try {
      final Set<CameraLensType> supportedLenses =
          await widget.controller.getSupportedLenses();
      // Filter out 'any' from the list and keep only specific lens types
      final List<CameraLensType> specificLenses =
          supportedLenses.where((lens) => lens != CameraLensType.any).toList();

      if (specificLenses.isNotEmpty && mounted) {
        setState(() {
          _availableLenses = specificLenses;
        });
      }
    } on Exception {
      // Keep default list if there's an error
    }
  }

  CameraLensType _getNextLensType() {
    // Safety check: return 'any' if no lenses are available
    if (_availableLenses.isEmpty) {
      return CameraLensType.any;
    }

    final int currentIndex = _availableLenses.indexOf(widget.currentLensType);

    // If current lens is not in available lenses, return the first one
    if (currentIndex == -1) {
      return _availableLenses.first;
    }

    // Get next lens, wrapping around to the first if we're at the end
    final int nextIndex = (currentIndex + 1) % _availableLenses.length;
    return _availableLenses[nextIndex];
  }

  IconData _getLensIcon() {
    switch (widget.currentLensType) {
      case CameraLensType.normal:
        return Icons.camera;
      case CameraLensType.wide:
        return Icons.camera_outdoor;
      case CameraLensType.zoom:
        return Icons.zoom_in;
      case CameraLensType.any:
        return Icons.camera_alt;
    }
  }

  String _getLensLabel() {
    switch (widget.currentLensType) {
      case CameraLensType.normal:
        return 'Normal';
      case CameraLensType.wide:
        return 'Wide';
      case CameraLensType.zoom:
        return 'Zoom';
      case CameraLensType.any:
        return 'Any';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show button if there are multiple lens options available
    if (_availableLenses.length < 2) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: () => widget.onLensTypeChanged(_getNextLensType()),
      icon: Icon(_getLensIcon(), color: Colors.white, size: 32),
      label: Text(
        _getLensLabel(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
