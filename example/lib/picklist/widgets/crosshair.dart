import 'package:flutter/material.dart';

class Crosshair extends StatelessWidget {
  const Crosshair({
    super.key,
    required this.scannerDisabled,
  });

  final bool scannerDisabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.close,
        color: scannerDisabled ? Colors.green : Colors.red,
      ),
    );
  }
}
