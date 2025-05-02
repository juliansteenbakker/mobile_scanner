import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Slider widget for zoom function
class ZoomScaleSlider extends StatelessWidget {
  /// Slider widget for zoom function
  const ZoomScaleSlider({required this.controller, super.key});

  /// Controller which is used to call the zoom function
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        final TextStyle labelStyle = Theme.of(
          context,
        ).textTheme.headlineMedium!.copyWith(color: Colors.white);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text('0%', overflow: TextOverflow.fade, style: labelStyle),
              Expanded(
                child: Slider(
                  value: state.zoomScale,
                  onChanged: controller.setZoomScale,
                ),
              ),
              Text('100%', overflow: TextOverflow.fade, style: labelStyle),
            ],
          ),
        );
      },
    );
  }
}
