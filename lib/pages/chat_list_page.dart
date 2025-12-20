import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  Stream<QuerySnapshot> _getTenantAssetsStream(String landlordId) {
    return FirebaseFirestore.instance
        .collection('assets')
        .where('landlordId', isEqualTo: landlordId)
        .where('tenantId', isNotEqualTo: null)
        .snapshots();
  }

  Future<DocumentSnapshot> _fetchTenantUserDoc(String tenantId) {
    return FirebaseFirestore.instance.collection('users').doc(tenantId).get();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final landlordId = user?.uid;

    if (landlordId == null) {
      return const Scaffold(body: Center(child: Text('Landlord not logged in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Tenants', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.purple[50],

      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _getTenantAssetsStream(landlordId),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final assetsWithTenants = snapshot.data!.docs;

            if (assetsWithTenants.isEmpty) {
              return const Center(child: Text("No tenants currently assigned to properties."));
            }

            final Map<String, Map<String, String>> uniqueTenants = {};
            for (var doc in assetsWithTenants) {
              final data = doc.data() as Map<String, dynamic>;
              final tenantId = data['tenantId'] as String?;
              final propertyName = data['name'] as String? ?? 'Property';

              if (tenantId != null) {
                if (!uniqueTenants.containsKey(tenantId) || uniqueTenants[tenantId]!['propertyName'] == 'Property') {
                  uniqueTenants[tenantId] = {'propertyName': propertyName, 'tenantId': tenantId};
                }
              }
            }

            final tenantEntries = uniqueTenants.values.toList();

            return ListView.builder(
              itemCount: tenantEntries.length,
              itemBuilder: (context, index) {
                final tenantId = tenantEntries[index]['tenantId']!;
                final propertyName = tenantEntries[index]['propertyName']!;

                return FutureBuilder<DocumentSnapshot>(
                  future: _fetchTenantUserDoc(tenantId),
                  builder: (context, userSnapshot) {
                    String tenantName = 'Loading...';
                    String ?tenantAvatar;
                    if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData && userSnapshot.data!.exists) {
                      tenantName = (userSnapshot.data!.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown Tenant';
                      tenantAvatar = (userSnapshot.data!.data() as Map<String, dynamic>?)?['avatarUrl'] ?? '';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 5,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),

                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(32.0),
                          child: tenantAvatar != null && tenantAvatar.isNotEmpty
                              ? Image.network(tenantAvatar, width: 40.0, height: 40.0, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40))
                              : const Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                        title: Text(tenantName, style: TextStyle(fontWeight: FontWeight.bold),),
                        subtitle: Text("Property: $propertyName"),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.indigo),
                          onPressed: () {},
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                receiverId: tenantId,
                                receiverName: tenantName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}