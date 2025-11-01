import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController icCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  bool _isLoading = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    nameCtrl.dispose();
    icCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 10,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void showEditDialog(Map<String, dynamic> userData) {
    _selectedImage = null;

    nameCtrl.text = userData['name'] as String? ?? '';
    icCtrl.text = userData['ic'] as String? ?? '';
    emailCtrl.text = userData['email'] as String? ?? '';
    phoneCtrl.text = userData['contactNumber'] as String? ?? '';
    addressCtrl.text = userData['address'] as String? ?? '';

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    showDialog(
      context: context,

      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Profile"),
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
                        color: Colors.blue[200],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      alignment: Alignment.center,
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : const Text("Tap to Select Image"),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: icCtrl,
                    decoration: InputDecoration(
                      labelText: "IC Number",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: "Contact Number",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: "Address",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    maxLines: 2,
                    keyboardType: TextInputType.multiline,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),

              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ElevatedButton(
                onPressed: () async {
                  if (uid == null) return;

                  setDialogState(() {
                    _isLoading = true;
                  });

                  String? avatarUrl;
                  DocumentSnapshot userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get();

                  String? oldAvatarUrl = userDoc.get('avatarUrl') as String?;

                  // If user select new image
                  if (_selectedImage != null) {
                    try {
                      String fileName = 'assets/${DateTime.now().millisecondsSinceEpoch}.jpg';
                      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
                      await storageRef.putFile(_selectedImage!);
                      avatarUrl = await storageRef.getDownloadURL();

                      // delete old image
                      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
                        try {
                          Reference oldRef = FirebaseStorage.instance.refFromURL(oldAvatarUrl);
                          await oldRef.delete();
                        } catch (e) {
                          print('Error deleting old image: $e');
                        }
                      }
                    } catch (e) {
                      print('Error uploading image: $e');
                    }
                  } else {
                    // no new image, use old
                    avatarUrl = oldAvatarUrl;
                  }

                  // renew firestore
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'name': nameCtrl.text.trim(),
                    'ic': icCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'contactNumber': phoneCtrl.text.trim(),
                    'avatarUrl': avatarUrl,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );

                  Navigator.pop(context); // close dialog

                  // reload
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilePage()),
                  );
                },

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
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    Future<Map<String, dynamic>?> getUserInformation() async {
      DocumentSnapshot userInfo = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return userInfo.data() as Map<String, dynamic>?;
    }

    return Scaffold(
      backgroundColor: Colors.purple[50],

      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: getUserInformation(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: CircularProgressIndicator(), // Loading
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  return const Text('Loading error');
                }

                final userData = snapshot.data!;
                final name = userData['name'] as String? ?? '-';
                final ic = userData['ic'] as String? ?? '-';
                final email = userData['email'] as String? ?? '-';
                final role = userData['role'] as String? ?? '-';
                final contactNumber = userData['contactNumber'] as String? ?? "-";
                final avatarUrl = userData['avatarUrl'] as String? ?? '';
                final address = userData['address'] as String? ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 50.0),
                    Hero(
                      tag: 'avatar',
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(avatarUrl),
                        radius: 70.0,
                      ),
                    ),
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Pacifico',
                        fontSize: 30.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      role,
                      style: TextStyle(
                        fontFamily: 'Source Sans Pro',
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30.0),

                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        leading: Icon(
                          Icons.account_box,
                          color: Colors.deepPurple,
                        ),
                        title: Text(
                          "Name",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          name,
                          style: TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontSize: 15.0,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 8.0),

                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        leading: Icon(Icons.badge, color: Colors.deepPurple),
                        title: Text(
                          "IC Number",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          ic,
                          style: TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontSize: 15.0,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 8.0),
                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        leading: Icon(Icons.mail, color: Colors.deepPurple),
                        title: Text(
                          "Email",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          email,
                          style: TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontSize: 15.0,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 8.0),

                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        leading: Icon(Icons.phone, color: Colors.deepPurple),
                        title: Text(
                          "Phone",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          contactNumber,
                          style: TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontSize: 15.0,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 8.0),

                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        leading: Icon(Icons.person, color: Colors.deepPurple),
                        title: Text(
                          "Role",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          role,
                          style: TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontSize: 15.0,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 8.0),

                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        leading: Icon(Icons.location_on, color: Colors.deepPurple),
                        title: Text(
                          "Address",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          address,
                          style: TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontSize: 15.0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40.0),
                    ElevatedButton(onPressed: (){showEditDialog(userData);}, child: Text("Edit Profile")),
                    SizedBox(height: 40.0),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
