import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A dialog widget that allows users to select a [DetectionSpeed] value.
///
/// The [DetectionSpeed] value is chosen from a list of predefined options using
/// radio buttons. The selected value is returned when the user confirms their
/// choice.
class DetectionSpeedDialog extends StatelessWidget {
  /// Creates a [DetectionSpeedDialog].
  ///
  /// Requires a [selectedSpeed] which represents the currently selected speed
  /// option.
  const DetectionSpeedDialog({required this.selectedSpeed, super.key});

  /// The currently selected [DetectionSpeed] option.
  final DetectionSpeed selectedSpeed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Detection Speed'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioGroup<DetectionSpeed>(
            groupValue: selectedSpeed,
            onChanged: (DetectionSpeed? value) {
              if (value != null) {
                Navigator.pop(context, value);
              }
            },
            child: Column(
              children: [
                for (final speed in DetectionSpeed.values)
                  RadioListTile<DetectionSpeed>(
                    title: Text(speed.name),
                    value: speed,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
