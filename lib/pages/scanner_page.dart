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
  String _fullText = '';
  String _nameText = '';
  String _icText = '';
  String _dateText = '';
  String _addressText = '';
  String _amountText = '';
  String _documentType = '';

  final ImagePicker _picker = ImagePicker();
  final textRecognizer = TextRecognizer();

  final TextEditingController icCtrl = TextEditingController();

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
    final addressRegex = RegExp(r'(NO\s\d+\s[A-Z\s\d]+?\s\d{5}\s[A-Z\s]+)');
    final nameRegex = RegExp(r'\b([A-Z]+\s?){2,4}\b');

    String amount = amountRegex.firstMatch(text)?.group(0) ?? "";
    String date = dateRegex.firstMatch(text)?.group(0) ?? "";
    String ic = icRegex.firstMatch(text)?.group(0) ?? "";
    String address = addressRegex.firstMatch(text)?.group(0) ?? "";
    String name = nameRegex.firstMatch(text)?.group(0) ?? "";

    setState(() {
      if (_documentType == 'Identity Card'){
        _icText = ic;
        _nameText = name.replaceAll('PENGENALAN', '');
        _addressText = address;
      }else if(_documentType == 'Bill'){
        _nameText = name;
        _dateText = date;
        _amountText = amount;
      }else if(_documentType == 'Contract'){
        _nameText = name;
        _icText = ic;
        _dateText = date;
      }
      _fullText =
          "Full Text:\n$text\n\n\n";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Document Scanner',
          style: TextStyle(color: Colors.white),
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

              if (_fullText.isEmpty)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: (){
                        _documentType = 'Identity Card';
                        _pickImage();
                      },
                      child: Text("Identity Card"),
                    ),
                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: (){
                        _documentType = 'Contract';
                        _pickImage();
                      },
                      child: Text("Contract"),
                    ),
                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: (){
                        _documentType = 'Bill';
                        _pickImage();
                      },
                      child: Text("Bill"),
                    ),
                    SizedBox(height: 20),
                  ],
                ),

              if (_nameText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                    child: ListTile(
                      leading: Icon(Icons.badge, color: Colors.deepPurple),
                      title: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        _nameText,
                        style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 15.0),
                      ),
                    ),
                  ),
                ),

              if (_icText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                    child: ListTile(
                      leading: Icon(Icons.badge, color: Colors.deepPurple),
                      title: Text('IC Number', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        _icText,
                        style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 15.0),
                      ),
                    ),
                  ),
                ),

              if (_addressText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                    child: ListTile(
                      leading: Icon(Icons.badge, color: Colors.deepPurple),
                      title: Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        _addressText,
                        style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 15.0),
                      ),
                    ),
                  ),
                ),

              if (_amountText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                    child: ListTile(
                      leading: Icon(Icons.badge, color: Colors.deepPurple),
                      title: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        _amountText,
                        style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 15.0),
                      ),
                    ),
                  ),
                ),

              if (_dateText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                    child: ListTile(
                      leading: Icon(Icons.badge, color: Colors.deepPurple),
                      title: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        _dateText,
                        style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 15.0),
                      ),
                    ),
                  ),
                ),

              if (_fullText.isNotEmpty)
                Column(
                  children: [
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,

                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Full Recognized Text'),
                              content: Text(_fullText),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('Full Recognized Text'),
                    ),
                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                      },
                      child: Text("Back"),
                    ),
                    SizedBox(height: 20),
                  ],
                ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
