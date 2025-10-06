import 'package:flutter/material.dart';
import 'package:tenant/pages/maintenance_page.dart';
import 'property_page.dart';
import 'scanner_page.dart';
import 'maintenance_page.dart';
import 'login_page.dart';

class TenantPage extends StatelessWidget {
  final List<Map<String, dynamic>> menuItems = [
    {
      "title": "Upload Document",
      "icon": Icons.upload_file,
      "page": ScannerPage(),
    },
    {
      "title": "View Document",
      "icon": Icons.article,
      "page": null, // 还没做页面，先用 null 占位
    },
    {
      "title": "Report Problem",
      "icon": Icons.build_circle,
      "page": MaintenancePage(),
    },
    {
      "title": "Owing Records",
      "icon": Icons.attach_money,
      "page": null,
    },
    {
      "title": "Notifications",
      "icon": Icons.notifications,
      "page": null,
    },
    {
      "title": "Logout",
      "icon": Icons.logout,
      "page": LoginPage(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Row(
          children: [
            Image.asset(
              'images/logo_white.png',
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text('MyTenant', style: TextStyle(color: Colors.white),),
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
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('images/logo.png'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome to MyTenant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'admin@yixiang.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('Profile'),
              onTap: () {
                // Handle item tap
              },
            ),
            ListTile(
              title: Text('About'),
              onTap: () {
                // Handle item tap
              },
            ),
            ListTile(
              title: Text('Help'),
              onTap: () {
                // Handle item tap
              },
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () {

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ), (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),

      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: InkWell(
                onTap: () {
                  if (item["page"] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item["page"]),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${item['title']} 功能还没做")),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'], size: 40, color: Colors.indigo),
                      const SizedBox(height: 12),
                      Text(
                        item['title'],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}