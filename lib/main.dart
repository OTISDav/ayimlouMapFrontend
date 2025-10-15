import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

// Modèle Vendor
class Vendor {
  final int id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  Vendor({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}

// Simuler une récupération des vendors depuis API
Future<List<Vendor>> fetchVendors() async {
  // Ici, tu remplaces par un appel http à ton backend
  await Future.delayed(Duration(seconds: 1));
  return [
    Vendor(id: 1, name: 'Vendeur 1', description: 'Meilleur Ayimolou', latitude: 6.170, longitude: 1.212),
    Vendor(id: 2, name: 'Vendeur 2', description: 'Ayimolou frais', latitude: 6.171, longitude: 1.215),
  ];
}

void main() {
  runApp(AyimolouMapApp());
}

class AyimolouMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AyimolouMap',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng _center = LatLng(6.170, 1.212);
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifie si le service GPS est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Le service de localisation est désactivé.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permission de localisation refusée');
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
    });

    _loadVendors();
  }

  Future<void> _loadVendors() async {
    List<Vendor> vendors = await fetchVendors();
    setState(() {
      markers = vendors
          .map((vendor) => Marker(
                markerId: MarkerId(vendor.id.toString()),
                position: LatLng(vendor.latitude, vendor.longitude),
                infoWindow: InfoWindow(title: vendor.name, snippet: vendor.description),
              ))
          .toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AyimolouMap')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _center, zoom: 15),
        markers: markers,
        onMapCreated: (controller) => mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
