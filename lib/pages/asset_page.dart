import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tenant/pages/bill_page.dart';
import 'package:tenant/pages/furniture_page.dart';

class AssetPage extends StatefulWidget {
  const AssetPage({super.key});

  @override
  _AssetPageState createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController tenantEmailCtrl = TextEditingController();
  final TextEditingController rentCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  String _editDialogMessage = '';
  String? _selectedTenantId;

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    tenantEmailCtrl.dispose();
    rentCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 10);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> addAsset() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (nameCtrl.text.isEmpty || addressCtrl.text.isEmpty) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image.')),
      );
      return;
    }

    Navigator.pop(context);

    setState(() {
      _isLoading = true;
    });

    String imageUrl = '';

    try {
      String fileName = 'assets/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      await storageRef.putFile(_selectedImage!);
      imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('assets').add({
        'landlordId': uid,
        'name': nameCtrl.text,
        'address': addressCtrl.text,
        'rent': double.tryParse(rentCtrl.text) ?? 0,
        'note': noteCtrl.text,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'tenantId': null,
      });

      nameCtrl.clear();
      addressCtrl.clear();
      rentCtrl.clear();
      noteCtrl.clear();
      _selectedImage = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getLandlordTenants() async {
    final landlordUid = FirebaseAuth.instance.currentUser?.uid;
    if (landlordUid == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('landlordId', isEqualTo: landlordUid)
        .get();

    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      'email': doc.get('email') ?? 'No Email',
      'name': doc.get('name') ?? doc.get('email') ?? 'Unknown Tenant',
    }).toList();
  }

  Future<void> updateAsset({
    required String assetId,
    String? oldImageUrl,
    required Function setDialogState
  }) async {
    final landlordUid = FirebaseAuth.instance.currentUser?.uid;
    if (landlordUid == null || nameCtrl.text.isEmpty || addressCtrl.text.isEmpty) {
      setDialogState(() {
        _editDialogMessage = "Property Name and Address cannot be empty.";
      });
      return;
    }

    setDialogState(() {
      _isLoading = true;
      _editDialogMessage = '';
    });

    String newImageUrl = oldImageUrl ?? '';
    String? newTenantId = _selectedTenantId;

    try {
      if (_selectedImage != null) {
        String fileName = 'assets/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        await storageRef.putFile(_selectedImage!);
        newImageUrl = await storageRef.getDownloadURL();

        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
          } catch (e) {
            print(e);
          }
        }
      }

      if (newTenantId != null) {
        await FirebaseFirestore.instance.collection('users').doc(newTenantId).update({
          'landlordId': landlordUid,
        });
      }

      Map<String, dynamic> updateData = {
        'name': nameCtrl.text,
        'address': addressCtrl.text,
        'rent': double.tryParse(rentCtrl.text) ?? 0,
        'note': noteCtrl.text,
        'imageUrl': newImageUrl,
        'tenantId': newTenantId,
      };

      await FirebaseFirestore.instance.collection('assets').doc(assetId).update(updateData);

      _selectedImage = null;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property updated successfully!')),
      );
    } catch (e) {
      setDialogState(() {
        _editDialogMessage = 'Update failed: ${e.toString()}';
      });
    } finally {
      setDialogState(() {
        _isLoading = false;
      });
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getTenantEmailAndVerify(String? tenantId, String assetId) async {
    if (tenantId == null) return '';
    final landlordUid = FirebaseAuth.instance.currentUser?.uid;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(tenantId).get();
      if (doc.exists) {
        String? currentLandlordOfTenant = doc.get('landlordId');
        if (currentLandlordOfTenant == landlordUid) {
          return doc.get('email') ?? '';
        }
      }

      await FirebaseFirestore.instance.collection('assets').doc(assetId).update({'tenantId': null});
      return '';
    } catch (e) {
      return '';
    }
  }

  void showEditDialog(String assetId, Map<String, dynamic> assetData, String currentTenantEmail) {
    nameCtrl.text = assetData['name'] ?? '';
    addressCtrl.text = assetData['address'] ?? '';
    rentCtrl.text = assetData['rent']?.toString() ?? '';
    noteCtrl.text = assetData['note'] ?? '';
    tenantEmailCtrl.text = currentTenantEmail;

    _selectedImage = null;
    _editDialogMessage = '';
    _selectedTenantId = assetData['tenantId'];

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getLandlordTenants(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
            }
            final List<Map<String, dynamic>> tenants = snapshot.data ?? [];
            return StatefulBuilder(
              builder: (context, setDialogState) {
                List<DropdownMenuItem<String>> dropdownItems = [
                  const DropdownMenuItem<String>(value: null, child: Text("None")),
                  ...tenants.map((t) => DropdownMenuItem<String>(value: t['id'], child: Text(t['email']))),
                ];

                return AlertDialog(
                  title: const Text("Edit Property"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () async {
                            await _pickImage();
                            setDialogState(() {});
                          },
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(30.0),
                              image: _selectedImage == null && assetData['imageUrl'] != null
                                  ? DecorationImage(image: NetworkImage(assetData['imageUrl']), fit: BoxFit.cover)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: _selectedImage != null
                                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                : assetData['imageUrl'] == null ? const Text("Tap to Select New Image") : const Text(""),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)))),
                        const SizedBox(height: 15),
                        TextField(controller: addressCtrl, decoration: InputDecoration(labelText: "Address", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)))),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: tenants.any((t) => t['id'] == _selectedTenantId) ? _selectedTenantId : null,
                          decoration: InputDecoration(labelText: "Assigned Tenant", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0))),
                          items: dropdownItems,
                          onChanged: (newValue) => setDialogState(() => _selectedTenantId = newValue),
                        ),
                        const SizedBox(height: 15),
                        TextField(controller: rentCtrl, decoration: InputDecoration(labelText: "Monthly Rent", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0))), keyboardType: TextInputType.number),
                        const SizedBox(height: 15),
                        TextField(controller: noteCtrl, decoration: InputDecoration(labelText: "Note", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)))),
                        if (_editDialogMessage.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_editDialogMessage, style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    _isLoading
                        ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: CircularProgressIndicator(strokeWidth: 2))
                        : ElevatedButton(onPressed: () => updateAsset(assetId: assetId, oldImageUrl: assetData['imageUrl'], setDialogState: setDialogState), child: const Text("Save")),
                  ],
                );
              },
            );
          },
        );
      },
    ).then((_) => setState(() => _selectedTenantId = null));
  }

  void showAddDialog() {
    _selectedImage = null;
    nameCtrl.clear();
    addressCtrl.clear();
    rentCtrl.clear();
    noteCtrl.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add New Property"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      await _pickImage();
                      setDialogState(() {});
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30.0)),
                      alignment: Alignment.center,
                      child: _selectedImage != null ? Image.file(_selectedImage!, fit: BoxFit.cover) : const Icon(Icons.add_photo_alternate_rounded, size: 60.0),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)))),
                  const SizedBox(height: 15),
                  TextField(controller: addressCtrl, decoration: InputDecoration(labelText: "Address", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)))),
                  const SizedBox(height: 15),
                  TextField(controller: rentCtrl, decoration: InputDecoration(labelText: "Monthly Rent", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0))), keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  TextField(controller: noteCtrl, decoration: InputDecoration(labelText: "Note", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              _isLoading
                  ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton(onPressed: addAsset, child: const Text("Add")),
            ],
          );
        },
      ),
    ).then((_) => setState(() => _selectedImage = null));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Please log in.')));

    return Scaffold(
      appBar: AppBar(title: const Text('Assets', style: TextStyle(color: Colors.white)), centerTitle: true, backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: showAddDialog, backgroundColor: Colors.indigo, foregroundColor: Colors.white, child: const Icon(Icons.add)),
      backgroundColor: Colors.purple[50],
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('assets').where('landlordId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final assets = snapshot.data!.docs;
            if (assets.isEmpty) return const Center(child: Text("No properties found."));

            return ListView.builder(
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final assetDoc = assets[index];
                final assetId = assetDoc.id;
                final asset = assetDoc.data() as Map<String, dynamic>;
                final String imageUrl = asset['imageUrl'] as String? ?? '';
                final String? tenantId = asset['tenantId'] as String?;

                return FutureBuilder<String>(
                  future: _getTenantEmailAndVerify(tenantId, assetId),
                  builder: (context, emailSnapshot) {
                    final tenantEmail = emailSnapshot.data ?? '';
                    final tenantInfo = (tenantId != null && tenantEmail.isNotEmpty) ? "Tenant: $tenantEmail" : "Tenant: None";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                      elevation: 3.0,
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FurniturePage(assetId: assetId, assetName: asset['name']))),
                        leading: imageUrl.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(12.0), child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40)))
                            : Image.asset('images/logo.png', height: 40),
                        title: Text(asset['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${asset['address']}\nRent: RM ${asset['rent']}\n$tenantInfo"),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.receipt_long, color: Colors.indigo), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BillPage(assetId: assetId, assetName: asset['name'])))),
                            IconButton(icon: const Icon(Icons.edit, color: Colors.indigo), onPressed: () => showEditDialog(assetId, asset, tenantEmail)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}