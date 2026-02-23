import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vendor.dart';



class VendorDetailScreen extends StatefulWidget {
  final Vendor vendor;
  const VendorDetailScreen({required this.vendor, super.key});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen>
    with SingleTickerProviderStateMixin {

  static const Color _bg      = Color(0xFFF7F3EE);
  static const Color _white   = Color(0xFFFFFFFF);
  static const Color _orange  = Color(0xFFFF5C2A);
  static const Color _green   = Color(0xFF00B87C);
  static const Color _yellow  = Color(0xFFFFCC00);
  static const Color _dark    = Color(0xFF1A1A1A);
  static const Color _grey    = Color(0xFF9A9A9A);
  static const Color _greyLt  = Color(0xFFEEEAE4);

  bool _isFavorite = false;

  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildDescription(),
                      const SizedBox(height: 24),
                      _buildInfoChips(),
                      const SizedBox(height: 32),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    final hasPhoto =
        widget.vendor.photo != null && widget.vendor.photo!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: hasPhoto ? 300.0 : 160.0,
      pinned: true,
      stretch: true,
      backgroundColor: _white,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _dark, size: 17),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => setState(() => _isFavorite = !_isFavorite),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _isFavorite
                  ? _orange.withOpacity(0.12)
                  : Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavorite ? _orange : _grey,
              size: 20,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: hasPhoto
            ? Stack(fit: StackFit.expand, children: [
          Image.network(
            widget.vendor.photo!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _photoPlaceholder(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _bg.withOpacity(0.7),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ])
            : _buildNoPhotoHeader(),
      ),
    );
  }

  Widget _buildNoPhotoHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _orange.withOpacity(0.12),
            _green.withOpacity(0.08),
            _bg,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _white,
            boxShadow: [
              BoxShadow(
                color: _orange.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(color: _orange.withOpacity(0.2), width: 1.5),
          ),
          child: const Center(
            child: Text('🍚', style: TextStyle(fontSize: 36)),
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: _greyLt,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, size: 56, color: _grey),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.vendor.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _dark,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
        ),
        // const SizedBox(width: 12),
        // // Rating badge
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        //   decoration: BoxDecoration(
        //     color: _yellow.withOpacity(0.15),
        //     borderRadius: BorderRadius.circular(20),
        //     border: Border.all(color: _yellow.withOpacity(0.5)),
        //   ),
        //   child: const Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(Icons.star_rounded, color: _yellow, size: 14),
        //       SizedBox(width: 4),
        //       Text('4.8',
        //           style: TextStyle(
        //             color: _dark,
        //             fontSize: 13,
        //             fontWeight: FontWeight.w700,
        //           )),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Container(
          width: 40, height: 3,
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 16, height: 3,
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 8, height: 3,
          decoration: BoxDecoration(
            color: _yellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        widget.vendor.description.isNotEmpty
            ? widget.vendor.description
            : 'Aucune description disponible.',
        style: TextStyle(
          fontSize: 15,
          color: _grey,
          height: 1.65,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildInfoChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(Icons.location_on_rounded, 'Lomé, Togo', _orange),
        _chip(Icons.access_time_rounded, 'Ouvert maintenant', _green),
        _chip(Icons.directions_walk_rounded, '320 m', _dark),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _greyLt),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.1),
            ),
            child: Icon(icon, color: accentColor, size: 13),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _dark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildActions() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(
              context, {'action': 'start', 'vendor': widget.vendor}),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_orange, Color(0xFFFF3D00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _orange.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Démarrer la navigation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => Navigator.pop(
              context, {'action': 'route', 'vendor': widget.vendor}),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _greyLt, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.alt_route_rounded, color: _orange, size: 20),
                const SizedBox(width: 10),
                const Text(
                  "Voir l'itinéraire",
                  style: TextStyle(
                    color: _dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}