import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'scanner_page.dart';

class DocumentPage extends StatelessWidget {
  const DocumentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    Future<Map<String, dynamic>?> getUserInformation() async {
      DocumentSnapshot userInfo = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return userInfo.data() as Map<String, dynamic>?;
    }

    Future<String?> _getAssetId() async {
      final assetQuery = await FirebaseFirestore.instance
          .collection('assets')
          .where('tenantId', isEqualTo: uid)
          .limit(1)
          .get();

      if (assetQuery.docs.isNotEmpty) {
        return assetQuery.docs.first.id;
      }
      return null;
    }

    return Scaffold(
      backgroundColor: Colors.purple[50],

      appBar: AppBar(
        title: const Text('My Document', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<Map<String, dynamic>?>(
                future: getUserInformation(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: double.infinity,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return const Text('Loading error');
                  }

                  final userData = snapshot.data!;
                  final name = userData['name'] as String? ?? '-';
                  final role = userData['role'] as String? ?? '-';
                  final avatarUrl = userData['avatarUrl'] as String? ?? '';
                  var icImageUrl = userData['icImageUrl'] as String? ?? '-';
                  var contractImageUrl = userData['contractImageUrl'] as String? ?? '-';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 35.0),
                      Hero(
                        tag: 'avatar',
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(avatarUrl),
                          radius: 70.0,
                        ),
                      ),
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        role,
                        style: TextStyle(
                          fontFamily: 'Source Sans Pro',
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 30.0),

                      Card(
                        margin: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.account_box,
                                color: Colors.deepPurple,
                              ),
                              title: Text(
                                "Identity Card",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if(icImageUrl.isEmpty)
                                    IconButton(
                                      icon: Icon(Icons.add_a_photo),
                                      color: Colors.deepPurple,
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => ScannerPage()),
                                        );
                                      },
                                    ),

                                  if(icImageUrl.isNotEmpty)...[
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      color: Colors.deepPurple,
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => ScannerPage()),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        Reference storageRef = FirebaseStorage.instance.refFromURL(icImageUrl);
                                        await storageRef.delete();

                                        await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                          'icImageUrl': '',
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Identity Card deleted successfully!')),
                                        );

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => DocumentPage()),
                                        );

                                      },
                                  ),]
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: icImageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        icImageUrl,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,

                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }

                                          return SizedBox(
                                            height: 200,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },

                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                ),
                                      ),
                                    ) : const Text("No Identity Card Recorded"),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 8.0),

                      Card(
                        margin: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.badge,
                                color: Colors.deepPurple,
                              ),
                              title: Text(
                                "Contract",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if(contractImageUrl.isEmpty)
                                    IconButton(
                                      icon: Icon(Icons.add_a_photo),
                                      color: Colors.deepPurple,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => ScannerPage()),
                                        );
                                      },
                                    ),

                                  if(contractImageUrl.isNotEmpty)...[
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      color: Colors.deepPurple,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => ScannerPage()),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        Reference storageRef = FirebaseStorage.instance.refFromURL(contractImageUrl);
                                        await storageRef.delete();

                                        await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                          'contractImageUrl': '',
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Contract deleted successfully!')),
                                        );

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => DocumentPage()),
                                        );

                                      },
                                    ),]
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: contractImageUrl.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  contractImageUrl,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,

                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }

                                    return SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                          loadingProgress
                                              .expectedTotalBytes !=
                                              null
                                              ? loadingProgress
                                              .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },

                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                  ),
                                ),
                              ) : const Text("No Contract Recorded"),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 8.0),

                      FutureBuilder<String?>(
                        future: _getAssetId(),
                        builder: (context, assetSnapshot) {
                          if (assetSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          }

                          final assetId = assetSnapshot.data;

                          if (assetId == null) {
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 10.0),
                              child: ListTile(
                                title: Text("Utility Bills", style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("No linked property found to view bills."),
                              ),
                            );
                          }
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('assets')
                                .doc(assetId)
                                .collection('bills')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, billSnapshot) {
                              if (billSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (billSnapshot.hasError) {
                                return Center(child: Text("Error loading bills: ${billSnapshot.error}"));
                              }

                              final bills = billSnapshot.data!.docs;

                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.mail, color: Colors.deepPurple),
                                      title: Text("Utility Bills (${bills.length})", style: TextStyle(fontWeight: FontWeight.bold)),
                                      trailing: IconButton(
                                        icon: Icon(Icons.add, color: Colors.deepPurple),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => ScannerPage()));
                                        },
                                      ),
                                    ),
                                    Divider(),

                                    if (bills.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text("No Bills Recorded."),
                                      ),

                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: bills.length,
                                      itemBuilder: (context, index) {
                                        final bill = bills[index].data() as Map<String, dynamic>;
                                        final docId = bills[index].id;
                                        final billImageUrl = bill['imageUrl'] as String? ?? '';

                                        final billTitle = "${bill['month'] ?? 'Month N/A'} ${bill['year'] ?? ''}";

                                        return Column(
                                          children: [
                                            ListTile(
                                              title: Text(billTitle),
                                              subtitle: Text("Amount: ${bill['amount'] ?? 'N/A'}  [ ${bill['type'] ?? 'N/A'} Bill ]"),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () async {
                                                      if (billImageUrl.isNotEmpty) {
                                                        await FirebaseStorage.instance.refFromURL(billImageUrl).delete();
                                                      }

                                                      await FirebaseFirestore.instance
                                                          .collection('assets').doc(assetId)
                                                          .collection('bills').doc(docId)
                                                          .delete();

                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Bill of $billTitle deleted successfully.')),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              onTap: () {
                                                if (billImageUrl.isNotEmpty) {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      content: Image.network(
                                                        billImageUrl,
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
                                            Divider(height: 1),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }
}
