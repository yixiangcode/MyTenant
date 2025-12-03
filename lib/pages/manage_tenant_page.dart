import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageTenantPage extends StatefulWidget {
  const ManageTenantPage({super.key});

  @override
  _ManageTenantPageState createState() => _ManageTenantPageState();
}

class _ManageTenantPageState extends State<ManageTenantPage> {

  final TextEditingController emailCtrl = TextEditingController();
  String _dialogMessage = '';

  Future<void> addTenant() async {
    final user = FirebaseAuth.instance.currentUser;
    final landlordId = user?.uid;
    final landlordEmail = user?.email ?? 'Unknown Landlord';

    if (landlordId == null) {
      setState(() { _dialogMessage = "Error: Landlord not authenticated."; });
      return;
    }

    final tenantEmail = emailCtrl.text.trim();
    if (tenantEmail.isEmpty) {
      setState(() { _dialogMessage = "Email cannot be empty."; });
      return;
    }

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: tenantEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      setState(() { _dialogMessage = "Error: User with this email not found in the 'users' collection."; });
      return;
    }

    final tenantDoc = userQuery.docs.first;
    final tenantId = tenantDoc.id;
    final currentLandlordId = tenantDoc.data()['landlordId'];
    final tenantRole = tenantDoc.data()['role'];

    if (landlordId == tenantId) {
      setState(() { _dialogMessage = "Error: You cannot add yourself as a tenant."; });
      return;
    }
    if (tenantRole != 'Tenant') {
      setState(() { _dialogMessage = "Error: User role is not 'Tenant'."; });
      return;
    }

    if (currentLandlordId == landlordId) {
      setState(() { _dialogMessage = "Error: This user is already managed by you."; });
      return;
    }

    final existingInvite = await FirebaseFirestore.instance
        .collection('invites')
        .where('tenantId', isEqualTo: tenantId)
        .where('landlordId', isEqualTo: landlordId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingInvite.docs.isNotEmpty) {
      setState(() { _dialogMessage = "An invitation is already pending for this tenant."; });
      return;
    }

    await FirebaseFirestore.instance.collection('invites').add({
      'landlordId': landlordId,
      'tenantId': tenantId,
      'landlordEmail': landlordEmail,
      'status': 'pending',
      'sentAt': FieldValue.serverTimestamp(),
    });

    emailCtrl.clear();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invitation sent to $tenantEmail. Waiting for approval!')),
    );
  }

  void showAddDialog() {
    _dialogMessage = '';
    emailCtrl.clear();

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text("Add New Tenant by Email"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Tenant Email",
                              prefixIcon: Icon(Icons.email),
                            )
                        ),
                        if (_dialogMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _dialogMessage,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel")
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          await addTenant().catchError((e) {
                            setState(() {
                              _dialogMessage = e.toString();
                            });
                          });
                        },
                        child: const Text("Send Invitation")
                    ),
                  ],
                );
              }
          );
        }
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final landlordId = user?.uid;

    if (landlordId == null) {
      return const Scaffold(body: Center(child: Text("Please log in to manage tenants.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenants', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
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
            .collection('users')
            .where('landlordId', isEqualTo: landlordId)
            .where('role', isEqualTo: 'Tenant')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final tenants = snapshot.data!.docs;
          if (tenants.isEmpty) return const Center(child: Text("No tenants found."));

          return ListView.builder(
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 3.0,
                child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: tenant['avatarUrl'] != null && tenant['avatarUrl'].isNotEmpty
                          ? Image.network(tenant['avatarUrl'], width: 40.0, height: 40.0, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40))
                          : const Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
                    title: Text(tenant['name'] ?? 'Name N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "Email: ${tenant['email']}\nContact: ${tenant['contactNumber'] ?? 'N/A'}\nAddress: ${tenant['address'] ?? 'N/A'}",
                    ),
                    isThreeLine: true,

                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(tenants[index].id)
                            .update({'landlordId': FieldValue.delete()});

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${tenant['name']} removed successfully!')),
                        );
                      },
                    )
                ),
              );
            },
          );
        },
      ),
    );
  }
}