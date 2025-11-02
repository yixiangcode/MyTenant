import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tenant/pages/bill_page.dart';

class PropertyPage extends StatefulWidget {
  const PropertyPage({super.key});

  @override
  _PropertyPageState createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController tenantEmailCtrl = TextEditingController();
  final TextEditingController rentCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  String _editDialogMessage = '';

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
    String? newTenantId = null;

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
            print("Error deleting old image: $e");
          }
        }
      }

      final tenantEmail = tenantEmailCtrl.text.trim();

      if (tenantEmail.isNotEmpty) {
        final tenantQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: tenantEmail)
            .limit(1)
            .get();

        if (tenantQuery.docs.isEmpty) {
          throw Exception("Tenant with email '$tenantEmail' not found.");
        }

        newTenantId = tenantQuery.docs.first.id;

        await FirebaseFirestore.instance.collection('users').doc(newTenantId).update({
          'landlordId': landlordUid,
        });

      } else {
        newTenantId = null;
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

  void showEditDialog(
      String assetId,
      Map<String, dynamic> assetData,
      String currentTenantEmail
      ) {

    nameCtrl.text = assetData['name'] ?? '';
    addressCtrl.text = assetData['address'] ?? '';
    rentCtrl.text = assetData['rent']?.toString() ?? '';
    noteCtrl.text = assetData['note'] ?? '';
    tenantEmailCtrl.text = currentTenantEmail;

    _selectedImage = null;
    _editDialogMessage = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                        borderRadius: BorderRadius.circular(12.0),
                        image: _selectedImage == null && assetData['imageUrl'] != null
                            ? DecorationImage(
                          image: NetworkImage(assetData['imageUrl']),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : assetData['imageUrl'] == null
                          ? const Text("Tap to Select New Image")
                          : const Text(""),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),),),
                  const SizedBox(height: 15),
                  TextField(controller: addressCtrl, decoration: InputDecoration(labelText: "Address", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: tenantEmailCtrl,
                    decoration: InputDecoration(
                      labelText: "Email of Tenant",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: rentCtrl, decoration: InputDecoration(labelText: "Monthly Rent", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),), keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  TextField(controller: noteCtrl, decoration: InputDecoration(labelText: "Note", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),)),

                  if (_editDialogMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_editDialogMessage, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),

              _isLoading
                  ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : ElevatedButton(
                  onPressed: () => updateAsset(
                    assetId: assetId,
                    oldImageUrl: assetData['imageUrl'],
                    setDialogState: setDialogState,
                  ),
                  child: const Text("Save")
              ),
            ],
          );
        },
      ),
    ).then((_) {
      setState(() {});
    });
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
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      alignment: Alignment.center,
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : const Text("Tap to Select Image"),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),),),
                  const SizedBox(height: 15),
                  TextField(controller: addressCtrl, decoration: InputDecoration(labelText: "Address", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),)),
                  const SizedBox(height: 15),
                  TextField(controller: rentCtrl, decoration: InputDecoration(labelText: "Monthly Rent", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),), keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  TextField(controller: noteCtrl, decoration: InputDecoration(labelText: "Note", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0),),)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),

              _isLoading
                  ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : ElevatedButton(onPressed: addAsset, child: const Text("Add")),
            ],
          );
        },
      ),
    ).then((_) {

      setState(() {
        _selectedImage = null;
      });
    });
  }

  Future<String> _getTenantEmail(String? tenantId) async {
    if (tenantId == null) return '';
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(tenantId).get();
      return doc.exists ? doc.get('email') ?? '' : '';
    } catch (e) {
      print("Error fetching tenant email: $e");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),

      backgroundColor: Colors.purple[50],

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assets')
            .where('landlordId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
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
                future: _getTenantEmail(tenantId),
                builder: (context, emailSnapshot) {
                  final tenantEmail = emailSnapshot.data ?? 'N/A';
                  final tenantInfo = tenantId != null
                      ? "Tenant: ${emailSnapshot.data ?? 'Loading...'}"
                      : "Tenant: None";

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillPage(
                              assetId: assetId,
                              assetName: asset['name'],
                            ),
                          ),
                        );
                      },
                      leading: imageUrl.isNotEmpty
                          ? ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.network(imageUrl, width: 80, height: 100, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),))
                          : Image.asset('images/logo.png', height: 40),

                      title: Text(asset['name']),
                      subtitle: Text("${asset['address']}\nRent: RM ${asset['rent']}\n$tenantInfo"),
                      isThreeLine: true,

                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.indigo),
                        onPressed: () => showEditDialog(assetId, asset, tenantEmail),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}