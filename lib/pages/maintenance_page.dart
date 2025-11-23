import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Map<String, String>? _tenantAsset;
  Future<void>? _assetLoadingFuture;

  @override
  void initState() {
    super.initState();
    _assetLoadingFuture = _loadTenantAsset();
  }

  Future<void> _loadTenantAsset() async {
    final user = FirebaseAuth.instance.currentUser;
    final tenantId = user?.uid;

    if (tenantId == null) {
      if (mounted) setState(() {});
      return;
    }

    try {
      final assetQuery = await FirebaseFirestore.instance
          .collection('assets')
          .where('tenantId', isEqualTo: tenantId)
          .limit(1)
          .get();

      if (assetQuery.docs.isNotEmpty) {
        final doc = assetQuery.docs.first;
        if (mounted) {
          setState(() {
            _tenantAsset = {
              'assetId': doc.id,
              'assetName': doc['name'] as String? ?? 'Your Property',
            };
          });
        }
      }
    } catch (e) {
      print("Error loading tenant asset: $e");
      if (mounted) setState(() => _tenantAsset = null);
    }
  }


  Future<void> detectObject() async {
    XFile? image;

    if (source == "Gallery"){
      image = await _picker.pickImage(source: ImageSource.gallery);
    }else if (source == "Camera"){
      image = await _picker.pickImage(source: ImageSource.camera);
    }

    if (image == null) return;

    if (_tenantAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot scan: No property assigned.')),
      );
      return;
    }

    setState(() {
      pickedImage = File(image!.path);
      result = "Processing...";
    });

    final inputImage = InputImage.fromFilePath(image.path);

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return FutureBuilder<void>(
      future: _assetLoadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final assetId = _tenantAsset?['assetId'];
        final assetName = _tenantAsset?['assetName'] ?? 'Maintenance';

        if (assetId == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Maintenance', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.indigo,
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Text(
                  'You have no assigned property. Please contact your Landlord.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('$assetName - Asset Scanner', style: const TextStyle(color: Colors.white),),
            centerTitle: true,
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),

          backgroundColor: Colors.purple[50],

          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: const EdgeInsets.only(top: 12, bottom: 8, left: 12, right: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  child: SizedBox(
                    height: 60.0,
                    child: ListTile(
                      leading: const Icon(Icons.image, color: Colors.indigo,size: 50.0,),
                      title: const Text('  Gallery',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),),
                      trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
                      onTap: (){
                        source = "Gallery";
                        detectObject();
                      },
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(top: 8, bottom: 12, left: 12, right: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  child: SizedBox(
                    height: 60.0,
                    child: ListTile(
                      leading: const Icon(Icons.view_in_ar, color: Colors.indigo,size: 50.0,),
                      title: const Text('  Scan Object',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),),
                      trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
                      onTap: (){
                        source = "Camera";
                        detectObject();
                      },
                    ),
                  ),
                ),

                if (pickedImage != null || result.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Column(
                      children: [
                        if (pickedImage != null)
                          ClipRRect(borderRadius: BorderRadius.circular(18.0), child: Image.file(pickedImage!, height: 150)),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              result.isEmpty ? "" : "Detected: $result",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Available Furniture Inventory',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
                Expanded(
                  child: FurnitureMaintenanceList(assetId: assetId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FurnitureMaintenanceList extends StatelessWidget {
  final String assetId;

  const FurnitureMaintenanceList({super.key, required this.assetId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assets')
          .doc(assetId)
          .collection('furniture')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error loading inventory: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final furnitureItems = snapshot.data!.docs;
        if (furnitureItems.isEmpty) return const Center(child: Text("No furniture listed for this property."));

        return ListView.builder(
          itemCount: furnitureItems.length,
          itemBuilder: (context, index) {
            final item = furnitureItems[index].data() as Map<String, dynamic>;
            final String imageUrl = item['imageUrl'] as String? ?? '';
            final String itemName = item['name'] ?? 'Item';
            final String condition = item['condition'] ?? 'N/A';
            final double price = item['price'] as double? ?? 0.0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.chair_outlined, size: 30, color: Colors.grey),
                    ),
                  )
                      : const Icon(Icons.chair, size: 40, color: Colors.grey),
                  title: Text(itemName),
                  subtitle: Text("Condition: $condition\nPrice: RM ${price.toStringAsFixed(2)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.build_circle, size: 35, color: Colors.red),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Report maintenance for: $itemName')),
                      );
                    },
                  ),
                  onTap: () {}
              ),
            );
          },
        );
      },
    );
  }
}