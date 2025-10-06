import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyPage extends StatefulWidget {
  final String ownerId;
  const PropertyPage({required this.ownerId});

  @override
  _PropertyPageState createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController rentCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();

  Future<void> addAsset() async {
    if (nameCtrl.text.isEmpty || addressCtrl.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('assets').add({
      'ownerId': widget.ownerId,
      'name': nameCtrl.text,
      'address': addressCtrl.text,
      'rent': double.tryParse(rentCtrl.text) ?? 0,
      'note': noteCtrl.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    nameCtrl.clear();
    addressCtrl.clear();
    rentCtrl.clear();
    noteCtrl.clear();
    Navigator.pop(context);
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Property"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: addressCtrl, decoration: InputDecoration(labelText: "Address")),
              TextField(controller: rentCtrl, decoration: InputDecoration(labelText: "Monthly Rent"), keyboardType: TextInputType.number),
              TextField(controller: noteCtrl, decoration: InputDecoration(labelText: "Note")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(onPressed: addAsset, child: Text("Add")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties', style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assets')
            .where('ownerId', isEqualTo: widget.ownerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

          final assets = snapshot.data!.docs;
          if (assets.isEmpty) return Center(child: Text("No properties found."));

          return ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
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