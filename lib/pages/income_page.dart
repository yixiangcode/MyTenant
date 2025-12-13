import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomePage extends StatelessWidget {
  const IncomePage({super.key});

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