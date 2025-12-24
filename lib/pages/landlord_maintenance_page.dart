import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LandlordMaintenancePage extends StatelessWidget {
  const LandlordMaintenancePage({super.key});

  Future<void> _updateStatus(BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('maintenance_requests')
          .doc(docId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated to $newStatus")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showActionSheet(BuildContext context, String docId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.pending_rounded, color: Colors.orange),
                title: const Text('Set to Pending'),
                onTap: () {
                  _updateStatus(context, docId, 'pending');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.build_rounded, color: Colors.blue),
                title: const Text('Set to In Progress'),
                onTap: () {
                  _updateStatus(context, docId, 'in progress');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                title: const Text('Set to Completed'),
                onTap: () {
                  _updateStatus(context, docId, 'completed');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final landlordId = FirebaseAuth.instance.currentUser?.uid;

    if (landlordId == null) {
      return const Scaffold(
        body: Center(child: Text("Please login")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Maintenance Requests"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.purple[50],
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('maintenance_requests')
              .where('landlordId', isEqualTo: landlordId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("No maintenance requests"));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final docId = docs[index].id;
                final data = docs[index].data() as Map<String, dynamic>;
                final status = data['status'] ?? 'pending';

                return Card(
                  elevation: 6.0,
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: ListTile(
                    onTap: () => _showActionSheet(context, docId),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    leading: data['imageUrl'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        data['imageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Icon(Icons.handyman_rounded),
                    title: Text(
                      data['furnitureName'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Property: ${data['assetName']}\nStatus: $status",
                    ),
                    trailing: _buildStatusIcon(status),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'completed') {
      return const Icon(Icons.check_circle_rounded, size: 30.0, color: Colors.green);
    } else if (status == 'in progress') {
      return const Icon(Icons.hourglass_bottom_rounded, size: 30.0, color: Colors.blue);
    } else {
      return const Icon(Icons.pending_actions_rounded, size: 30.0, color: Colors.orange);
    }
  }
}