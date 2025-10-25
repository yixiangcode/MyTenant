import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final ImagePicker _picker = ImagePicker();
  String result = "";
  File? pickedImage;

  Future<void> detectObject() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    setState(() {
      pickedImage = File(image.path);
      result = "Processing...";
    });

    final inputImage = InputImage.fromFilePath(image.path);

    // 🔹 使用 ML Kit Image Labeling
    final options = ImageLabelerOptions(confidenceThreshold: 0.6);
    final labeler = ImageLabeler(options: options);

    final List<ImageLabel> labels = await labeler.processImage(inputImage);

    String detected = labels.isNotEmpty ? labels.first.label : "Unknown";

    setState(() {
      result = detected;
    });

    await labeler.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Scanner', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      backgroundColor: const Color(0xFFF2F4F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: SizedBox(
                height: 60.0,
                child: ListTile(
                  leading: Icon(Icons.view_in_ar, color: Colors.indigo,size: 50.0,),
                  title: Text('  Scan Object',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),),
                  trailing: Icon(Icons.chevron_right, color: Colors.indigo),
                  onTap: detectObject,
                ),
              ),
            ),
            SizedBox(height: 20),
            pickedImage != null
                ? Image.file(pickedImage!, height: 200)
                : Container(),
            SizedBox(height: 20),
            Text(
              result.isEmpty ? "" : "Detected: $result",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
