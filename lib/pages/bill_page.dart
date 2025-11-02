import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillPage extends StatelessWidget {
  final String assetId;
  final String assetName;

  const BillPage({
    super.key,
    required this.assetId,
    required this.assetName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${assetName} Bills', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),

      backgroundColor: Colors.purple[50],

      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection('assets')
            .doc(assetId)
            .collection('bills')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final bills = snapshot.data!.docs;
          if (bills.isEmpty) return Center(child: Text("No bills recorded for $assetName."));

          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index].data() as Map<String, dynamic>;
              final billType = bill['type'] ?? 'Utility Bill';
              final billTitle = "$billType (${bill['month'] ?? 'N/A'} ${bill['year'] ?? ''})";

              return ListTile(
                title: Text(billTitle),
                subtitle: Text("Amount: ${bill['amount'] ?? 'N/A'}"),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          );
        },
      ),
    );
  }
}