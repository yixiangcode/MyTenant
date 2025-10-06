import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTenantPage extends StatefulWidget {
  final String ownerId;
  const ManageTenantPage({required this.ownerId});

  @override
  _ManageTenantPageState createState() => _ManageTenantPageState();
}

class _ManageTenantPageState extends State<ManageTenantPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController contactNumberCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController rentalDateCtrl = TextEditingController();

  Future<void> addTenant() async {
    if (nameCtrl.text.isEmpty || contactNumberCtrl.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('tenants').add({
      'ownerId': widget.ownerId,
      'name': nameCtrl.text,
      'contactNumber': contactNumberCtrl.text,
      'address': addressCtrl.text,
      'rentalDate': rentalDateCtrl.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    nameCtrl.clear();
    contactNumberCtrl.clear();
    addressCtrl.clear();
    rentalDateCtrl.clear();
    Navigator.pop(context);
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Tenant"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: contactNumberCtrl, decoration: InputDecoration(labelText: "Contact Number")),
              TextField(controller: addressCtrl, decoration: InputDecoration(labelText: "Address")),
              TextField(controller: rentalDateCtrl, decoration: InputDecoration(labelText: "Rental Date")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(onPressed: addTenant, child: Text("Add")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenants', style: TextStyle(color: Colors.white),
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
            .collection('tenants')
            .where('ownerId', isEqualTo: widget.ownerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

          final tenants = snapshot.data!.docs;
          if (tenants.isEmpty) return Center(child: Text("No tenants found."));

          return ListView.builder(
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(tenant['name']),
                  subtitle: Text("${tenant['address']}\nContact Number: ${tenant['contactNumber']}"),
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