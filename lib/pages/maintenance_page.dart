import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/services.dart' show rootBundle;

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final ImagePicker _picker = ImagePicker();
  String result = "";
  File? pickedImage;
  String source = "";

  Future<void> detectObject() async {

    XFile? image;

    if (source == "Gallery"){
      image = await _picker.pickImage(source: ImageSource.gallery);
    }else if (source == "Camera"){
      image = await _picker.pickImage(source: ImageSource.camera);
    }


    if (image == null) return;

    setState(() {
      pickedImage = File(image!.path);
      result = "Processing...";
    });

    final inputImage = InputImage.fromFilePath(image.path);

    // 1. 配置 Firebase 模型下载器
    final modelName = 'Appliances';
    final response = await FirebaseModelDownloader.instance.getModel(
      modelName,
      FirebaseModelDownloadType.latestModel,
    );

    // 2. 获取下载模型的路径
    final modelPath = response.file.path;

    // 3. 使用 FirebaseImageLabelerOptions
    final options = LocalLabelerOptions(
      modelPath: modelPath,
      confidenceThreshold: 0.0,
    );

    final labeler = ImageLabeler(options: options);
    final List<ImageLabel> labels = await labeler.processImage(inputImage);

    String detected = labels.isNotEmpty ? labels.first.label : "Unknown";

    for (var label in labels) {
      print('>> Label: ${label.label}, Confidence: ${label.confidence}');
    }

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
        foregroundColor: Colors.white,
      ),

      backgroundColor: Colors.purple[50],

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: SizedBox(
                height: 60.0,
                child: ListTile(
                  leading: Icon(Icons.image, color: Colors.indigo,size: 50.0,),
                  title: Text('  Gallery',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),),
                  trailing: Icon(Icons.chevron_right, color: Colors.indigo),
                  onTap: (){
                    source = "Gallery";
                    detectObject();
                    },
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.all(20),
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
                  onTap: (){
                    source = "Camera";
                    detectObject();
                    },
                ),
              ),
            ),
            SizedBox(height: 20),
            pickedImage != null
                ? ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.file(pickedImage!, height: 200))
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