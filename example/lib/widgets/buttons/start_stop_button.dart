import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StartStopButton extends StatelessWidget {
  const StartStopButton({required this.controller, super.key});

  final MobileScannerController controller;

  Future<void> onPressedStop() async {
    await controller.stop();
  }

  Future<void> onPressedStart() async {
    await controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return IconButton(
            color: Colors.white,
            icon: const Icon(Icons.play_arrow),
            iconSize: 32,
            onPressed: onPressedStart,
          );
        }

        return IconButton(
          color: Colors.white,
          icon: const Icon(Icons.stop),
          iconSize: 32,
          onPressed: onPressedStop,
        );
      },
    );
  }
}
