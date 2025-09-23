import 'package:flutter/material.dart';

/// A dialog widget that allows users to select a [BoxFit] value.
///
/// The [BoxFit] value is chosen from a list of predefined options using radio
/// buttons. The selected value is returned when the user confirms their choice.
class BoxFitDialog extends StatefulWidget {
  /// Creates a [BoxFitDialog].
  ///
  /// Requires a [selectedBoxFit] which represents the currently selected fit
  /// option.
  const BoxFitDialog({required this.selectedBoxFit, super.key});

  /// The currently selected [BoxFit] option.
  final BoxFit selectedBoxFit;

  @override
  State<BoxFitDialog> createState() => _BoxFitDialogState();
}

class _BoxFitDialogState extends State<BoxFitDialog> {
  late BoxFit tempBoxFit;

  @override
  void initState() {
    super.initState();
    tempBoxFit = widget.selectedBoxFit;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select BoxFit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioGroup<BoxFit>(
            groupValue: tempBoxFit,
            onChanged: (BoxFit? value) {
              if (value != null) {
                setState(() {
                  tempBoxFit = value;
                });
              }
            },
            child: Column(
              children: [
                for (final fit in BoxFit.values)
                  RadioListTile<BoxFit>(title: Text(fit.name), value: fit),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, tempBoxFit);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
