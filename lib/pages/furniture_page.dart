import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FurniturePage extends StatefulWidget {
  final String assetId;
  final String assetName;

  const FurniturePage({super.key, required this.assetId, required this.assetName});

  @override
  State<FurniturePage> createState() => _FurniturePageState();
}

class _FurniturePageState extends State<FurniturePage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController quantityCtrl = TextEditingController();
  final TextEditingController conditionCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _dialogErrorMessage = '';

  @override
  void dispose() {
    nameCtrl.dispose();
    quantityCtrl.dispose();
    conditionCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(Function setDialogState) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setDialogState(() {
        _selectedImage = File(pickedFile.path);
        _dialogErrorMessage = '';
      });
    }
  }

  Future<void> _addFurnitureItem() async {
    final String name = nameCtrl.text.trim();
    final int quantity = int.tryParse(quantityCtrl.text) ?? 1;
    final String condition = conditionCtrl.text.trim();
    final double price = double.tryParse(priceCtrl.text) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Furniture name is required.')),
      );
      return;
    }
    if (_selectedImage == null) {
      setState(() {
        _dialogErrorMessage = 'Please select an image for the item.';
      });
      return;
    }

    Navigator.pop(context);

    setState(() {
      _isLoading = true;
    });

    String? imageUrl;

    try {
      String fileName = 'furniture/${widget.assetId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('assets')
          .doc(widget.assetId)
          .collection('furniture')
          .add({
        'name': name,
        'quantity': quantity,
        'condition': condition.isNotEmpty ? condition : 'N/A',
        'price': price,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      nameCtrl.clear();
      quantityCtrl.clear();
      conditionCtrl.clear();
      priceCtrl.clear();
      _selectedImage = null;
      _dialogErrorMessage = '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $name successfully!')),
      );

    } catch (e) {
      print("Error adding furniture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteFurnitureItem(String itemId, String? imageUrl) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      }

      await FirebaseFirestore.instance
          .collection('assets')
          .doc(widget.assetId)
          .collection('furniture')
          .doc(itemId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully!')),
      );

    } catch (e) {
      print("Error deleting furniture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateFurnitureItem({
    required String itemId,
    required String? oldImageUrl,
    required Function setDialogState
  }) async {
    final String name = nameCtrl.text.trim();
    final int quantity = int.tryParse(quantityCtrl.text) ?? 1;
    final String condition = conditionCtrl.text.trim();
    final double price = double.tryParse(priceCtrl.text) ?? 0.0;

    if (name.isEmpty) {
      setDialogState(() {
        _dialogErrorMessage = "Item Name cannot be empty.";
      });
      return;
    }

    setDialogState(() {
      _isLoading = true;
      _dialogErrorMessage = '';
    });

    String newImageUrl = oldImageUrl ?? '';

    try {
      if (_selectedImage != null) {
        String fileName = 'furniture/${widget.assetId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putFile(_selectedImage!);
        TaskSnapshot snapshot = await uploadTask;
        newImageUrl = await snapshot.ref.getDownloadURL();

        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
        }
      }

      Map<String, dynamic> updateData = {
        'name': name,
        'quantity': quantity,
        'condition': condition.isNotEmpty ? condition : 'N/A',
        'price': price,
        'imageUrl': newImageUrl,
      };

      await FirebaseFirestore.instance
          .collection('assets')
          .doc(widget.assetId)
          .collection('furniture')
          .doc(itemId)
          .update(updateData);

      _selectedImage = null;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully!')),
      );

    } catch (e) {
      setDialogState(() {
        _dialogErrorMessage = 'Update failed: ${e.toString().replaceAll("Exception:", "")}';
      });
    } finally {
      if (mounted) {
        setDialogState(() {
          _isLoading = false;
        });
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddFurnitureDialog() {
    nameCtrl.clear();
    quantityCtrl.text = '1';
    conditionCtrl.clear();
    priceCtrl.clear();
    _selectedImage = null;
    _dialogErrorMessage = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Add New Furniture"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _pickImage(setDialogState),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30.0),
                        image: _selectedImage != null
                            ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: _selectedImage == null
                          ? const Icon(Icons.add_photo_alternate_rounded, size: 60.0,)
                          : null,
                    ),
                  ),
                  if (_dialogErrorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_dialogErrorMessage, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Item Name"),
                  ),
                  TextField(
                    controller: quantityCtrl,
                    decoration: const InputDecoration(labelText: "Quantity"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: conditionCtrl,
                    decoration: const InputDecoration(labelText: "Condition"),
                  ),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: "Price (RM)"),
                    keyboardType: TextInputType.number,
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
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) {
                    setDialogState(() {
                      _dialogErrorMessage = 'Furniture name is required.';
                    });
                    return;
                  }
                  if (_selectedImage == null) {
                    setDialogState(() {
                      _dialogErrorMessage = 'Please select an image for the item.';
                    });
                    return;
                  }

                  setDialogState(() {
                    _isLoading = true;
                  });
                  _addFurnitureItem();
                },
                child: const Text("Add"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditFurnitureDialog(String itemId, Map<String, dynamic> itemData) {
    nameCtrl.text = itemData['name'] ?? '';
    quantityCtrl.text = itemData['quantity']?.toString() ?? '1';
    conditionCtrl.text = itemData['condition'] ?? '';
    priceCtrl.text = itemData['price']?.toString() ?? '';
    _selectedImage = null;
    _dialogErrorMessage = '';

    final String? currentImageUrl = itemData['imageUrl'] as String?;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Item"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _pickImage(setDialogState),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.0),
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : currentImageUrl != null && currentImageUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(currentImageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: _selectedImage == null && (currentImageUrl == null || currentImageUrl.isEmpty)
                          ? const Text("Tap to Select New Image")
                          : null,
                    ),
                  ),
                  if (_dialogErrorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_dialogErrorMessage, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 15),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Item Name")),
                  TextField(controller: quantityCtrl, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
                  TextField(controller: conditionCtrl, decoration: const InputDecoration(labelText: "Condition")),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: "Price (RM)"),
                    keyboardType: TextInputType.number,
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
                onPressed: () => _updateFurnitureItem(
                  itemId: itemId,
                  oldImageUrl: currentImageUrl,
                  setDialogState: setDialogState,
                ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Furniture of ${widget.assetName}'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      backgroundColor: Colors.purple[50],

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assets')
            .doc(widget.assetId)
            .collection('furniture')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final furnitureItems = snapshot.data!.docs;
          if (furnitureItems.isEmpty) return const Center(child: Text("No items listed. Tap '+' to add one."));

          return Stack(
            children: [
              ListView.builder(
                itemCount: furnitureItems.length,
                itemBuilder: (context, index) {
                  final doc = furnitureItems[index];
                  final itemId = doc.id;
                  final item = doc.data() as Map<String, dynamic>;
                  final String imageUrl = item['imageUrl'] as String? ?? '';
                  final double price = item['price'] as double? ?? 0.0;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36.0),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36.0),
                      ),

                      leading: imageUrl.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, size: 30),
                        ),
                      )
                          : const Icon(Icons.chair_rounded, size: 40, color: Colors.grey),
                      title: Text(item['name'] ?? 'Item'),
                      subtitle: Text("Qty: ${item['quantity'] ?? 1}\nCondition: ${item['condition'] ?? 'N/A'}\nPrice: RM ${price.toStringAsFixed(2)}"),
                      isThreeLine: true,

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.indigo, size: 20),
                            onPressed: () => _showEditFurnitureDialog(itemId, item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                            onPressed: () => _deleteFurnitureItem(itemId, imageUrl),
                          ),
                        ],
                      ),
                      onTap: (){},
                    ),
                  );
                },
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFurnitureDialog,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}