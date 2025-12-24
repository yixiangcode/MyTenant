import 'package:flutter/material.dart';
import 'package:tenant/pages/about_page.dart';
import 'package:tenant/pages/ai_chat_page.dart';
import 'package:tenant/pages/owing_page.dart';
import 'notification_page.dart';
import 'scanner_page.dart';
import 'maintenance_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'document_page.dart';
import 'chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TenantPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const TenantPage({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = userData['name'] as String? ?? '-';
    final email = userData['email'] as String? ?? '-';
    final avatarUrl = userData['avatarUrl'] as String? ?? '';
    final landlordId = userData['landlordId'] as String? ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Hero(
              tag: 'logo',
              child: Image(image: AssetImage('images/logo_white.png'), height: 40),
            ),
            const SizedBox(width: 10),
            const Text('My', style: TextStyle(color: Colors.white, fontFamily: 'Pacifico')),
            const Text('Tenant', style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Pacifico')),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'avatar',
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 20)),
                  Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle_rounded),
              title: const Text('Profile'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage())),
            ),
            ListTile(
              leading: const Icon(Icons.info_rounded),
              title: const Text('About'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AboutPage())),
            ),
            ListTile(
              leading: const Icon(Icons.help_rounded),
              title: const Text('Help'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIChatPage())),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.indigo, Colors.cyan.shade200],
            )
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collectionGroup('bills').where('ownerId', isEqualTo: uid).where('paid', isEqualTo: false).snapshots(),
                  builder: (context, snapshot) {
                    double total = 0;
                    int count = 0;
                    if (snapshot.hasData) {
                      count = snapshot.data!.docs.length;
                      for (var doc in snapshot.data!.docs) {
                        total += (doc['amount'] is num) ? doc['amount'] : double.tryParse(doc['amount'].toString()) ?? 0;
                      }
                    }
                    bool hasDebt = count > 0;
                    return Card(
                      color: hasDebt ? Colors.orange[200] : Colors.indigoAccent[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 6.0,
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
                        borderRadius: BorderRadius.circular(30),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Hi, $name", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(hasDebt ? "Upcoming Bill: RM ${total.toStringAsFixed(2)}" : "Upcoming Bills: RM 0",
                                        style: TextStyle(fontSize: 18, color: hasDebt ? Colors.red[900] : Colors.indigo, fontWeight: FontWeight.bold)),
                                    Text(hasDebt ? "You have $count unpaid bills." : "No outstanding bills", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              Hero(tag: 'avatar', child: CircleAvatar(backgroundImage: NetworkImage(avatarUrl), radius: 35.0)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collectionGroup('bills').where('tenantId', isEqualTo: uid).where('paid', isEqualTo: false).snapshots(),
                    builder: (context, snapshot) {
                      int unpaidCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildGridItem(context, Icons.document_scanner_rounded, "Scan Document", () => ScannerPage()),
                          _buildGridItem(context, Icons.description_rounded, "View Document", () => DocumentPage()),
                          _buildGridItem(context, Icons.handyman_rounded, "Maintenance", () => MaintenancePage()),
                          _buildGridItem(context, Icons.forum_rounded, "Chat", () => ChatPage(receiverId: landlordId, receiverName: 'Chat with Landlord')),
                          _buildGridItem(context, Icons.local_atm_rounded, "Owing Records", () => OwingPage(), badgeCount: unpaidCount),
                          _buildGridItem(context, Icons.notifications_rounded, "Notification", () => NotificationPage()),
                        ],
                      );
                    }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, IconData icon, String title, Widget Function() targetPage, {int badgeCount = 0}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 6.0,
      child: Stack(
        children: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage())),
            borderRadius: BorderRadius.circular(30),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 50, color: Colors.indigo),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: 15,
              top: 15,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: Colors.red,
                child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}