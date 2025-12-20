import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String monthName(int m) {
  const list = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  ];
  return list[m - 1];
}

Future<void> _generateSingleRentBill(String assetId) async {
  final assetRef = FirebaseFirestore.instance.collection('assets').doc(assetId);
  final assetSnap = await assetRef.get();
  if (!assetSnap.exists || assetSnap.data() == null || !assetSnap.data()!.containsKey('tenantId') || assetSnap['tenantId'] == null) {
    return;
  }

  final rent = assetSnap['rent'];
  final tenantId = assetSnap['tenantId'];

  final now = DateTime.now();
  final month = monthName(now.month);
  final year = now.year.toString();

  final billsRef = assetRef.collection('bills');

  final exist = await billsRef
      .where('type', isEqualTo: 'Rent')
      .where('month', isEqualTo: month)
      .where('year', isEqualTo: year)
      .get();

  if (exist.docs.isNotEmpty) return;

  await billsRef.add({
    'type': 'Rent',
    'amount': rent,
    'month': month,
    'year': year,
    'paid': false,
    'tenantId': tenantId,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

class OwingPage extends StatefulWidget {
  const OwingPage({super.key});

  @override
  State<OwingPage> createState() => _OwingPageState();
}

class _OwingPageState extends State<OwingPage> {
  bool _isGenerating = true;
  String? _assetId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      try {
        final assetsSnap = await FirebaseFirestore.instance
            .collection('assets')
            .where('tenantId', isEqualTo: uid)
            .limit(1)
            .get();

        if (assetsSnap.docs.isNotEmpty) {
          final assetDoc = assetsSnap.docs.first;
          _assetId = assetDoc.id;

          await _generateSingleRentBill(_assetId!);
        }

      } catch (e) {
        print('Error during bill initialization: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
    }
  }

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
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in.')),
      );
    }

    if (_isGenerating) {
      return Scaffold(
        appBar: AppBar(title: Text('Owing Records'), centerTitle: true, foregroundColor: Colors.white ,backgroundColor: Colors.indigo),
        backgroundColor: Colors.purple[50],
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_assetId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Owing Records'), centerTitle: true, foregroundColor: Colors.white ,backgroundColor: Colors.indigo),
        backgroundColor: Colors.purple[50],
        body: Center(child: Text('No asset linked to this tenant account.')),
      );
    }

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
            .collection('assets')
            .doc(_assetId)
            .collection('bills')
            .where('paid', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('StreamBuilder Error: ${snapshot.error}');
            return Center(child: Text('Error loading bills.'));
          }

          if (!snapshot.hasData) {
            return  Center(child: CircularProgressIndicator());
          }

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

              final amountText = data['amount'] is String
                  ? data['amount']
                  : 'RM ${data['amount'].toStringAsFixed(2)}';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.0),
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
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
                  title: Text('${data['type']} - ${data['month']} ${data['year']}'),
                  subtitle: Text('Amount: $amountText'),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
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