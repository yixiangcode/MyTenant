import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwingPage extends StatelessWidget {
  const OwingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owing Records'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.indigo,
      ),

      backgroundColor: Colors.purple[50],

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('bills')
            .where('ownerId', isEqualTo: uid)
            .where('paid', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final bills = snapshot.data!.docs;
          if (bills.isEmpty) {
            return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 80,),
                    Text('No outstanding bills'),
                  ],
                ));
          }

          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              final data = bill.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.0),
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
                  title: Text('${data['type']} - ${data['month']} ${data['year']}'),
                  subtitle: Text('Amount: RM ${data['amount']}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await bill.reference.update({
                        'paid': true,
                        'paidAt': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment successful')),
                      );
                    },
                    child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
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
