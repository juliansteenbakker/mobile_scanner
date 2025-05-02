import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Button widget for switch camera function
class SwitchCameraButton extends StatelessWidget {
  /// Construct a new [SwitchCameraButton] instance.
  const SwitchCameraButton({required this.controller, super.key});

  /// Controller which is used to call switchCamera
  final MobileScannerController controller;

  Future<void> _onPressed() async => controller.switchCamera();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        final int? availableCameras = state.availableCameras;

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
          onPressed: _onPressed,
        );
      },
    );
  }
}
