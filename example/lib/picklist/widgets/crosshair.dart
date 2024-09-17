import 'package:flutter/material.dart';

class Crosshair extends StatelessWidget {
  const Crosshair({
    super.key,
    required this.scannerEnabled,
  });

  final bool scannerEnabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.close,
        color: scannerEnabled ? Colors.red : Colors.green,
      ),
    );
  }
}
