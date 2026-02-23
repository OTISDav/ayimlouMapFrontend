import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../models/vendor.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../styles/map_style.dart';
import 'vendor_detail_screen.dart';
import 'donation_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AYIMOLOU MAP  •  Map Screen — Light & Modern
// ─────────────────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {

  // ── Palette (cohérente avec Splash v3) ───────────────────────────────────
  static const Color _orange   = Color(0xFFFF5C2A);
  static const Color _green    = Color(0xFF00B87C);
  static const Color _yellow   = Color(0xFFFFCC00);
  static const Color _white    = Color(0xFFFFFFFF);
  static const Color _bg       = Color(0xFFF7F3EE);
  static const Color _dark     = Color(0xFF1A1A1A);
  static const Color _grey     = Color(0xFF9A9A9A);
  static const Color _greyLt   = Color(0xFFEEEAE4);

  // ── State ─────────────────────────────────────────────────────────────────
  late GoogleMapController _mapController;
  LatLng _initialCenter = const LatLng(6.170, 1.212);
  LatLng? _userLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loading = true;
  bool _searchFocused = false;

  // Search
  List<Vendor> _allVendors = [];          // liste complète (jamais modifiée)
  List<Vendor> _searchResults = [];       // résultats filtrés
  bool _showResults = false;

  final TtsService _tts = TtsService.instance;
  bool _ttsReady = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  BitmapDescriptor? _vendorIcon;
  BitmapDescriptor? _highlightedIcon;
  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  Vendor? _selectedVendor;
  bool _readyToNavigate = false;
  StreamSubscription<Position>? _gpsStream;

  // Bottom sheet animation
  late final AnimationController _sheetCtrl;
  late final Animation<Offset> _sheetAnim;
  bool _sheetVisible = false;

  // FAB pulse animation
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _sheetAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _searchFocus.addListener(() {
      setState(() {
        _searchFocused = _searchFocus.hasFocus;
        if (!_searchFocus.hasFocus) _showResults = false;
      });
    });

    _searchCtrl.addListener(_onSearchChanged);

    _initialize();
  }

  Future<void> _initialize() async {
    await _tts.init();
    setState(() => _ttsReady = true);

    // Génère les icônes custom AVANT de charger les vendeurs
    _vendorIcon = await _createMarkerIcon(
      color: const Color(0xFFFF5C2A),
      highlighted: false,
    );
    _highlightedIcon = await _createMarkerIcon(
      color: const Color(0xFF1A1A1A),
      highlighted: true,
    );

    await _determinePosition();
    await _loadVendors();
    await _tts.onAppReady();
  }

  // ── Génère une épingle personnalisée avec Canvas ──────────────────────────
  Future<BitmapDescriptor> _createMarkerIcon({
    required Color color,
    required bool highlighted,
  }) async {
    const double w = 80;
    const double h = 100;
    const double r = 36; // rayon du cercle

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder,
        Rect.fromLTWH(0, 0, w, h));

    // ── Ombre portée ──────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      const Offset(w / 2, r + 4),
      r,
      shadowPaint,
    );

    // ── Cercle principal ──────────────────────────────────────────────
    final bgPaint = Paint()..color = color;
    canvas.drawCircle(const Offset(w / 2, r), r, bgPaint);

    // ── Bordure blanche ───────────────────────────────────────────────
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(const Offset(w / 2, r), r - 1, borderPaint);

    // ── Pointe en bas ─────────────────────────────────────────────────
    final pointerPaint = Paint()..color = color;
    final path = Path()
      ..moveTo(w / 2 - 10, r + r - 6)
      ..lineTo(w / 2, h - 8)
      ..lineTo(w / 2 + 10, r + r - 6)
      ..close();
    canvas.drawPath(path, pointerPaint);

    // ── Emoji 🍚 au centre ────────────────────────────────────────────
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: highlighted ? 26 : 28,
        textAlign: TextAlign.center,
      ),
    )..addText('🍚');
    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: w));
    canvas.drawParagraph(
      paragraph,
      Offset(0, r - paragraph.height / 2),
    );

    // ── Point blanc au bas de la pointe ───────────────────────────────
    canvas.drawCircle(
      Offset(w / 2, h - 6),
      3,
      Paint()..color = Colors.white.withOpacity(0.8),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

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

  Future<void> _loadVendors() async {
    try {
      final vendors = await ApiService.fetchVendors(
        lat: _userLocation?.latitude,
        lon: _userLocation?.longitude,
      );
      setState(() {
        _allVendors = vendors;  // sauvegarde complète pour la recherche
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
                  MaterialPageRoute(
                    builder: (_) => VendorDetailScreen(vendor: vendor),
                  ),
                );
                if (result != null) {
                  if (result['action'] == 'route') {
                    _drawRouteTo(vendor);
                  } else if (result['action'] == 'start') {
                    await _drawRouteTo(vendor);
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
      // Annonce du nombre de vendeurs trouvés
      await _tts.onVendorsLoaded(_allVendors.length);
    } catch (e) {
      debugPrint("Erreur chargement vendeurs : $e");
      setState(() => _loading = false);
    }
  }

  // ── Search logic ──────────────────────────────────────────────────────────
  void _onSearchChanged() {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showResults = false;
        _searchResults = [];
        // Restaurer tous les markers
        _rebuildMarkers(_allVendors);
      });
      return;
    }

    final filtered = _allVendors.where((v) {
      return v.name.toLowerCase().contains(query) ||
          v.description.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _searchResults = filtered;
      _showResults = true;
    });
  }

  void _selectVendorFromSearch(Vendor vendor) {
    _searchCtrl.text = vendor.name;
    _searchFocus.unfocus();
    setState(() => _showResults = false);

    // Centrer la carte sur ce vendeur
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(vendor.latitude, vendor.longitude),
        16,
      ),
    );

    // Mettre en évidence uniquement ce marker
    _rebuildMarkers(_allVendors, highlighted: vendor);
  }

  void _rebuildMarkers(List<Vendor> vendors, {Vendor? highlighted}) {
    _markers = vendors.map((vendor) {
      final isHighlighted = highlighted?.id == vendor.id;
      return Marker(
        markerId: MarkerId(vendor.id.toString()),
        position: LatLng(vendor.latitude, vendor.longitude),
        infoWindow: InfoWindow(
          title: vendor.name,
          snippet: vendor.description,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VendorDetailScreen(vendor: vendor),
              ),
            );
            if (result != null) {
              if (result['action'] == 'route') _drawRouteTo(vendor);
              else if (result['action'] == 'start') await _drawRouteTo(vendor);
            }
          },
        ),
        icon: isHighlighted
            ? (_highlightedIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
            : (_vendorIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)),
        zIndex: isHighlighted ? 2 : 1,
      );
    }).toSet();
  }

  Future<void> _drawRouteTo(Vendor vendor) async {
    if (_userLocation == null) return;
    await _tts.onRouteCalculating(vendor.name);

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
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: _orange,
            width: 5,
            patterns: [],
          ),
        };
        _selectedVendor = vendor;
        _readyToNavigate = true;
      });
      final bounds = _boundsFromList(routePoints);
      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      await _tts.onRouteReady(vendor.name);

      _sheetCtrl.forward();
      setState(() => _sheetVisible = true);
    } else {
      await _tts.onRouteNotFound(vendor.name);
    }
  }

  void _startNavigation() async {
    if (_selectedVendor == null) return;
    final vendor = _selectedVendor!;
    await _tts.onNavigationStarted(vendor.name);
    _gpsStream?.cancel();

    _gpsStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((Position position) async {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );

      final dist = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        vendor.latitude, vendor.longitude,
      );

      final arrived = dist <= 10;
      await _tts.announceGps(dist);

      if (arrived) {
        _gpsStream?.cancel();
        if (mounted) {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) =>
                  DonationScreen(vendorName: vendor.name),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                child: child,
              ),
            ),
          );
          _dismissSheet();
        }
      }
    });
    setState(() => _readyToNavigate = false);
  }

  LatLngBounds _boundsFromList(List<LatLng> points) {
    double south = points.first.latitude, north = points.first.latitude;
    double west = points.first.longitude, east = points.first.longitude;
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

  void _dismissSheet() {
    _sheetCtrl.reverse().then((_) {
      setState(() {
        _sheetVisible = false;
        _readyToNavigate = false;
        _selectedVendor = null;
        _polylines = {};
      });
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _loading ? _buildLoader() : _buildMap(),
    );
  }

  // ── Loading state ─────────────────────────────────────────────────────────
  Widget _buildLoader() {
    return Container(
      color: _bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_orange, Color(0xFFFF3D00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _orange.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🍚', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chargement de la carte...',
              style: TextStyle(
                fontSize: 14,
                color: _grey,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 48,
              child: LinearProgressIndicator(
                backgroundColor: _greyLt,
                color: _orange,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main map UI ───────────────────────────────────────────────────────────
  Widget _buildMap() {
    return Stack(
      children: [
        // ── Google Map ───────────────────────────────────────────────
        GoogleMap(
          initialCameraPosition:
          CameraPosition(target: _initialCenter, zoom: 14),
          onMapCreated: (c) {
            _mapController = c;
            c.setMapStyle(ayimolouMapStyle);
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _markers,
          polylines: _polylines,
        ),

        // ── Top safe area overlay ────────────────────────────────────
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search bar
              _buildSearchBar(),

              // Search results dropdown
              if (_showResults) _buildSearchResults(),

              // Vendor count chip
              if (!_searchFocused && !_showResults) _buildVendorChip(),
            ],
          ),
        ),

        // ── FAB cluster (right side) ─────────────────────────────────
        Positioned(
          right: 16,
          bottom: _sheetVisible ? 210 : 40,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => _buildFabCluster(),
          ),
        ),

        // ── Bottom navigation sheet ──────────────────────────────────
        if (_sheetVisible) _buildNavigationSheet(),
      ],
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_searchFocused ? 0.12 : 0.07),
              blurRadius: _searchFocused ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _searchFocused
                ? _orange.withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search_rounded,
              color: _searchFocused ? _orange : _grey,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                style: const TextStyle(
                  fontSize: 15,
                  color: _dark,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Vendeur, quartier...',
                  hintStyle: TextStyle(
                    color: _grey.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (_) {
                  if (_searchResults.isNotEmpty) {
                    _selectVendorFromSearch(_searchResults.first);
                  } else {
                    _searchFocus.unfocus();
                  }
                },
              ),
            ),
            if (_searchFocused)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  _searchFocus.unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _greyLt,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: _grey),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🍚',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Search results dropdown ───────────────────────────────────────────────
  Widget _buildSearchResults() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxHeight: 260),
        child: _searchResults.isEmpty
            ? Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, color: _grey, size: 18),
              const SizedBox(width: 8),
              Text(
                'Aucun vendeur trouvé',
                style: TextStyle(color: _grey, fontSize: 14),
              ),
            ],
          ),
        )
            : ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: true,
          itemCount: _searchResults.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: _greyLt,
            indent: 56,
          ),
          itemBuilder: (_, i) {
            final v = _searchResults[i];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectVendorFromSearch(v),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('🍚',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _dark,
                            ),
                          ),
                          if (v.description.isNotEmpty)
                            Text(
                              v.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: _grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.north_west_rounded,
                        size: 16, color: _grey),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Vendor count chip ─────────────────────────────────────────────────────
  Widget _buildVendorChip() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${_markers.length} vendeurs trouvés',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _dark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB cluster ───────────────────────────────────────────────────────────
  Widget _buildFabCluster() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mute/Unmute voice
        _fab(
          icon: _tts.isMuted
              ? Icons.volume_off_rounded
              : Icons.volume_up_rounded,
          color: _tts.isMuted ? _dark : _white,
          iconColor: _tts.isMuted ? _white : _green,
          onTap: () async {
            await _tts.toggleMute();
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        // My location
        _fab(
          icon: Icons.my_location_rounded,
          color: _white,
          iconColor: _orange,
          onTap: () {
            if (_userLocation != null) {
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(_userLocation!, 15),
              );
            }
          },
        ),
        const SizedBox(height: 10),
        // Refresh
        _fab(
          icon: Icons.refresh_rounded,
          color: _white,
          iconColor: _grey,
          onTap: _loadVendors,
        ),
        // Navigation FAB (animated)
        if (_readyToNavigate) ...[
          const SizedBox(height: 10),
          Transform.scale(
            scale: _pulseAnim.value,
            child: _fab(
              icon: Icons.navigation_rounded,
              color: _orange,
              iconColor: _white,
              size: 56,
              onTap: _startNavigation,
            ),
          ),
        ],
      ],
    );
  }

  Widget _fab({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    double size = 46,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (color == _white ? Colors.black : color)
                  .withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.42),
      ),
    );
  }

  // ── Bottom navigation sheet ───────────────────────────────────────────────
  Widget _buildNavigationSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _sheetAnim,
        child: Container(
          decoration: const BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 30,
                offset: Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _greyLt,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // Vendor info row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                        child: Text('🍚',
                            style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVendor?.name ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.circle,
                                size: 7, color: _green),
                            const SizedBox(width: 5),
                            const Text(
                              'Itinéraire prêt',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _green,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Close
                  GestureDetector(
                    onTap: _dismissSheet,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _greyLt,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: _grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _sheetButton(
                      label: 'Itinéraire',
                      icon: Icons.alt_route_rounded,
                      color: _orange.withOpacity(0.1),
                      textColor: _orange,
                      onTap: () {
                        if (_selectedVendor != null) {
                          _drawRouteTo(_selectedVendor!);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _sheetButton(
                      label: 'Démarrer la navigation',
                      icon: Icons.navigation_rounded,
                      color: _orange,
                      textColor: _white,
                      onTap: _startNavigation,
                      primary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: primary
              ? [
            BoxShadow(
              color: _orange.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gpsStream?.cancel();
    _tts.stop();
    _sheetCtrl.dispose();
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}