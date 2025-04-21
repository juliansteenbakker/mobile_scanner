import 'package:flutter/material.dart';

/// A dialog widget that allows users to set a detection timeout value in
/// milliseconds.
///
/// The timeout is selected using a slider, with values ranging from 0 to
/// 5000 ms. The selected value is returned when the user confirms their choice.
class DetectionTimeoutDialog extends StatefulWidget {
  /// Creates a [DetectionTimeoutDialog].
  ///
  /// Requires an [initialTimeoutMs] which is displayed as the default timeout
  /// value.
  const DetectionTimeoutDialog({required this.initialTimeoutMs, super.key});

  /// The initial timeout value in milliseconds.
  final int initialTimeoutMs;

  @override
  State<DetectionTimeoutDialog> createState() => _DetectionTimeoutDialogState();
}

class _DetectionTimeoutDialogState extends State<DetectionTimeoutDialog> {
  late int tempTimeout;

  @override
  void initState() {
    super.initState();
    tempTimeout = widget.initialTimeoutMs;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Detection Timeout (ms)'),
      content: SizedBox(
        height: 100,
        child: Column(
          children: [
            Slider(
              value: tempTimeout.toDouble(),
              max: 5000,
              divisions: 50,
              label: '$tempTimeout ms',
              onChanged: (double value) {
                setState(() {
                  tempTimeout = value.toInt();
                });
              },
            ),
            Text('$tempTimeout ms'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, tempTimeout);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
