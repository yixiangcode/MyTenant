import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:tenant/pages/professional_page.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';

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
  final TextEditingController searchCtrl = TextEditingController();

  Map<String, String>? _tenantAsset;
  Future<void>? _assetLoadingFuture;

  bool _isSearching = false;
  bool _isLoading = false;

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

  String getRepairKeyword(String label) {
    label = label.toLowerCase();

    if (label.contains("sink") || label.contains("flush_toilet") || label.contains("squat_toilet")) {
      return "plumber";
    } else if (label.contains("cassette_aircond") || label.contains("wall_aircond")) {
      return "aircond";
    } else if (label.contains("fluorescent_lamp") || label.contains("led_lamp")) {
      return "lamp";
    } else if (label.contains("wall_fan") || label.contains("ceiling_fan")) {
      return "fan";
    }else if(label.contains("door_knob")){
      return "door_lock";
    } else if (label.contains("distribution_board")) {
      return "electrician";
    } else {
      return label;
    }
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );
  }


  Future<List<dynamic>> searchNearbyRepairShops(String keyword) async {
    const apiKey = "";

    Position pos = await _getLocation();

    final url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=${pos.latitude},${pos.longitude}"
        "&radius=3000"
        "&keyword=$keyword"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    return data["results"];
  }

  Future<void> detectObject() async {
    XFile? image;

    if (source == "Gallery"){
      image = await _picker.pickImage(source: ImageSource.gallery);
    }else if (source == "Camera"){
      image = await _picker.pickImage(source: ImageSource.camera);
    }

    if (image == null) return;

    /*
    if (_tenantAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot scan: No property assigned.')),
      );
      return;
    }
    */

    setState(() {
      pickedImage = File(image!.path);
      result = "Loading...";
    });

    final inputImage = InputImage.fromFilePath(image.path);


    final modelName = 'Appliances';
    final response = await FirebaseModelDownloader.instance.getModel(
      modelName,
      FirebaseModelDownloadType.latestModel,
    );

    final modelPath = response.file.path;

    final options = LocalLabelerOptions(
      modelPath: modelPath,
      confidenceThreshold: 0.2,
    );


    final labeler = ImageLabeler(options: options);

    final List<ImageLabel> labels = await labeler.processImage(inputImage);

    result = labels.isNotEmpty ? labels.first.label : "Unknown";

    setState(() {
      result = result;
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
          return Scaffold(
            appBar: AppBar(
              title: const Text('Asset Problem Scanner', style: TextStyle(color: Colors.white),),
              centerTitle: true,
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            backgroundColor: Colors.purple[50],
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final assetId = _tenantAsset?['assetId'];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Asset Problem Scanner', style: TextStyle(color: Colors.white),),
            centerTitle: true,
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),

          backgroundColor: Colors.purple[50],

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8.0,),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: "Search professionals...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10.0,),
                    ElevatedButton(
                        onPressed: _isSearching ? null : () async{
                          try {
                            if(searchCtrl.text.trim().isEmpty){
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please search the keyword first.")),
                              );
                            }else{
                              setState(() {
                                _isSearching = true;
                              });

                              List<dynamic> shops = await searchNearbyRepairShops(searchCtrl.text.trim());

                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProfessionalPage(shops: shops)),
                              );
                            }

                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error finding repair shops: $e")),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isSearching = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          minimumSize: const Size(50, 50),
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                        child: _isSearching
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
                        )
                            : const Icon(Icons.search_rounded, size: 30, color: Colors.indigo,)
                    )
                  ],
                ),

                const SizedBox(height: 14.0,),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          source = "Gallery";
                          detectObject();
                        },
                        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.indigo,size: 30.0,),
                        label: const Text('Gallery',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16.0,),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          source = "Camera";
                          detectObject();
                        },
                        icon: const Icon(Icons.view_in_ar_rounded, color: Colors.indigo,size: 30.0,),
                        label: const Text('Scan',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16.0,),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () async {
                    if(result == ''){
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please scan your asset first.")),
                      );
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      String keyword = getRepairKeyword(result);
                      List<dynamic> shops = await searchNearbyRepairShops(keyword);

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfessionalPage(shops: shops)),
                      );

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error finding repair shops: $e")),
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  icon: _isLoading
                      ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Icon(Icons.location_on_rounded, color: Colors.indigo,size: 30.0,),
                  label: const Text('Search Professionals',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    foregroundColor: Colors.black,
                  ),
                ),

                const SizedBox(height: 20.0,),

                if (pickedImage != null || result.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Column(
                      children: [
                        if (pickedImage != null)
                          ClipRRect(borderRadius: BorderRadius.circular(18.0), child: Image.file(pickedImage!, height: 150)),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 3.0,
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

                // asserId != null then show furniture list
                if (assetId != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Available Furniture Inventory',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: FurnitureMaintenanceList(assetId: assetId),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Text(
                      'Note: Furniture inventory is not available because you have no assigned property.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ]
                // --- 结束条件判断 ---
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 3.0,

              child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),

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