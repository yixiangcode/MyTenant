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
  String result = '';
  File? pickedImage;
  String source = '';
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
        final data = doc.data();
        if (mounted) {
          setState(() {
            _tenantAsset = {
              'assetId': doc.id,
              'assetName': data['name'] as String? ?? 'Your Property',
              'landlordId': data['landlordId'] as String? ?? '',
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
    } else if (label.contains("distribution_board") || label.contains("water_heater")) {
      return "electrician";
    } else {
      return label;
    }
  }

  Map<String, List<String>> _commonIssues = {
    "led_lamp": ["Flickering", "Not turning on", "Dim light"],
    "fluorescent_lamp": ["Flickering", "Not turning on", "Broken starter"],
    "lamp": ["Flickering", "Not turning on", "Broken bulb"],
    "wall_aircond": ["Not cold", "Water leaking", "Noisy", "No power"],
    "cassette_aircond": ["Not cold", "Water leaking", "Noisy"],
    "wall_fan": ["Not rotating", "Noisy", "Speed too slow"],
    "ceiling_fan": ["Wobbling", "Too slow", "Remote not working"],
    "sink": ["Leaking pipe", "Clogged drain", "Broken tap"],
    "flush_toilet": ["Not flushing", "Water leaking", "Broken handle"],
    "squat_toilet": ["Clogged", "Water inlet leak", "Flushing weak"],
    "door_knob": ["Stuck lock", "Broken handle", "Key cannot turn"],
    "table": ["Wobbly legs", "Broken surface", "Stained"],
    "chair": ["Wobbly", "Broken leg", "Torn cushion"],
    "refrigerator": ["Not cooling", "Leaking water", "Noisy compressor"],
    "water_heater": ["No hot water", "Water leak", "Trip power"],
    "switches": ["Loose socket", "Sparking", "Not working"],
    "distribution_board": ["Frequent tripping", "Burning smell", "No power supply"],
    "computer": ["Cannot boot", "Blue screen", "Hardware failure"],
    "clock": ["Stopped", "Time inaccurate", "Broken glass"],
    "water": ["Low pressure", "Dirty water", "No water supply"],
  };

  Future<void> _showIssueReportDialog(String detectedItem) async {
    String? selectedIssue;
    final TextEditingController manualItemCtrl = TextEditingController();
    final TextEditingController manualIssueCtrl = TextEditingController();
    bool isUnknown = detectedItem == "Unknown" || detectedItem.isEmpty;

    List<String> issues = _commonIssues[detectedItem.toLowerCase()] ?? ["Other"];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isUnknown ? "Manual Report" : "Report $detectedItem"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUnknown)
                TextField(controller: manualItemCtrl, decoration: const InputDecoration(labelText: "What is broken?")),
              if (!isUnknown)
                DropdownButtonFormField<String>(
                  value: selectedIssue,
                  hint: const Text("Select an issue"),
                  items: issues.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDialogState(() => selectedIssue = val),
                ),
              TextField(controller: manualIssueCtrl, decoration: const InputDecoration(labelText: "Description")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('maintenance_requests').add({
                  'assetId': _tenantAsset?['assetId'],
                  'assetName': _tenantAsset?['assetName'],
                  'furnitureName': isUnknown ? manualItemCtrl.text : detectedItem,
                  'description': isUnknown ? manualIssueCtrl.text : (selectedIssue ?? manualIssueCtrl.text),
                  'tenantId': FirebaseAuth.instance.currentUser!.uid,
                  'landlordId': _tenantAsset?['landlordId'],
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              },
              child: const Text("Submit"),
            )
          ],
        ),
      ),
    );
  }

  Future<Position> _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
    } catch (e) {
      await Geolocator.openLocationSettings();
      throw Exception("Location services are disabled.");
    }
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
      confidenceThreshold: 0.4,
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
        final assetName = _tenantAsset?['assetName'];
        final landlordId = _tenantAsset?['landlordId'];

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
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: "Search professionals...",
                          prefixIcon: const Icon(Icons.search_rounded),
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
                                SnackBar(
                                  content: const Text(
                                    "Please search the keyword first.",
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  backgroundColor: Colors.indigoAccent,
                                  duration: const Duration(seconds: 2),

                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  margin: const EdgeInsets.all(15),
                                  elevation: 8.0,
                                ),
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
                        icon: const Icon(Icons.photo_library_rounded, color: Colors.indigo,size: 30.0,),
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
                        label: const Text('Scanner',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
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

                if (pickedImage != null || result.isNotEmpty)...[
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () async {
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
                      ],
                    ),
                  ),

                  Center(child: ElevatedButton(onPressed: (){_showIssueReportDialog(result);}, child: Text("Report"))),
                ],

                const SizedBox(height: 25),

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
                    child: FurnitureMaintenanceList(assetId: assetId, assetName: assetName!, landlordId: landlordId!),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Text(
                      '',
                      //'Note: Furniture inventory is not available because you have no assigned property.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ]
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
  final String assetName;
  final String landlordId;

  const FurnitureMaintenanceList({super.key, required this.assetId, required this.assetName, required this.landlordId});

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
                borderRadius: BorderRadius.circular(30.0),
              ),
              elevation: 3.0,

              child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
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
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('maintenance_requests')
                          .add({
                        'assetId': assetId,
                        'assetName': assetName,
                        'furnitureName': itemName,
                        'issueType': 'furniture',
                        'imageUrl': imageUrl,
                        'tenantId': FirebaseAuth.instance.currentUser!.uid,
                        'landlordId': landlordId,
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Maintenance reported'),
                          backgroundColor: Colors.green,
                        ),
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