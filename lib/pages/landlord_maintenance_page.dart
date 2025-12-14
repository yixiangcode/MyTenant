import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LandlordMaintenancePage extends StatelessWidget {
  const LandlordMaintenancePage({super.key});

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
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
              final data = docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.network(
                    data['imageUrl'],
                    width: 50,
                    fit: BoxFit.cover,
                  )
                      : const Icon(Icons.build),
                  title: Text(data['furnitureName'] ?? ''),
                  subtitle: Text(
                    "${data['assetName']}\n${data['description']}",
                  ),
                  trailing: Chip(
                    label: Text(data['status']),
                    backgroundColor: data['status'] == 'pending'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
