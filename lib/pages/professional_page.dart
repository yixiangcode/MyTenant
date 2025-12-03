import 'package:flutter/material.dart';
import 'shop_details_page.dart';

class ProfessionalPage extends StatelessWidget {
  final List<dynamic> shops;

  const ProfessionalPage({super.key, required this.shops});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nearby Professionals"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.indigo,
      ),
      backgroundColor: Colors.purple[50],

      body: ListView.builder(
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index] as Map<String, dynamic>;

          final String? placeId = shop["place_id"];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 3.0,
            child: ListTile(
              leading: const Icon(Icons.store, size: 32, color: Colors.indigo),
              title: Text(shop["name"] ?? "No name"),
              subtitle: Text(shop["vicinity"] ?? "No address"),
              trailing: Text(
                shop["rating"] != null ? "⭐ ${shop["rating"]}" : "",
                style: const TextStyle(fontSize: 16),
              ),

              onTap: () {
                if (placeId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopDetailsPage(
                        placeId: placeId,
                        shopName: shop["name"] ?? "Details",
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: No Place ID available for this shop.')),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
