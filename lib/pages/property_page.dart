import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PropertyPage extends StatefulWidget {
  final String ownerId;
  const PropertyPage({super.key, required this.ownerId});

  @override
  _PropertyPageState createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController rentCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();

  File? _selectedImage;
  bool _isAdding = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    rentCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // 注意：这里使用 setState 来更新 _selectedImage 变量
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // **修改：集成图片上传和 Firestore 存储**
  Future<void> addAsset() async {
    if (nameCtrl.text.isEmpty || addressCtrl.text.isEmpty) return;

    // 强制检查图片
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image.')),
      );
      return;
    }

    // 关闭对话框
    Navigator.pop(context);

    setState(() {
      _isAdding = true; // 开始加载
    });

    String imageUrl = '';

    try {
      // 1. 上传图片到 Firebase Storage
      String fileName = 'assets/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      await storageRef.putFile(_selectedImage!);

      // 2. 获取图片的下载 URL
      imageUrl = await storageRef.getDownloadURL();

      // 3. 将数据和图片 URL 存入 Firestore
      await FirebaseFirestore.instance.collection('assets').add({
        'ownerId': widget.ownerId,
        'name': nameCtrl.text,
        'address': addressCtrl.text,
        'rent': double.tryParse(rentCtrl.text) ?? 0,
        'note': noteCtrl.text,
        'imageUrl': imageUrl, // <-- 存储 URL
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 清理
      nameCtrl.clear();
      addressCtrl.clear();
      rentCtrl.clear();
      noteCtrl.clear();
      _selectedImage = null; // 清除图片

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property added successfully!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() {
        _isAdding = false; // 停止加载
      });
    }
  }

  // **修改：修复 setDialogState 和添加加载状态**
  void showAddDialog() {
    _selectedImage = null;
    nameCtrl.clear();
    addressCtrl.clear();
    rentCtrl.clear();
    noteCtrl.clear();

    showDialog(
      context: context,
      // **必须**使用 StatefulBuilder 才能在 AlertDialog 内部更新 _selectedImage 的预览
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
                      setDialogState(() {}); // 仅更新对话框内部的 UI
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : const Text("Tap to Select Image"),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
                  TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Address")),
                  TextField(controller: rentCtrl, decoration: const InputDecoration(labelText: "Monthly Rent"), keyboardType: TextInputType.number),
                  TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "Note")),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              // **添加加载状态显示**
              _isAdding
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
      // 无论对话框如何关闭，都重置 _selectedImage
      setState(() {
        _selectedImage = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      // **添加全局加载状态显示**
      body: _isAdding
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assets')
            .where('ownerId', isEqualTo: widget.ownerId)
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
              final asset = assets[index];
              final String imageUrl = asset['imageUrl'] as String? ?? ''; // <-- 获取图片 URL

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  // **修改：显示图片**
                  leading: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                  )
                      : const Icon(Icons.house, size: 40, color: Colors.indigo),

                  title: Text(asset['name']),
                  subtitle: Text("${asset['address']}\nRent: RM ${asset['rent']}"),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}