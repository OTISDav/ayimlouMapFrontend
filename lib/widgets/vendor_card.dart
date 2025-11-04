import 'package:flutter/material.dart';
import '../models/vendor.dart';

class VendorCard extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback? onTap;
  VendorCard({required this.vendor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.restaurant, color: Colors.white)),
        title: Text(vendor.name),
        subtitle: Text(vendor.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
