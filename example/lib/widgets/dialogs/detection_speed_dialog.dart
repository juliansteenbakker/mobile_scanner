import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DetectionSpeedDialog extends StatelessWidget {
  const DetectionSpeedDialog({required this.selectedSpeed, super.key});
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
