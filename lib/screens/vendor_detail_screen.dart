import 'package:flutter/material.dart';
import '../models/vendor.dart';

class VendorDetailScreen extends StatelessWidget {
  final Vendor vendor;

  const VendorDetailScreen({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(vendor.name)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nom: ${vendor.name}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Description: ${vendor.description}"),
            SizedBox(height: 10),
            Text("Latitude: ${vendor.latitude}"),
            Text("Longitude: ${vendor.longitude}"),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  // Ajouter aux favoris ou autre action
                },
                child: Text("Ajouter aux favoris"))
          ],
        ),
      ),
    );
  }
}
