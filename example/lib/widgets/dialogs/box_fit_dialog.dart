import 'package:flutter/material.dart';

class BoxFitDialog extends StatefulWidget {
  const BoxFitDialog({required this.selectedBoxFit, super.key});
  final BoxFit selectedBoxFit;

  @override
  _BoxFitDialogState createState() => _BoxFitDialogState();
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
          for (final fit in BoxFit.values)
            RadioListTile<BoxFit>(
              title: Text(fit.name),
              value: fit,
              groupValue: tempBoxFit,
              onChanged: (BoxFit? value) {
                if (value != null) {
                  setState(() {
                    tempBoxFit = value;
                  });
                }
              },
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
