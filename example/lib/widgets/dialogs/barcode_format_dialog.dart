import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Import BarcodeFormat

class BarcodeFormatDialog extends StatefulWidget {
  const BarcodeFormatDialog({required this.selectedFormats, super.key});
  final List<BarcodeFormat> selectedFormats;

  @override
  _BarcodeFormatDialogState createState() => _BarcodeFormatDialogState();
}

class _BarcodeFormatDialogState extends State<BarcodeFormatDialog> {
  late List<BarcodeFormat> tempSelectedFormats;

  @override
  void initState() {
    super.initState();
    tempSelectedFormats = List<BarcodeFormat>.from(widget.selectedFormats);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Barcode Formats'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: BarcodeFormat.values.map((format) {
            return CheckboxListTile(
              title: Text(format.name.toUpperCase()),
              value: tempSelectedFormats.contains(format),
              onChanged: (bool? value) {
                setState(() {
                  if (value ?? false) {
                    tempSelectedFormats.add(format);
                  } else {
                    tempSelectedFormats.remove(format);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, tempSelectedFormats);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
