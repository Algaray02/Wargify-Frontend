import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/screens/warga/pages/verifikasi_titik_page.dart';
import 'package:wargify/screens/warga/pages/sos_trigger_page.dart';

/// Model untuk satu titik checkpoint di rute ronda.
class _Checkpoint {
  final String id; // e.g. "P-01"
  final String nama; // e.g. "Pos Utama"
  final double lat;
  final double lng;
  bool sudahVerifikasi = false; // diset via assignment, bukan konstruktor

  _Checkpoint({
    required this.id,
    required this.nama,
    required this.lat,
    required this.lng,
  });
}

/// Halaman Patrol In Progress.
///
/// Dipush dari [RondaScreen] saat user menekan MULAI RONDA.
/// Menerima [initialDetik] agar timer melanjutkan hitungan dari ronda_page.
///
/// Navigasi:
/// - Tombol back / tombol X → pop (timer tetap jalan di ronda_page via callback)
/// - VERIFIKASI TITIK → push [VerifikasiTitikPage]
/// - PANIC BUTTON → push [SosTriggerPage]
/// - Complete → konfirmasi lalu pop dengan result 'complete'
/// - Pause / Resume → pause/resume timer lokal
class PatrolInProgressPage extends StatefulWidget {
  /// Detik awal dari timer ronda_page.
  final int initialDetik;

  /// Callback tiap detik agar ronda_page juga update timernya.
  final void Function(int detik)? onTimerTick;

  /// Callback saat patrol selesai (Complete ditekan).
  final VoidCallback? onComplete;

  const PatrolInProgressPage({
    super.key,
    required this.initialDetik,
    this.onTimerTick,
    this.onComplete,
  });

  @override
  State<PatrolInProgressPage> createState() => _PatrolInProgressPageState();
}

