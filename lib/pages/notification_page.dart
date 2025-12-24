import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  Future<void> _handleAccept(BuildContext context, String inviteDocId, String tenantId, String landlordId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(tenantId).update({'landlordId': landlordId});
      await FirebaseFirestore.instance.collection('invites').doc(inviteDocId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation accepted!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Acceptance failed: $e')));
    }
  }

  Future<void> _handleReject(BuildContext context, String inviteDocId) async {
    try {
      await FirebaseFirestore.instance.collection('invites').doc(inviteDocId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation rejected.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rejection failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantId = FirebaseAuth.instance.currentUser?.uid;
    if (tenantId == null) return const Scaffold(body: Center(child: Text('Please log in.')));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          centerTitle: true,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Maintenance", icon: Icon(Icons.build)),
              Tab(text: "Bills", icon: Icon(Icons.payments)),
              Tab(text: "Invites", icon: Icon(Icons.mail)),
            ],
          ),
        ),
        backgroundColor: Colors.purple[50],
        body: TabBarView(
          children: [
            _buildMaintenanceList(tenantId),
            _buildBillsList(tenantId),
            _buildInvitesList(tenantId),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitesList(String tenantId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('invites').where('tenantId', isEqualTo: tenantId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No pending invites.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.person_add, color: Colors.indigo),
                title: const Text('Property Invitation'),
                subtitle: Text('From: ${data['landlordEmail']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _handleAccept(context, docs[index].id, tenantId, data['landlordId'])),
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _handleReject(context, docs[index].id)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBillsList(String tenantId) {
    final isNearDeadline = DateTime.now().day <= 15;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('bills').where('ownerId', isEqualTo: tenantId).where('paid', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('All bills are paid!'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.0),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: isNearDeadline ? Colors.red[50] : Colors.white,
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: isNearDeadline ? Colors.red : Colors.orange),
                title: Text('${data['type']} Bill - ${data['month']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Due date: before 15th of month'),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMaintenanceList(String tenantId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maintenance_requests')
          .where('tenantId', isEqualTo: tenantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No maintenance records.'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final imageUrl = data['imageUrl'];

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.0),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ListTile(
                leading: imageUrl != null && imageUrl != ''
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _getStatusIcon(status),
                  ),
                )
                    : _getStatusIcon(status),
                title: Text(data['furnitureName'] ?? 'Repair Request', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Status: ${status.toUpperCase()}'),
                trailing: Text(
                  _getStatusText(status),
                  style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Icon _getStatusIcon(String s) => s == 'completed' ? const Icon(Icons.check_circle, color: Colors.green) : (s == 'in progress' ? const Icon(Icons.sync, color: Colors.blue) : const Icon(Icons.pending, color: Colors.orange));
  Color _getStatusColor(String s) => s == 'completed' ? Colors.green : (s == 'in progress' ? Colors.blue : Colors.orange);
  String _getStatusText(String s) => s == 'completed' ? "Done" : (s == 'in progress' ? "Fixing" : "Pending");
}