import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays a crosshair widget in the center of the screen, and reacts to
/// scanner being enabled or not.
class CrosshairWidget extends StatelessWidget {
  /// Construct a new [CrosshairWidget] instance.
  const CrosshairWidget(this.scannerEnabled, {super.key});

  /// Listener for if scanner is enabled or not
  final ValueListenable<bool> scannerEnabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: scannerEnabled,
      builder: (context, value, child) {
        return Center(
          child: Icon(
            Icons.close,
            color: scannerEnabled.value ? Colors.red : Colors.green,
          ),
        );
      },
    );
  }
}
