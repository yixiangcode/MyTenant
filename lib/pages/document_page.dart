import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    return Scaffold(
      backgroundColor: Colors.purple[50],

      appBar: AppBar(
        title: const Text('Document', style: TextStyle(color: Colors.white)),
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
                  final icImageUrl = userData['icImageUrl'] as String? ?? '-';
                  final contractImageUrl =
                      userData['contractImageUrl'] as String? ?? '-';
                  final billImageUrl =
                      userData['billImageUrl'] as String? ?? '-';

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
                                    )
                                  : const Icon(Icons.broken_image, size: 50),
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
                              )
                                  : const Icon(Icons.broken_image, size: 50),
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
                                Icons.mail,
                                color: Colors.deepPurple,
                              ),
                              title: Text(
                                "Bill",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: billImageUrl.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  billImageUrl,
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
                              )
                                  : const Icon(Icons.broken_image, size: 50),
                            ),
                          ],
                        ),
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
