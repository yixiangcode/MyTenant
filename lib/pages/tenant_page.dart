import 'package:flutter/material.dart';
import 'scanner_page.dart';
import 'maintenance_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'document_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TenantPage extends StatelessWidget {
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
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Hero(
              tag: 'logo',
              child: Image.asset('images/logo_white.png', height: 40),
            ),
            const SizedBox(width: 10),
            const Text('MyTenant', style: TextStyle(color: Colors.white)),
          ],
        ),
        //actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.settings))],
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<Map<String, dynamic>?>(
                    future: getUserInformation(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: CircularProgressIndicator(), // Loading
                          ),
                        );
                      }

                      if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return const Text('Loading error');
                      }

                      final userData = snapshot.data!;
                      final name = userData['name'] as String? ?? '-';
                      final email = userData['email'] as String? ?? '-';
                      final role = userData['role'] as String? ?? '-';
                      final contactNumber = userData['contactNumber'] as String? ?? "-";
                      final avatarUrl = userData['avatarUrl'] as String? ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'avatar',
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(avatarUrl),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            name,
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          Text(
                            email,
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              onTap: () {
                // Handle item tap
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Help'),
              onTap: () {
                // Handle item tap
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Logout Successful")),
                );

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),

      //backgroundColor: Colors.grey[100],
      backgroundColor: const Color(0xFFF2F4F7),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.lightBlue[100],
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        FutureBuilder<Map<String, dynamic>?>(
                          future: getUserInformation(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              // 数据加载中
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              // 数据加载错误
                              return Text(
                                "Welcome to My Tenant\nDisplay Error",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            } else {
                              final userData = snapshot.data!;
                              final name = userData['name'] as String? ?? '-';
                              final avatarUrl = userData['avatarUrl'] as String? ?? '';

                              return Row(
                                children: [
                                  Text(
                                    "$name\nUnpaid Bill: RM 2000\nDue Date: 12/12/2025",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(avatarUrl),
                                      radius: 35.0,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.0),

              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,

                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),

                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ScannerPage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.document_scanner,
                              size: 50,
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Scan Document",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DocumentPage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.article, size: 50, color: Colors.indigo),
                            const SizedBox(height: 12),
                            Text(
                              "View Document",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MaintenancePage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.handyman,
                              size: 50,
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Maintenance",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MaintenancePage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_atm,
                              size: 50,
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Owing Records",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MaintenancePage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications,
                              size: 50,
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Notification",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MaintenancePage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat,
                              size: 50,
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Chat",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
}
