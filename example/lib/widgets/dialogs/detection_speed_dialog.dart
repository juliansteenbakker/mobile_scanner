import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A dialog widget that allows users to select a detection speed for the
/// scanner.
///
/// The detection speed is chosen from a predefined set of options using radio
/// buttons. Once the user selects a speed, the dialog closes and returns the
/// selected value.
class DetectionSpeedDialog extends StatelessWidget {
  /// Creates a [DetectionSpeedDialog].
  ///
  /// Requires a [selectedSpeed] which represents the currently chosen speed.
  const DetectionSpeedDialog({required this.selectedSpeed, super.key});

  /// The currently selected detection speed.
  final DetectionSpeed selectedSpeed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Detection Speed'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final speed in DetectionSpeed.values)
            RadioListTile<DetectionSpeed>(
              title: Text(speed.name),
              value: speed,
              groupValue: selectedSpeed,
              onChanged: (DetectionSpeed? value) {
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
            ),
        ],
      ),
    );
  }
}
