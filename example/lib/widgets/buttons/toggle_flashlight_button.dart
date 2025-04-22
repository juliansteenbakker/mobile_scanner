import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Button widget for toggle torch (flash) function
class ToggleFlashlightButton extends StatelessWidget {
  /// Construct a new [ToggleFlashlightButton] instance.
  const ToggleFlashlightButton({required this.controller, super.key});

  /// Controller which is used to call toggleTorch
  final MobileScannerController controller;

  Future<void> _onPressed() async => controller.toggleTorch();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        switch (state.torchState) {
          case TorchState.auto:
            return IconButton(
              color: Colors.white,
              iconSize: 32,
              icon: const Icon(Icons.flash_auto),
              onPressed: _onPressed,
            );
          case TorchState.off:
            return IconButton(
              color: Colors.white,
              iconSize: 32,
              icon: const Icon(Icons.flash_off),
              onPressed: _onPressed,
            );
          case TorchState.on:
            return IconButton(
              color: Colors.white,
              iconSize: 32,
              icon: const Icon(Icons.flash_on),
              onPressed: _onPressed,
            );
          case TorchState.unavailable:
            return const SizedBox.square(
              dimension: 48,
              child: Icon(Icons.no_flash, size: 32, color: Colors.grey),
            );
        }
      },
    );
  }
}
