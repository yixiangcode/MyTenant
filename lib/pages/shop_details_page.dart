import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _launchPhone(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty || phoneNumber == "Phone not listed") return;

    final formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri(scheme: 'tel', path: formattedNumber);

    await _launchUrl(url);
  }

  Future<void> _launchWebsite(String? websiteUrl) async {
    if (websiteUrl == null || websiteUrl.isEmpty || websiteUrl == "Website not listed") return;

    String finalUrl = websiteUrl.startsWith('http') ? websiteUrl : 'https://$websiteUrl';

    final Uri url = Uri.parse(finalUrl);

    await _launchUrl(url);
  }

  Future<void> _launchMap(String? address) async {
    if (address == null || address.isEmpty || address == "N/A") return;

    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');

    await _launchUrl(url);
  }

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开: ${url.toString()}')),
        );
      }
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
    final String? address = details["formatted_address"];
    final String? phoneNumber = details["international_phone_number"];
    final String? website = details["website"];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details["name"] ?? "N/A",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  if (details.containsKey("rating"))
                    Text(
                      "Rating: ⭐ ${details["rating"]} (${details["user_ratings_total"]} reviews)",
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ),
          ),

          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.location_on,
                  address ?? "Address not listed",
                  address != null ? () => _launchMap(address) : null,
                ),
                _buildDetailRow(
                  Icons.phone,
                  phoneNumber ?? "Phone not listed",
                  phoneNumber != null ? () => _launchPhone(phoneNumber) : null,
                ),
                _buildDetailRow(
                  Icons.language,
                  website ?? "Website not listed",
                  website != null ? () => _launchWebsite(website) : null,
                ),
              ],
            ),
          ),

          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildOpeningHours(details["opening_hours"]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String? text, VoidCallback? onTap) {
    bool isAvailable = text != null && text.isNotEmpty && text != "Phone not listed" && text != "Website not listed" && text != "Address not listed";

    final finalOnTap = isAvailable ? onTap : null;

    String displayText = text ?? "N/A";

    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(displayText, style: TextStyle(
        decoration: TextDecoration.none,
        color: isAvailable ? Colors.blue.shade800 : Colors.black87,
      )),
      onTap: finalOnTap,
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
        const Text("🕒 Opening Hours:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
        const Divider(),
        ...hours.map((hour) => Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
          child: Text(hour, style: const TextStyle(fontSize: 16)),
        )).toList(),
      ],
    );
  }
}