import 'package:flutter/material.dart';
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
              leading: const Icon(Icons.account_circle_rounded),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_rounded),
              title: const Text('About'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_rounded),
              title: const Text('Help'),
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AIChatPage()),
                );
                },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      "Logout Successfully.",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),

                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    margin: const EdgeInsets.all(25),
                    elevation: 8.0,
                  ),
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

      /*
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AIChatPage()),
          );
        },
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.support_agent_rounded, size: 45,),
      ),
      */

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
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 6.0,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfilePage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
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
                  _buildGridItem(context, Icons.document_scanner_rounded, "Scan Document", () => ScannerPage()),
                  _buildGridItem(context, Icons.description_rounded, "View Document", () => DocumentPage()),
                  _buildGridItem(context, Icons.handyman_rounded, "Maintenance", () => MaintenancePage()),
                  _buildGridItem(context, Icons.forum_rounded, "Chat", () => ChatPage(receiverId: landlordId, receiverName: 'Chat with Landlord',)),
                  _buildGridItem(context, Icons.local_atm_rounded, "Owing Records", () => OwingPage()),
                  _buildGridItem(context, Icons.notifications_rounded, "Notification", () => NotificationPage()),
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
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 6.0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => targetPage()),
          );
        },
        borderRadius: BorderRadius.circular(30),
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