class _PatrolInProgressPageState extends State<PatrolInProgressPage>
    with TickerProviderStateMixin {
  // ── Timer ──────────────────────────────────────────────────────────────
  late int _detik;
  bool _isPaused = false;
  Timer? _timer;

  // ── Lokasi / Tracking ──────────────────────────────────────────────────
  double _distanceMeters = 0.0;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSub;
  bool _gpsActive = false;

  // ── Checkpoint / Sektor ────────────────────────────────────────────────
  /// Dummy checkpoints — nanti diganti data dari API (route yang di-set RT)
  final List<_Checkpoint> _checkpoints = [
    _Checkpoint(id: 'P-01', nama: 'Pos Utama', lat: -6.9147, lng: 107.6098),
    _Checkpoint(id: 'P-02', nama: 'Sektor A-1', lat: -6.9155, lng: 107.6110),
    _Checkpoint(id: 'P-03', nama: 'Sektor B-2', lat: -6.9162, lng: 107.6125),
    _Checkpoint(id: 'P-04', nama: 'Sektor C-4', lat: -6.9170, lng: 107.6140),
    _Checkpoint(
      id: 'P-05',
      nama: 'Pos Keamanan A',
      lat: -6.9180,
      lng: 107.6155,
    ),
  ];

  String _currentSector = 'Belum ada verifikasi';
  int _verifiedCount = 0;

  // ── Trail / path ──────────────────────────────────────────────────────
  final List<Offset> _trailPoints = [];

  // ── Map pulse animation (drives CustomPaint repaint) ──────────────────
  late AnimationController _dotPulse;

  @override
  void initState() {
    super.initState();
    _detik = widget.initialDetik;
    _startTimer();
    _startGps();

    // _dotPulse dipakai sebagai Listenable untuk CustomPaint agar dot
    // user berkedip tanpa perlu setState setiap frame.
    _dotPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSub?.cancel();
    _dotPulse.dispose();
    super.dispose();
  }

  // ── Timer ──────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() => _detik++);
        widget.onTimerTick?.call(_detik);
      }
    });
  }

  String get _timerDisplay {
    final h = _detik ~/ 3600;
    final m = (_detik % 3600) ~/ 60;
    final s = _detik % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── GPS Tracking ───────────────────────────────────────────────────────
  Future<void> _startGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    setState(() => _gpsActive = true);

    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // update tiap 5 meter
          ),
        ).listen((pos) {
          if (!mounted || _isPaused) return;
          if (_lastPosition != null) {
            final d = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              pos.latitude,
              pos.longitude,
            );
            setState(() {
              _distanceMeters += d;
              // tambah titik trail di canvas map (dinormalisasi ke 0-1)
              _trailPoints.add(
                Offset(pos.longitude.toDouble(), pos.latitude.toDouble()),
              );
            });
          }
          _lastPosition = pos;
        });
  }

  String get _distanceDisplay {
    if (_distanceMeters >= 1000) {
      return '${(_distanceMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${_distanceMeters.toStringAsFixed(0)} m';
  }

  // ── Pause / Resume ──────────────────────────────────────────────────────
  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _positionSub?.pause();
    } else {
      _positionSub?.resume();
    }
  }

  // ── Verifikasi Titik ───────────────────────────────────────────────────
  void _handleVerifikasiTitik() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifikasiTitikPage(
          onScanSuccess: (kode) {
            // Cari checkpoint yang dikenal berdasarkan id atau nama
            final int idx = _checkpoints.indexWhere(
              (c) => c.id == kode || c.nama == kode,
            );

            final String sektorNama;
            if (idx != -1) {
              // Checkpoint dikenal → tandai verified
              _checkpoints[idx].sudahVerifikasi = true;
              sektorNama = _checkpoints[idx].nama;
            } else {
              // QR tidak cocok dengan checkpoint manapun — tetap catat nama sektornya
              sektorNama = kode;
            }

            setState(() {
              _currentSector = sektorNama;
              _verifiedCount = _checkpoints
                  .where((c) => c.sudahVerifikasi)
                  .length;
            });
            _showSnackbar(
              '✓ $sektorNama berhasil diverifikasi',
              AppColors.success,
            );
          },
        ),
      ),
    );
  }

  // ── Complete ──────────────────────────────────────────────────────────
  void _handleComplete() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Selesaikan Ronda?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Durasi: $_timerDisplay\nJarak: $_distanceDisplay\nTitik Terverifikasi: $_verifiedCount/${_checkpoints.length}',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // tutup dialog
                        widget.onComplete?.call();
                        Navigator.pop(context); // kembali ke ronda_page
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCFE8EE), // warna dasar peta
      body: Stack(
        children: [
          // ── Background Map ──────────────────────────────────────────────
          // _dotPulse dipakai sebagai repaint listenable agar dot user
          // berkedip animasi tanpa perlu setState setiap frame.
          Positioned.fill(
            child: CustomPaint(
              painter: _MapPainter(
                checkpoints: _checkpoints,
                trailPoints: _trailPoints,
                pulseValue: _dotPulse.value,
                repaint: _dotPulse,
              ),
            ),
          ),

          // ── Konten utama ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ──────────────────────────────────────────────
                _buildTopBar(),

                const Spacer(),

                // ── Info Cards ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        icon: Icons.my_location_rounded,
                        iconColor: AppColors.primary,
                        iconBg: AppColors.secondary,
                        label: 'CURRENT SECTOR',
                        value: _currentSector,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoCard(
                        icon: Icons.route_rounded,
                        iconColor: AppColors.success,
                        iconBg: Color(0xFFD6F5C0),
                        label: 'DISTANCE COVERED',
                        value: _distanceDisplay,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Action Panel ──────────────────────────────────────────
                _buildActionPanel(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Label + GPS status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patrol in Progress',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _gpsActive ? AppColors.success : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _gpsActive ? 'GPS: ACTIVE' : 'GPS: CONNECTING...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _gpsActive ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Timer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _timerDisplay,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ── Info Card ────────────────────────────────────────────────────────────
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Action Panel ─────────────────────────────────────────────────────────
  Widget _buildActionPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Verifikasi Titik
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _handleVerifikasiTitik,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: Text(
                'VERIFIKASI TITIK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Pause + Complete
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _isPaused ? 'Resume' : 'Pause',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D1B2A),
                    side: const BorderSide(
                      color: Color(0xFFDDE3EC),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleComplete,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                  ),
                  label: Text(
                    'Complete',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Panic Button
          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SosTriggerPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_rounded, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'PANIC BUTTON',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'EMERGENCY ASSISTANCE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter: Map ──────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  final List<_Checkpoint> checkpoints;
  final List<Offset> trailPoints;

  /// Nilai 0.0–1.0 dari AnimationController untuk efek pulse dot user.
  final double pulseValue;

  _MapPainter({
    required this.checkpoints,
    required this.trailPoints,
    required this.pulseValue,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Grid (seperti peta topografi) ────────────────────────────────────
    final gridPaint = Paint()
      ..color = const Color(0xFFB8D8E0).withOpacity(0.6)
      ..strokeWidth = 1;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ── Blok jalan / area (dummy street map feel) ─────────────────────
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Jalan horizontal
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.35),
      Offset(size.width * 0.9, size.height * 0.35),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.55),
      Offset(size.width * 0.9, size.height * 0.55),
      roadPaint,
    );
    // Jalan vertikal
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.1),
      Offset(size.width * 0.3, size.height * 0.9),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.1),
      Offset(size.width * 0.7, size.height * 0.9),
      roadPaint,
    );

    // ── Rute ronda (garis putus-putus biru muda) ──────────────────────
    final routePositions = _dummyRoutePositions(size);

    final routePaint = Paint()
      ..color = const Color(0xFF5BB8D4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (routePositions.length > 1) {
      for (int i = 0; i < routePositions.length - 1; i++) {
        _drawDashedLine(
          canvas,
          routePositions[i],
          routePositions[i + 1],
          routePaint,
        );
      }
    }

    // ── Trail GPS pengguna (solid biru tua) ──────────────────────────
    if (trailPoints.length > 1) {
      // Normalisasi ke canvas size
      // Untuk saat ini (dummy) kita pakai routePositions sebagai trail demo
    }

    // ── Titik-titik checkpoint ────────────────────────────────────────
    for (int i = 0; i < routePositions.length; i++) {
      final pos = routePositions[i];
      final cp = i < checkpoints.length ? checkpoints[i] : null;
      final verified = cp?.sudahVerifikasi ?? false;

      // Lingkaran luar
      final outerPaint = Paint()
        ..color = (verified ? AppColors.success : AppColors.primary)
            .withOpacity(0.2);
      canvas.drawCircle(pos, 20, outerPaint);

      // Lingkaran dalam
      final innerPaint = Paint()
        ..color = verified ? AppColors.success : AppColors.primary;
      canvas.drawCircle(pos, 12, innerPaint);

      // Icon check jika verified
      if (verified) {
        final checkPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(pos.dx - 4, pos.dy),
          Offset(pos.dx - 1, pos.dy + 4),
          checkPaint,
        );
        canvas.drawLine(
          Offset(pos.dx - 1, pos.dy + 4),
          Offset(pos.dx + 5, pos.dy - 4),
          checkPaint,
        );
      }

      // Label ID
      if (cp != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: cp.id,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // Label kotak di bawah titik
        final labelBg = Paint()..color = AppColors.primary;
        final labelRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(pos.dx, pos.dy + 26),
            width: tp.width + 12,
            height: 16,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(labelRect, labelBg);
        tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + 18));
      }
    }

    // ── Titik posisi user saat ini (dot berkedip via pulseValue) ─────────
    final userPos = routePositions.isNotEmpty
        ? routePositions.last
        : Offset(size.width * 0.5, size.height * 0.5);

    // Outer ring beranimasi: radius 14–22 berdasarkan pulseValue
    final double outerRadius = 14.0 + (pulseValue * 8.0);
    final userOuterPaint = Paint()
      ..color = const Color(0xFF5BB8D4).withOpacity(0.15 + pulseValue * 0.2);
    canvas.drawCircle(userPos, outerRadius, userOuterPaint);

    final userPaint = Paint()..color = const Color(0xFF1E6FA8);
    canvas.drawCircle(userPos, 9, userPaint);

    final userCorePaint = Paint()..color = Colors.white;
    canvas.drawCircle(userPos, 4, userCorePaint);
  }

  /// Posisi dummy rute di canvas
  List<Offset> _dummyRoutePositions(Size size) {
    return [
      Offset(size.width * 0.25, size.height * 0.20),
      Offset(size.width * 0.70, size.height * 0.20),
      Offset(size.width * 0.70, size.height * 0.45),
      Offset(size.width * 0.45, size.height * 0.45),
      Offset(size.width * 0.45, size.height * 0.25),
    ];
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLen = 8.0;
    const gapLen = 6.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final totalLen = math.sqrt(dx * dx + dy * dy);
    final nx = dx / totalLen;
    final ny = dy / totalLen;

    double traveled = 0;
    while (traveled < totalLen) {
      final start = Offset(p1.dx + nx * traveled, p1.dy + ny * traveled);
      final end = Offset(
        p1.dx + nx * math.min(traveled + dashLen, totalLen),
        p1.dy + ny * math.min(traveled + dashLen, totalLen),
      );
      canvas.drawLine(start, end, paint);
      traveled += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.trailPoints != trailPoints ||
      old.checkpoints != checkpoints ||
      old.pulseValue != pulseValue;
}
