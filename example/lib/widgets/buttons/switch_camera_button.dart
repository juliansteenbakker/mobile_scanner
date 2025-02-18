import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SwitchCameraButton extends StatelessWidget {
  const SwitchCameraButton({required this.controller, super.key});

  final MobileScannerController controller;

  Future<void> onPressed() async {
    await controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        final availableCameras = state.availableCameras;

        if (availableCameras != null && availableCameras < 2) {
          return const SizedBox.shrink();
        }

        final Widget icon;

        switch (state.cameraDirection) {
          case CameraFacing.front:
            icon = const Icon(Icons.camera_front);
          case CameraFacing.back:
            icon = const Icon(Icons.camera_rear);
          case CameraFacing.external:
            icon = const Icon(Icons.usb);
          case CameraFacing.unknown:
            icon = const Icon(Icons.device_unknown);
        }

        return IconButton(
          color: Colors.white,
          iconSize: 32,
          icon: icon,
          onPressed: onPressed,
        );
      },
    );
  }
}
