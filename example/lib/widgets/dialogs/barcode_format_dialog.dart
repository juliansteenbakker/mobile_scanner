import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A dialog widget that allows users to select multiple barcode formats.
///
/// The user can choose from a list of predefined barcode formats using
/// checkboxes. The selected formats are returned when the user confirms their
/// choice.
class BarcodeFormatDialog extends StatefulWidget {
  /// Creates a [BarcodeFormatDialog].
  ///
  /// Requires a list of [selectedFormats] that represents the currently
  /// selected barcode formats.
  const BarcodeFormatDialog({required this.selectedFormats, super.key});

  /// The list of currently selected [BarcodeFormat] options.
  final List<BarcodeFormat> selectedFormats;

  @override
  State<BarcodeFormatDialog> createState() => _BarcodeFormatDialogState();
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
          children:
              BarcodeFormat.values.map((format) {
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
