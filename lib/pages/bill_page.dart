import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillPage extends StatelessWidget {
  final String assetId;
  final String assetName;

  BillPage({
    super.key,
    required this.assetId,
    required this.assetName,
  });

  final Map<String, IconData> typeIcons = {
    'Water': Icons.water_drop_rounded,
    'Electric': Icons.bolt_rounded,
    'Electricity': Icons.bolt_rounded,
    'Internet': Icons.router_rounded,
    'Maintenance': Icons.build_circle_rounded,
    'Rent': Icons.home_rounded,
    'Rental': Icons.home_rounded,
  };

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
              final billTitle = "$billType Bill (${bill['month'] ?? 'N/A'} ${bill['year'] ?? ''})";

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                elevation: 3.0,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  leading: bill['type'] != null && typeIcons.containsKey(bill['type'])
                      ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(typeIcons[bill['type']], color: Colors.indigo),
                  )
                      : null,
                  title: Text(billTitle),
                  subtitle: Text("Amount: RM ${bill['amount'] ?? 'N/A'}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (bill['imageUrl'].isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: Image.network(
                            bill['imageUrl'],
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                height: 300,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No image recorded for this bill.')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}