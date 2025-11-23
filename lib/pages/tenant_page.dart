import 'package:flutter/material.dart';
import 'notification_page.dart';
import 'scanner_page.dart';
import 'maintenance_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'document_page.dart';
import 'chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TenantPage extends StatelessWidget {

  final Map<String, dynamic> userData;
  const TenantPage({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final name = userData['name'] as String? ?? '-';
    final email = userData['email'] as String? ?? '-';
    final avatarUrl = userData['avatarUrl'] as String? ?? '';
    final landlordId = userData['landlordId'] as String? ?? '';

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
            const Text('MyTenant', style: TextStyle(color: Colors.white, fontFamily: 'Pacifico')),
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
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logout Successful")),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.purple[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.indigoAccent[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfilePage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hi, $name",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Upcoming Bill: RM 2000",
                                style: TextStyle(fontSize: 16, color: Colors.indigo),
                              ),
                              const Text(
                                "Due Date: 15 December 2025",
                                style: TextStyle(fontSize: 16, color: Colors.indigo),
                              ),
                            ],
                          ),
                        ),
                        Hero(
                          tag: 'avatar',
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(avatarUrl),
                            radius: 35.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGridItem(context, Icons.document_scanner, "Scan Document", () => ScannerPage()),
                  _buildGridItem(context, Icons.article, "View Document", () => DocumentPage()),
                  _buildGridItem(context, Icons.handyman, "Maintenance", () => MaintenancePage()),
                  _buildGridItem(context, Icons.local_atm, "Owing Records", () => NotificationPage()),
                  _buildGridItem(context, Icons.notifications, "Notification", () => NotificationPage()),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatPage(receiverId: landlordId, receiverName: 'Chat with Landlord',)),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.chat, size: 50, color: Colors.indigo),
                            SizedBox(height: 12),
                            Text("Chat", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, IconData icon, String title, Widget Function() targetPage) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => targetPage()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: Colors.indigo,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}