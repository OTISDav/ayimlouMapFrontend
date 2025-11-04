import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/vendor.dart';
import '../services/api_service.dart';
import 'vendor_detail_screen.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng _initialCenter = const LatLng(6.170, 1.212);
  LatLng? _userLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loading = true;

  final FlutterTts _flutterTts = FlutterTts();
  BitmapDescriptor? _vendorIcon;

  final String _googleApiKey = 'AIzaSyCL3xPuxOlUMzh33k-z941HAn62HV_6qyE'; // ta clé API

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCustomMarker();
    await _determinePosition();
    await _loadVendors();
  }

  /// 🧩 Charger le pin personnalisé
  Future<void> _loadCustomMarker() async {
    _vendorIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)),
      'assets/icon/pin.png',
    );
  }

  /// 📍 Récupérer la position de l’utilisateur
  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _initialCenter = _userLocation!;
      });
    } catch (e) {
      debugPrint("Erreur de localisation : $e");
    }
  }

  /// 🧭 Charger les vendeurs depuis l’API
  Future<void> _loadVendors() async {
    try {
      final vendors = await ApiService.fetchVendors(
        lat: _userLocation?.latitude,
        lon: _userLocation?.longitude,
      );

      setState(() {
        _markers = vendors.map((vendor) {
          return Marker(
            markerId: MarkerId(vendor.id.toString()),
            position: LatLng(vendor.latitude, vendor.longitude),
            infoWindow: InfoWindow(
              title: vendor.name,
              snippet: vendor.description,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VendorDetailScreen(vendor: vendor)),
                );

                if (result != null) {
                  if (result['action'] == 'route') {
                    _drawRouteTo(vendor);
                  } else if (result['action'] == 'start') {
                    await _drawRouteTo(vendor);
                    _startNavigation(vendor);
                  }
                }
              },
            ),
            icon: _vendorIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          );
        }).toSet();
        _loading = false;
      });
    } catch (e) {
      debugPrint("Erreur lors du chargement des vendeurs : $e");
      setState(() => _loading = false);
    }
  }

  /// 🚗 Tracer l’itinéraire
  Future<void> _drawRouteTo(Vendor vendor) async {
    if (_userLocation == null) return;

    await _speak("Calcul de l’itinéraire jusqu’à ${vendor.name}...");

    PolylinePoints polylinePoints = PolylinePoints(apiKey: _googleApiKey);

    final result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(_userLocation!.latitude, _userLocation!.longitude),
        destination: PointLatLng(vendor.latitude, vendor.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      final routePoints =
          result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: Colors.blueAccent,
        width: 6,
      );

      setState(() => _polylines = {polyline});

      final bounds = _boundsFromList(routePoints);
      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));

      await _speak("Itinéraire prêt. Suivez la ligne bleue sur la carte.");
    } else {
      await _speak("Aucune route trouvée vers ${vendor.name}.");
    }
  }

  /// 🚘 Démarrer la navigation interne
  Future<void> _startNavigation(Vendor vendor) async {
    if (_polylines.isEmpty) {
      await _drawRouteTo(vendor);
    }

    final routePoints = _polylines.first.points;
    await _speak("Navigation vers ${vendor.name} démarrée.");

    for (final point in routePoints) {
      await Future.delayed(const Duration(milliseconds: 500));
      _mapController.animateCamera(CameraUpdate.newLatLng(point));
    }

    await _speak("Vous êtes arrivé à destination !");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🚗 Arrivé à destination !")),
    );
  }

  /// 🔊 Synthèse vocale
  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.9);
    await _flutterTts.speak(text);
  }

  /// 📐 Limites de la carte
  LatLngBounds _boundsFromList(List<LatLng> points) {
    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;

    for (var p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  /// 🧱 Interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SafeArea( // ✅ supprime l’espace vide du haut
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: _initialCenter, zoom: 14),
                    onMapCreated: (c) => _mapController = c,
                    myLocationEnabled: true,
                    markers: _markers,
                    polylines: _polylines,
                    zoomControlsEnabled: false,
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: "Rechercher un vendeur ou quartier...",
                          prefixIcon: Icon(Icons.search, color: Colors.teal),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        onSubmitted: (query) {
                          // TODO: Recherche interne
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    right: 20,
                    child: Column(
                      children: [
                        _buildActionButton(
                          icon: Icons.my_location,
                          onPressed: () {
                            if (_userLocation != null) {
                              _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(_userLocation!, 15),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          icon: Icons.refresh,
                          onPressed: _loadVendors,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 🎯 Boutons flottants
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.teal),
        onPressed: onPressed,
      ),
    );
  }
}
