import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShopDetailsPage extends StatefulWidget {
  final String placeId;
  final String shopName;

  const ShopDetailsPage({super.key, required this.placeId, required this.shopName});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final String apiKey = "";

  Map<String, dynamic>? shopDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShopDetails();
  }

  Future<void> _fetchShopDetails() async {
    const fields = "name,formatted_address,international_phone_number,website,opening_hours,rating,user_ratings_total,photo";

    final url = "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=${widget.placeId}"
        "&fields=$fields"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (mounted) {
        setState(() {
          shopDetails = data["result"];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print("Error fetching details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      backgroundColor: Colors.purple[50],

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : shopDetails == null
          ? const Center(child: Text("Details not available."))
          : _buildDetailsContent(shopDetails!),
    );
  }

  Widget _buildDetailsContent(Map<String, dynamic> details) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(details["name"] ?? "N/A", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Address: ${details["formatted_address"] ?? "N/A"}"),

          if (details.containsKey("rating"))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Rating: ⭐ ${details["rating"]} (${details["user_ratings_total"]} reviews)", style: const TextStyle(fontSize: 16)),
            ),

          const Divider(),
          _buildDetailRow(Icons.phone, details["international_phone_number"] ?? "Phone not listed"),
          _buildDetailRow(Icons.language, details["website"] ?? "Website not listed"),

          const Divider(),
          _buildOpeningHours(details["opening_hours"]),

          // Add button or map
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(text),
    );
  }

  Widget _buildOpeningHours(Map<String, dynamic>? openingHours) {
    if (openingHours == null || !openingHours.containsKey("weekday_text")) {
      return const Text("Opening hours details not available.");
    }

    final List<String> hours = (openingHours["weekday_text"] as List).cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Opening Hours:", style: TextStyle(fontWeight: FontWeight.bold)),
        ...hours.map((hour) => Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(hour),
        )).toList(),
      ],
    );
  }
}