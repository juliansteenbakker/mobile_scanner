import 'package:flutter/material.dart';

/// A dialog widget that allows users to input and set a camera resolution.
///
/// The dialog presents two text fields where users can enter width and height
/// values. The resolution is validated to ensure it is within a reasonable
/// range before being returned to the calling widget.
class ResolutionDialog extends StatefulWidget {
  /// Creates a [ResolutionDialog].
  ///
  /// Requires an [initialResolution] which serves as the default width and
  /// height values displayed in the text fields.
  const ResolutionDialog({required this.initialResolution, super.key});

  /// The initial resolution size (width and height) that appears in the dialog.
  final Size initialResolution;

  @override
  State<ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<ResolutionDialog> {
  late TextEditingController widthController;
  late TextEditingController heightController;

  @override
  void initState() {
    super.initState();
    widthController = TextEditingController(
      text: widget.initialResolution.width.toInt().toString(),
    );
    heightController = TextEditingController(
      text: widget.initialResolution.height.toInt().toString(),
    );
  }

  @override
  void dispose() {
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void _saveResolution(BuildContext context) {
    final String widthText = widthController.text.trim();
    final String heightText = heightController.text.trim();

    // Check for empty input
    if (widthText.isEmpty || heightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Width and Height cannot be empty')),
      );
      return;
    }

    final int? width = int.tryParse(widthText);
    final int? height = int.tryParse(heightText);

    // Check if values are valid numbers
    if (width == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    // Ensure values are within a reasonable range
    if (width <= 144 || height <= 144) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Width and Height must be greater than 144'),
        ),
      );
      return;
    }

    if (width > 4000 || height > 4000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Width and Height must be 4000 or less')),
      );
      return;
    }

    // Return the new resolution size
    Navigator.pop(context, Size(width.toDouble(), height.toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Camera Resolution'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widthController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Width'),
          ),
          TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Height'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _saveResolution(context),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
