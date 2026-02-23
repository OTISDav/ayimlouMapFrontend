import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'map_screen.dart';



class DonationScreen extends StatefulWidget {
  final String vendorName;
  const DonationScreen({required this.vendorName, super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen>
    with TickerProviderStateMixin {


  static const Color _bg      = Color(0xFFF7F3EE);
  static const Color _white   = Color(0xFFFFFFFF);
  static const Color _orange  = Color(0xFFFF5C2A);
  static const Color _green   = Color(0xFF00B87C);
  static const Color _yellow  = Color(0xFFFFCC00);
  static const Color _dark    = Color(0xFF1A1A1A);
  static const Color _grey    = Color(0xFF9A9A9A);
  static const Color _greyLt  = Color(0xFFEEEAE4);

  int? _selectedAmount;
  bool _donated = false;

  final List<int> _amounts = [100, 250, 500, 1000];

  late final AnimationController _enterCtrl;
  late final AnimationController _checkCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _checkScale;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _checkCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _confirmDonation() async {
    if (_selectedAmount == null) return;
    setState(() => _donated = true);
    _checkCtrl.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _goToMap();
  }

  void _goToMap() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => MapScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: _donated ? _buildThanksState() : _buildDonationContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildThanksState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _checkCtrl,
            builder: (_, __) => Transform.scale(
              scale: _checkScale.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _green,
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Merci pour votre soutien !',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre don aide à maintenire ayimolouMap',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _goToMap,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close_rounded, color: _dark, size: 18),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _green,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Arrivé à destination',
                      style: TextStyle(
                        fontSize: 12,
                        color: _green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),


          Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _orange.withOpacity(0.15),
                        _yellow.withOpacity(0.15),
                      ],
                    ),
                    border: Border.all(
                      color: _orange.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text('🤝', style: TextStyle(fontSize: 50)),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),


          const Text(
            'Vous êtes arrivé !',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _dark,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),


          Row(children: [
            Container(width: 40, height: 3,
                decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Container(width: 16, height: 3,
                decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Container(width: 8, height: 3,
                decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(2))),
          ]),

          const SizedBox(height: 16),

          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 15, color: _grey, height: 1.6),
              children: [
                const TextSpan(text: 'Vous venez d\'être guidé jusqu\'à '),
                TextSpan(
                  text: widget.vendorName,
                  style: const TextStyle(
                    color: _dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: '. Souhaitez-vous faire un petit don pour soutenir notre Application !!!!?',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),


          const Text(
            'Choisissez un montant',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _dark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: _amounts.map((amount) {
              final isSelected = _selectedAmount == amount;
              return GestureDetector(
                onTap: () => setState(() => _selectedAmount = amount),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? _orange : _white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _orange : _greyLt,
                      width: isSelected ? 0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? _orange.withOpacity(0.3)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: isSelected ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$amount FCFA',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : _dark,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),


          GestureDetector(
            onTap: _selectedAmount != null ? _confirmDonation : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                gradient: _selectedAmount != null
                    ? const LinearGradient(
                  colors: [_orange, Color(0xFFFF3D00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: _selectedAmount == null ? _greyLt : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedAmount != null
                    ? [
                  BoxShadow(
                    color: _orange.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.volunteer_activism_rounded,
                    color: _selectedAmount != null ? Colors.white : _grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _selectedAmount != null
                        ? 'Faire un don de $_selectedAmount FCFA'
                        : 'Sélectionnez un montant',
                    style: TextStyle(
                      color: _selectedAmount != null ? Colors.white : _grey,
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
            onTap: _goToMap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Non merci, passer',
                  style: TextStyle(
                    color: _grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}