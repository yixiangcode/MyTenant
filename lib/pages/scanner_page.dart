import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 30);
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
      if (_documentType == 'Identity Card') {
        _icText = ic;
        if (ic.isNotEmpty) {
          int icStartIndex = text.indexOf(ic);
          if (icStartIndex != -1) {
            int searchStartIndex = icStartIndex + ic.length;
            String subText = text.substring(searchStartIndex);
            name = nameRegex.firstMatch(subText)?.group(0) ?? "";
          }
        } else {
          name = nameRegex.firstMatch(text)?.group(0) ?? "";
        }

        _nameText = name
            .replaceAll('KAD', '')
            .replaceAll('PENGENALAN', '')
            .replaceAll('MALAYSIA', '')
            .replaceAll('NO', '')
            .trim();
        _addressText = address;
      } else if (_documentType == 'Bill') {
        _dateText = date;
        _amountText = amount;
      } else if (_documentType == 'Contract') {
        _nameText = name
            .replaceAll('AND', '')
            .replaceAll('THE', '')
            .replaceAll('TENANT', '')
            .replaceAll('LANDLORD', '')
            .replaceAll('FOR', '')
            .replaceAll('RENTAL', '')
            .replaceAll('PREMISE', '')
            .trim();
        _icText = ic;
        _dateText = date;
        _addressText = address;
      }
      _fullText = "Full Text:\n$text\n\n\n";
    });
  }

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController icCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  bool _isEditing = false;

  void showEditDialog() {
    nameCtrl.text = _nameText;
    addressCtrl.text = _addressText;
    icCtrl.text = _icText;
    amountCtrl.text = _amountText;
    dateCtrl.text = _dateText;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    showDialog(
      context: context,

      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  if (_nameText.isNotEmpty)...[
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),),
                    ),
                  const SizedBox(height: 15),
                  ],

                  if (_addressText.isNotEmpty)...[
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(labelText: "Address", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),),
                      maxLines: 2,
                      keyboardType: TextInputType.multiline,
                    ),
                  const SizedBox(height: 15),
                  ],

                  if (_icText.isNotEmpty)...[
                    TextField(
                      controller: icCtrl,
                      decoration: InputDecoration(labelText: "IC Number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),),
                      keyboardType: TextInputType.number,
                    ),
                  const SizedBox(height: 15),
                  ],

                  if (_amountText.isNotEmpty)...[
                    TextField(
                      controller: amountCtrl,
                      decoration: InputDecoration(labelText: "Amount", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),),
                    ),
                  const SizedBox(height: 15),
                  ],

                  if (_dateText.isNotEmpty)
                    TextField(
                      controller: dateCtrl,
                      decoration: InputDecoration(labelText: "Date", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              // **添加加载状态显示**
              _isEditing
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        if (uid == null) return;

                        setDialogState(() {
                          _isEditing = true;
                        });

                        String fileName = 'assets/${DateTime.now().millisecondsSinceEpoch}.jpg';
                        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

                        await storageRef.putFile(_image!);

                        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

                        String? icImageUrl;
                        String? contractImageUrl;
                        String? billImageUrl;

                        if(_documentType == 'Identity Card'){
                          String? oldIcImageUrl = userDoc.get('icImageUrl') as String?;

                          icImageUrl = await storageRef.getDownloadURL();

                          if (oldIcImageUrl != null && oldIcImageUrl.isNotEmpty) {
                            try {
                              Reference oldRef = FirebaseStorage.instance.refFromURL(oldIcImageUrl);
                              await oldRef.delete();
                            } catch (e) {
                              print('Error deleting old image: $e');
                            }
                          }
                        }

                        if(_documentType == "Contract"){
                          String? oldContractImageUrl = userDoc.get('contractImageUrl') as String?;

                          contractImageUrl = await storageRef.getDownloadURL();

                          if (oldContractImageUrl != null && oldContractImageUrl.isNotEmpty) {
                            try {
                              Reference oldRef = FirebaseStorage.instance.refFromURL(oldContractImageUrl);
                              await oldRef.delete();
                            } catch (e) {
                              print('Error deleting old image: $e');
                            }
                          }
                        }

                        if(_documentType == "Bill"){
                          String? oldBillImageUrl = userDoc.get('billImageUrl') as String?;

                          billImageUrl = await storageRef.getDownloadURL();

                          if (oldBillImageUrl != null && oldBillImageUrl.isNotEmpty) {
                            try {
                              Reference oldRef = FirebaseStorage.instance.refFromURL(oldBillImageUrl);
                              await oldRef.delete();
                            } catch (e) {
                              print('Error deleting old image: $e');
                            }
                          }
                        }


                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                              if (_nameText.isNotEmpty)
                                'name': nameCtrl.text.trim(),
                              if (_icText.isNotEmpty)
                                'ic': icCtrl.text.trim(),
                              if (_addressText.isNotEmpty)
                                'address': addressCtrl.text.trim(),
                              if (_dateText.isNotEmpty)
                                'date': dateCtrl.text.trim(),
                              if (_documentType == 'Identity Card')
                                'icImageUrl': icImageUrl,
                              if (_documentType == 'Contract')
                                'contractImageUrl': contractImageUrl,
                              if (_documentType == 'Bill')
                                'billImageUrl': billImageUrl,
                            });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                          ),
                        );

                        Navigator.pop(context);

                        setState(() {
                          _isEditing = false;
                          _nameText = nameCtrl.text.trim();
                          _icText = icCtrl.text.trim();
                          _addressText = addressCtrl.text.trim();
                          _dateText = dateCtrl.text.trim();
                        });
                      },
                      child: const Text("Save"),
                    ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Document Scanner',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      backgroundColor: const Color(0xFFF2F4F7),
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
                    Card(
                      margin: const EdgeInsets.all(25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      child: SizedBox(
                        height: 60.0,
                        child: ListTile(
                          leading: Icon(
                            Icons.badge,
                            color: Colors.indigo,
                            size: 50.0,
                          ),
                          title: Text(
                            ' Identity Card',
                            style: TextStyle(
                              fontSize: 26,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.indigo,
                          ),
                          onTap: () {
                            _documentType = 'Identity Card';
                            _pickImage();
                          },
                        ),
                      ),
                    ),

                    Card(
                      margin: const EdgeInsets.all(25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      child: SizedBox(
                        height: 60.0,
                        child: ListTile(
                          leading: Icon(
                            Icons.description,
                            color: Colors.indigo,
                            size: 50.0,
                          ),
                          title: Text(
                            ' Contract',
                            style: TextStyle(
                              fontSize: 26,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.indigo,
                          ),
                          onTap: () {
                            _documentType = 'Contract';
                            _pickImage();
                          },
                        ),
                      ),
                    ),

                    Card(
                      margin: const EdgeInsets.all(25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      child: SizedBox(
                        height: 60.0,
                        child: ListTile(
                          leading: Icon(
                            Icons.receipt_long,
                            color: Colors.indigo,
                            size: 50.0,
                          ),
                          title: Text(
                            ' Bill',
                            style: TextStyle(
                              fontSize: 26,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.indigo,
                          ),
                          onTap: () {
                            _documentType = 'Bill';
                            _pickImage();
                          },
                        ),
                      ),
                    ),
                  ],
                ),

              if (_nameText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                    child: ListTile(
                      leading: Icon(Icons.account_box, color: Colors.deepPurple),
                      title: Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        _nameText,
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontSize: 15.0,
                        ),
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
                      title: Text(
                        'IC Number',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        _icText,
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontSize: 15.0,
                        ),
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
                      leading: Icon(Icons.location_on, color: Colors.deepPurple),
                      title: Text(
                        'Address',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _addressText,
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontSize: 15.0,
                        ),
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
                      leading: Icon(Icons.money, color: Colors.deepPurple),
                      title: Text(
                        'Amount',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        _amountText,
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontSize: 15.0,
                        ),
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
                      leading: Icon(Icons.calendar_month, color: Colors.deepPurple),
                      title: Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        _dateText,
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontSize: 15.0,
                        ),
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
                      child: const Text('Full Recognized Text (Testing Purpose)'),
                    ),
                    SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: showEditDialog,
                      child: Text("Edit"),
                    ),
                    SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () async {
                        if (uid == null) return;

                        String fileName = 'assets/${DateTime.now().millisecondsSinceEpoch}.jpg';
                        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

                        await storageRef.putFile(_image!);

                        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

                        String? icImageUrl;
                        String? contractImageUrl;
                        String? billImageUrl;

                        if(_documentType == 'Identity Card'){
                          String? oldIcImageUrl = userDoc.get('icImageUrl') as String?;

                          icImageUrl = await storageRef.getDownloadURL();

                          if (oldIcImageUrl != null && oldIcImageUrl.isNotEmpty) {
                            try {
                              Reference oldRef = FirebaseStorage.instance.refFromURL(oldIcImageUrl);
                              await oldRef.delete();
                            } catch (e) {
                              print('Error deleting old image: $e');
                            }
                          }
                        }

                        if(_documentType == "Contract"){
                          String? oldContractImageUrl = userDoc.get('contractImageUrl') as String?;

                          contractImageUrl = await storageRef.getDownloadURL();

                          if (oldContractImageUrl != null && oldContractImageUrl.isNotEmpty) {
                            try {
                              Reference oldRef = FirebaseStorage.instance.refFromURL(oldContractImageUrl);
                              await oldRef.delete();
                            } catch (e) {
                              print('Error deleting old image: $e');
                            }
                          }
                        }

                        if(_documentType == "Bill"){
                          String? oldBillImageUrl = userDoc.get('billImageUrl') as String?;

                          billImageUrl = await storageRef.getDownloadURL();

                          if (oldBillImageUrl != null && oldBillImageUrl.isNotEmpty) {
                            try {
                              Reference oldRef = FirebaseStorage.instance.refFromURL(oldBillImageUrl);
                              await oldRef.delete();
                            } catch (e) {
                              print('Error deleting old image: $e');
                            }
                          }
                        }


                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                          if (_nameText.isNotEmpty)
                            'name': nameCtrl.text.trim(),
                          if (_icText.isNotEmpty)
                            'ic': icCtrl.text.trim(),
                          if (_addressText.isNotEmpty)
                            'address': addressCtrl.text.trim(),
                          if (_dateText.isNotEmpty)
                            'date': dateCtrl.text.trim(),
                          if (_documentType == 'Identity Card')
                            'icImageUrl': icImageUrl,
                          if (_documentType == 'Contract')
                            'contractImageUrl': contractImageUrl,
                          if (_documentType == 'Bill')
                            'billImageUrl': billImageUrl,
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                          ),
                        );

                        Navigator.pop(context);

                        setState(() {
                          _isEditing = false;
                          _nameText = nameCtrl.text.trim();
                          _icText = icCtrl.text.trim();
                          _addressText = addressCtrl.text.trim();
                          _dateText = dateCtrl.text.trim();
                        });
                      },
                      child: const Text("Save"),
                    ),
                    SizedBox(height: 10),
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
