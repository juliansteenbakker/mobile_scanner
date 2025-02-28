import 'package:flutter/material.dart';

class DetectionTimeoutDialog extends StatefulWidget {
  const DetectionTimeoutDialog({required this.initialTimeoutMs, super.key});
  final int initialTimeoutMs;

  @override
  _DetectionTimeoutDialogState createState() => _DetectionTimeoutDialogState();
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
