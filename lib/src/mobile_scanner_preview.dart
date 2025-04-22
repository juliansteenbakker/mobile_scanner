import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A widget showing a live camera preview.
class CameraPreview extends StatelessWidget {
  /// Creates a preview widget for the given camera controller.
  const CameraPreview(this.controller, {super.key});

  /// The controller for the camera that the preview is shown for.
  final MobileScannerController controller;

  /// Maps the different device orientations to quarter turns that the
  /// preview should take in account.
  static const Map<DeviceOrientation, int> turns = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeRight: 1,
    DeviceOrientation.portraitDown: 2,
    DeviceOrientation.landscapeLeft: 3,
  };

  @override
  Widget build(BuildContext context) {
    return controller.value.isInitialized
        ? ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (BuildContext context, MobileScannerState value, Widget? child) {
              final bool isLandscape =  _isLandscape();
              return SizedBox(
                width: isLandscape ? value.size.height : value.size.width,
                height: isLandscape ? value.size.width : value.size.height,
                child: _wrapInRotatedBox(child: controller.buildCameraView()),
              );
            },
          )
        : const SizedBox();
  }

  Widget _wrapInRotatedBox({required Widget child}) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return child;
    }
    final turns =  _getQuarterTurns();
    return RotatedBox(
      quarterTurns: turns,
      child: child,
    );
  }

  bool _isLandscape() {
    return <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ].contains(_getApplicableOrientation());
  }

  int _getQuarterTurns() {
    return turns[_getApplicableOrientation()]!;
  }

  DeviceOrientation _getApplicableOrientation() {
    return controller.value.deviceOrientation;
  }
}
