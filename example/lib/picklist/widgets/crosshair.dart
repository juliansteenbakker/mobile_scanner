import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Crosshair extends StatelessWidget {
  const Crosshair(
    this.scannerEnabled, {
    super.key,
  });

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
