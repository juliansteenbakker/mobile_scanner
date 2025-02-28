import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Button widget for stop or start function
class StartStopButton extends StatelessWidget {
  /// Construct a new [StartStopButton] instance.
  const StartStopButton({required this.controller, super.key});

  /// Controller which is used to call stop or start
  final MobileScannerController controller;

  Future<void> _onPressedStop() async => controller.stop();

  Future<void> _onPressedStart() async => controller.start();

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
            onPressed: _onPressedStart,
          );
        }

        return IconButton(
          color: Colors.white,
          icon: const Icon(Icons.stop),
          iconSize: 32,
          onPressed: _onPressedStop,
        );
      },
    );
  }
}
