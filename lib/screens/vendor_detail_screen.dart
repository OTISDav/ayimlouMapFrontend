import 'package:flutter/material.dart';
import '../models/vendor.dart';

class VendorDetailScreen extends StatelessWidget {
  final Vendor vendor;
  const VendorDetailScreen({required this.vendor, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vendor.name),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage de la photo si disponible
            if (vendor.photo != null && vendor.photo!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    vendor.photo!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              vendor.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(vendor.description),
            const SizedBox(height: 12),
            // Row(
            //   children: [
            //     const Icon(Icons.location_on, color: Colors.teal),
            //     const SizedBox(width: 8),
            //     Text('Lat: ${vendor.latitude}, Lon: ${vendor.longitude}'),
            //   ],
            // ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.alt_route),
                  label: const Text('Itinéraire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(
                        context, {'action': 'route', 'vendor': vendor});
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.navigation),
                  label: const Text('Démarrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(
                        context, {'action': 'start', 'vendor': vendor});
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Favori'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
                  ),
                  onPressed: () {
                    // TODO: Ajouter aux favoris
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
