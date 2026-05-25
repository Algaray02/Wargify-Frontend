import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/widgets/common/sos_detail_dialog.dart';

class SosTriggerPage extends StatefulWidget {
  const SosTriggerPage({super.key});

  @override
  State<SosTriggerPage> createState() => _SosTriggerPageState();
}

class _SosTriggerPageState extends State<SosTriggerPage>
    with SingleTickerProviderStateMixin {
  // --- Hold state ---
  bool _isHolding = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  static const int _holdDurationSeconds = 3;

  // --- Lokasi state ---
  String _latitude = '-';
  String _longitude = '-';
  String _alamat = 'Mendeteksi lokasi...';
  bool _isLoadingLokasi = true;

  // --- Animation ---
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _detectLokasi();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Deteksi Lokasi Otomatis ───────────────────────────────────────────────
  Future<void> _detectLokasi() async {
    setState(() => _isLoadingLokasi = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _alamat = 'Layanan lokasi tidak aktif';
          _isLoadingLokasi = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _alamat = 'Izin lokasi ditolak';
            _isLoadingLokasi = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _alamat = 'Izin lokasi diblokir';
          _isLoadingLokasi = false;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final Placemark place = placemarks.first;
        setState(() {
          _latitude = '${position.latitude.toStringAsFixed(4)}° S';
          _longitude = '${position.longitude.toStringAsFixed(4)}° E';
          _alamat =
              '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}'
                  .trim()
                  .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
          _isLoadingLokasi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _alamat = 'Gagal mendeteksi lokasi';
          _isLoadingLokasi = false;
        });
      }
    }
  }

  // ── Hold Logic ────────────────────────────────────────────────────────────
  void _onHoldStart(dynamic details) {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });

    const interval = Duration(milliseconds: 50);
    final totalTicks = (_holdDurationSeconds * 1000) / interval.inMilliseconds;
    int ticks = 0;

    _holdTimer = Timer.periodic(interval, (timer) {
      ticks++;
      setState(() => _holdProgress = ticks / totalTicks);

      if (ticks >= totalTicks) {
        timer.cancel();
        _onHoldComplete();
      }
    });
  }

  void _onHoldEnd(dynamic details) {
    if (_holdProgress < 1.0) {
      _holdTimer?.cancel();
      setState(() {
        _isHolding = false;
        _holdProgress = 0.0;
      });
    }
  }

  void _onHoldComplete() {
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
    _showDetailDialog();
  }

  // ── Dialog Detail ─────────────────────────────────────────────────────────
  void _showDetailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SosDetailDialog(
        onBatal: () => Navigator.pop(context),
        onKirim: (keterangan) {
          Navigator.pop(context); // tutup dialog
          _showSosSuccess(keterangan);
        },
      ),
    );
  }

  void _showSosSuccess(String keterangan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.danger,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SOS Terkirim!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SOS-mu telah terkirim ke semua warga',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"$keterangan"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // tutup success dialog
                    Navigator.pop(context); // kembali ke home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Kembali ke Home',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ── Header Badge ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              color: AppColors.danger,
                              size: 10,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SISTEM EMERGENCY',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Situasi yang Butuh\nPenanganan Segera',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Menekan tombol di bawah akan memberi peringatan kepada warga sekitar kalau ada situasi gawat di lokasi anda',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ── SOS Hold Button ──
                      GestureDetector(
                        onLongPressStart: _onHoldStart,
                        onLongPressEnd: _onHoldEnd,
                        child: ScaleTransition(
                          scale: _isHolding
                              ? AlwaysStoppedAnimation(1.0)
                              : _pulseAnimation,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Progress ring
                              SizedBox(
                                width: 270,
                                height: 270,
                                child: CircularProgressIndicator(
                                  value: _holdProgress,
                                  strokeWidth: 5,
                                  backgroundColor: AppColors.danger.withOpacity(
                                    0.15,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.danger,
                                      ),
                                ),
                              ),
                              // Button body
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.danger.withOpacity(
                                        _isHolding ? 0.5 : 0.3,
                                      ),
                                      blurRadius: _isHolding ? 40 : 20,
                                      spreadRadius: _isHolding ? 10 : 4,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.wifi_tethering_rounded,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _isHolding
                                          ? 'TAHAN ${((_holdDurationSeconds * 1000) * (1 - _holdProgress) / 1000).ceil()}...'
                                          : 'HOLD TO TRIGGER SOS',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ── Lokasi Card ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lokasi saat ini',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D1B2A),
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: _detectLokasi,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isLoadingLokasi
                                          ? Colors.grey[200]
                                          : Colors.green[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _isLoadingLokasi
                                          ? 'DETECTING...'
                                          : 'LOCKED',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _isLoadingLokasi
                                            ? Colors.grey[600]
                                            : Colors.green[800],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Lat & Long
                            Row(
                              children: [
                                Expanded(
                                  child: _buildLocationField(
                                    'LATITUDE',
                                    _latitude,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildLocationField(
                                    'LONGITUDE',
                                    _longitude,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Alamat
                            Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: _isLoadingLokasi
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.map_outlined,
                                          color: AppColors.primary,
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _alamat,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0D1B2A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // ── Batalkan ──
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'BATALKAN',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
