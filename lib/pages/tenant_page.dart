import 'package:flutter/material.dart';
import 'property_page.dart';

class TenantPage extends StatelessWidget {
  final List<Map<String, dynamic>> menuItems = [
    {
      "title": "Upload Document",
      "icon": Icons.upload_file,
      "page": const PropertyPage(ownerId: "123"),
    },
    {
      "title": "View Document",
      "icon": Icons.article,
      "page": null, // 还没做页面，先用 null 占位
    },
    {
      "title": "Report Problem",
      "icon": Icons.build_circle,
      "page": null,
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
      "page": null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MyTenant", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
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