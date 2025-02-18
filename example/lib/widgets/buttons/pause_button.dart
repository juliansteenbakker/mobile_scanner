import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PauseButton extends StatelessWidget {
  const PauseButton({required this.controller, super.key});

  final MobileScannerController controller;

  Future<void> onPressed() async {
    await controller.pause();
  }

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
          onPressed: onPressed,
        );
      },
    );
  }
}
