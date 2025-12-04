import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  Future<void> _handleAccept(
      BuildContext context,
      String inviteDocId,
      String tenantId,
      String landlordId
      ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(tenantId).update({
        'landlordId': landlordId,
      });

      await FirebaseFirestore.instance.collection('invites').doc(inviteDocId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation accepted! You are now linked to the landlord.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Acceptance failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleReject(BuildContext context, String inviteDocId) async {
    try {
      await FirebaseFirestore.instance.collection('pending_invites').doc(inviteDocId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation rejected.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejection failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final tenantId = currentUser?.uid;

    if (tenantId == null) {
      return const Scaffold(body: Center(child: Text('Please log in as a Tenant.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      backgroundColor: Colors.purple[50],

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invites')
            .where('tenantId', isEqualTo: tenantId)
            .where('status', isEqualTo: 'pending')
            .orderBy('sentAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final invites = snapshot.data?.docs ?? [];

          if (invites.isEmpty) {
            return const Center(child: Text('You have no pending notifications.'));
          }

          return ListView.builder(
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final inviteDoc = invites[index];
              final inviteData = inviteDoc.data() as Map<String, dynamic>;
              final inviteDocId = inviteDoc.id;
              final landlordEmail = inviteData['landlordEmail'] as String? ?? 'Unknown Landlord';
              final landlordId = inviteData['landlordId'] as String;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(36.0),
                ),
                elevation: 3.0,

                child: ListTile(
                  leading: const Icon(Icons.mail, color: Colors.indigo),
                  title: const Text('Invitation'),
                  subtitle: Text('From: $landlordEmail'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _handleAccept(
                            context,
                            inviteDocId,
                            tenantId,
                            landlordId
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _handleReject(context, inviteDocId),
                      ),
                    ],
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