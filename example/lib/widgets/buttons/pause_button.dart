import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Button widget for pause function
class PauseButton extends StatelessWidget {
  /// Construct a new [PauseButton] instance.
  const PauseButton({required this.controller, super.key});

  /// Controller which is used to call pause
  final MobileScannerController controller;

  Future<void> _onPressed() async => controller.pause();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        return IconButton(
          color: Colors.white,
          iconSize: 32,
          icon: const Icon(Icons.pause),
          onPressed: _onPressed,
        );
      },
    );
  }
}
