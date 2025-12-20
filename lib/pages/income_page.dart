import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomePage extends StatelessWidget {
  IncomePage({super.key});

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
    final landlordId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Records'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.indigo,
      ),

      backgroundColor: Colors.purple[50],

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assets')
            .where('landlordId', isEqualTo: landlordId)
            .snapshots(),
        builder: (context, assetSnapshot) {
          if (!assetSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final assets = assetSnapshot.data!.docs;

          if (assets.isEmpty) {
            return const Center(child: Text('No assets found'));
          }

          return ListView(
            children: assets.map((asset) {
              return StreamBuilder<QuerySnapshot>(
                stream: asset.reference
                    .collection('bills')
                    .where('paid', isEqualTo: true)
                    .snapshots(),
                builder: (context, billSnapshot) {
                  if (!billSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final bills = billSnapshot.data!.docs;
                  if (bills.isEmpty) return const SizedBox();

                  double total = 0;
                  for (var bill in bills) {
                    final amount = bill['amount'] as num? ?? 0;
                    total += amount.toDouble();
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0),
                    ),
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset['name'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Total Income: RM ${total.toStringAsFixed(2)}'),
                          const Divider(),
                          ...bills.map((bill) {
                            final data = bill.data() as Map<String, dynamic>;
                            final billAmount = data['amount'] as num? ?? 0;

                            return ListTile(
                              leading: data['type'] != null && typeIcons.containsKey(data['type'])
                                  ? Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(typeIcons[data['type']], color: Colors.indigo),
                              )
                                  : null,
                              title: Text('${data['type']}'),
                              subtitle: Text('${data['month']} ${data['year']}'),
                              trailing: Text('RM ${billAmount.toStringAsFixed(2)}'),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}