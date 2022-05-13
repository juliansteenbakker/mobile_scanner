import 'dart:developer';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerFromImage extends StatefulWidget {
  const BarcodeScannerFromImage({Key? key}) : super(key: key);

  @override
  _BarcodeScannerFromImageState createState() =>
      _BarcodeScannerFromImageState();
}

class _BarcodeScannerFromImageState extends State<BarcodeScannerFromImage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Read from file')),
        body: Builder(builder: (context) {
          return SafeArea(
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _loading = true;
                        });
                        try {
                          if (Platform.isAndroid ||
                              Platform.isIOS ||
                              Platform.isMacOS) {
                            String? filePath;
                            if (Platform.isAndroid || Platform.isIOS) {
                              filePath = await _getFilePathMobile();
                            } else if (Platform.isMacOS) {
                              filePath = await _getFilePathMacOS();
                            }

                            if (filePath == null) {
                              _showMessage('No file selected.');
                            } else {
                              var barcodes = await MobileScannerTools.instance
                                  .readFromFile(filePath);

                              _showMessage(barcodes?.isNotEmpty == true
                                  ? barcodes!
                                      .map((element) => element.rawValue ?? '-')
                                      .toList()
                                      .join('\n')
                                  : 'Nothing found.');
                            }
                          } else {
                            _showMessage('Unsupported platform.');
                          }
                        } catch (e, s) {
                          log('Error while scanning data : $e $s');
                        }
                        setState(() {
                          _loading = false;
                        });
                      },
                      child: const Text('Analyze image'),
                    ),
            ),
          );
        }),
      ),
    );
  }

  Future<String?> _getFilePathMobile() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  Future<String?> _getFilePathMacOS() async {
    final typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'png']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    return file?.path;
  }

  _showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Result'),
          content: Text(message),
        );
      },
    );
  }
}
