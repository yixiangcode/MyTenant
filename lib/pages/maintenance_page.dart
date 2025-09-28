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

    String detected = labels.isNotEmpty ? labels.first.label : "Unknown object";

    setState(() {
      result = detected;
    });

    await labeler.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detect Object")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: detectObject,
              child: Text("Scan Object"),
            ),
            SizedBox(height: 20),
            pickedImage != null
                ? Image.file(pickedImage!, height: 200)
                : Container(),
            SizedBox(height: 20),
            Text(
              result.isEmpty ? "No result yet" : "Detected: $result",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
