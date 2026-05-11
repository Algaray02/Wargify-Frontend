import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/screens/warga/home/home_screen.dart';
import 'package:wargify/screens/warga/iuran/iuran_screen.dart';
import 'package:wargify/screens/warga/gallery/gallery_screen.dart';
import 'package:wargify/widgets/warga/warga_header.dart';
import 'package:wargify/widgets/warga/warga_bottom_nav.dart';
import 'package:wargify/widgets/warga/ronda/ronda_timer_card.dart';
import 'package:wargify/widgets/warga/ronda/ronda_persiapan_card.dart';
import 'package:wargify/widgets/warga/ronda/jadwal_ronda_card.dart';
import 'package:wargify/widgets/warga/ronda/riwayat_ronda_item.dart';
import 'package:wargify/screens/warga/qr/qr_scanner_screen.dart';

class RondaScreen extends StatefulWidget {
  const RondaScreen({super.key});

  @override
  State<RondaScreen> createState() => _RondaScreenState();
}

class _RondaScreenState extends State<RondaScreen> {
  int _currentNavIndex = 4; // ronda = index 4

  // --- State Ronda ---
  bool _sudahScan = false;
  bool _rondaBerjalan = false;
  int _detikBerjalan = 0;
  Timer? _timer;

  // --- Dummy Data ---
  final String _lokasi = 'Sektor C-4 • Blok Perumahan Utama';

  final List<Map<String, dynamic>> _jadwalMendatang = [
    {
      'bulan': 'OKT',
      'tanggal': '24',
      'hariNama': 'Selasa',
      'namaTempat': 'Pos Keamanan A-1',
      'waktu': '22:00 - 06:00',
      'status': 'Mendatang',
      'jumlahAnggota': 5,
    },
  ];

  final List<Map<String, String>> _riwayatRonda = [
    {
      'namaTempat': 'Sektor B-2',
      'shift': 'Malam Minggu',
      'durasi': '08:00:00',
      'tanggal': '21 OKT',
      'status': 'Selesai',
    },
    {
      'namaTempat': 'Pos Utama',
      'shift': 'Shift Malam',
      'durasi': '07:45:00',
      'tanggal': '18 OKT',
      'status': 'Selesai',
    },
  ];

  String get _timerDisplay {
    final jam = _detikBerjalan ~/ 3600;
    final menit = (_detikBerjalan % 3600) ~/ 60;
    final detik = _detikBerjalan % 60;
    return '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
  }

  void _handleScanQr() {
    // TODO: integrasi QR scanner sesungguhnya
    // Simulasi scan berhasil
    setState(() => _sudahScan = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'QR Pos berhasil discan!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleMulaiRonda() {
    setState(() => _rondaBerjalan = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _detikBerjalan++);
    });
  }

  void _handleSelesaiRonda() {
    _timer?.cancel();
    setState(() {
      _rondaBerjalan = false;
      _sudahScan = false;
      _detikBerjalan = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ronda selesai! Terima kasih.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: WargaHeader(
        onNotificationTap: () {
          // TODO: navigate to notifications
        },
      ),
      bottomNavigationBar: WargaBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WargaHomeScreen()),
            );
            return;
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const IuranScreen()),
            );
            return;
          }
          if (index == 2) {
            Navigator.push(
              // ← push bukan pushReplacement
              context,
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            );
            return;
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GalleryScreen()),
            );
            return;
          }
          setState(() => _currentNavIndex = index);
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // --- Timer Card ---
            RondaTimerCard(
              timer: _timerDisplay,
              lokasi: _lokasi,
              isMulai: _rondaBerjalan,
              onLokasiTap: () {
                // TODO: buka maps
              },
            ),
            const SizedBox(height: 16),

            // --- Persiapan Card (hanya tampil kalau belum mulai) ---
            if (!_rondaBerjalan)
              RondaPersiapanCard(
                sudahScan: _sudahScan,
                onScanTap: _handleScanQr,
                onMulaiTap: _handleMulaiRonda,
              ),

            // --- Tombol Selesai Ronda (hanya tampil kalau sedang berjalan) ---
            if (_rondaBerjalan) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _handleSelesaiRonda,
                  icon: const Icon(Icons.stop_circle_outlined, size: 20),
                  label: Text(
                    'SELESAI RONDA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // --- Jadwal Mendatang ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'JADWAL MENDATANG',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: lihat semua jadwal
                  },
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ..._jadwalMendatang.map(
              (jadwal) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: JadwalRondaCard(
                  bulan: jadwal['bulan'] ?? '',
                  tanggal: jadwal['tanggal'] ?? '',
                  hariNama: jadwal['hariNama'] ?? '',
                  namaTempat: jadwal['namaTempat'] ?? '',
                  waktu: jadwal['waktu'] ?? '',
                  status: jadwal['status'] ?? '',
                  jumlahAnggota: jadwal['jumlahAnggota'] ?? 0,
                  onTap: () {
                    // TODO: detail jadwal
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Riwayat Ronda ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RIWAYAT RONDA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: lihat semua riwayat
                  },
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ..._riwayatRonda.map(
              (riwayat) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RiwayatRondaItem(
                  namaTempat: riwayat['namaTempat'] ?? '',
                  shift: riwayat['shift'] ?? '',
                  durasi: riwayat['durasi'] ?? '',
                  tanggal: riwayat['tanggal'] ?? '',
                  status: riwayat['status'] ?? '',
                  onTap: () {
                    // TODO: detail riwayat
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
