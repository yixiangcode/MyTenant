import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  File? _image;
  String _recognizedText = "";

  final ImagePicker _picker = ImagePicker();
  final textRecognizer = TextRecognizer();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _processImage(_image!);
    }
  }

  Future<void> _processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    String text = recognizedText.text;

    final amountRegex = RegExp(r'RM\s?\d+(\.\d{2})?');
    final dateRegex = RegExp(
      r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}\s+[a-zA-Z]{3,4}\s+\d{4})\b',
      caseSensitive: false,
    );
    final icRegex = RegExp(r'\b\d{6}-\d{2}-\d{4}\b', caseSensitive: false);
    final addressRegex = RegExp(
      r'(NO|LOT|UNIT)\s?\d+.*?(\s(JALAN|TAMAN|LORONG)\s+[A-Z\d\s]+)+',
      caseSensitive: false,
      dotAll: true,
    );
    final nameRegex = RegExp(r'\b[A-Z\s]{3}\b');
    final nameRegexLine = RegExp(r'^([A-Z]+\s?){2,}$');

    String amount = amountRegex.firstMatch(text)?.group(0) ?? "Not found";
    String date = dateRegex.firstMatch(text)?.group(0) ?? "Not found";
    String ic = icRegex.firstMatch(text)?.group(0) ?? "Not found";
    String address = addressRegex.firstMatch(text)?.group(0) ?? "Not found";
    String name = nameRegex.firstMatch(text)?.group(0) ?? "Not found";
    String nameLine = nameRegexLine.firstMatch(text)?.group(0) ?? "Not found";

    setState(() {
      _recognizedText =
          "Full Text:\n$text\n\n\nAmount: $amount\nDate: $date\nIC: $ic\nAddress: $address\nName: $name\nNameLine: $nameLine\n\n\n";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner', style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null) Image.file(_image!),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text("Scan Document"),
              ),
              SizedBox(height: 20),
              Text(_recognizedText),
            ],
          ),
        ),
      ),
    );
  }
}
