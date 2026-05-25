import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/screens/warga/pages/home_page.dart';
import 'package:wargify/screens/warga/pages/iuran_page.dart';
import 'package:wargify/screens/warga/pages/gallery_page.dart';
import 'package:wargify/screens/warga/pages/patrol_in_progress_page.dart';
import 'package:wargify/screens/warga/pages/qr_scanner_page.dart';
import 'package:wargify/widgets/warga/warga_header.dart';
import 'package:wargify/widgets/warga/warga_bottom_nav.dart';
import 'package:wargify/widgets/warga/ronda/ronda_timer_card.dart';
import 'package:wargify/widgets/warga/ronda/ronda_persiapan_card.dart';
import 'package:wargify/widgets/warga/ronda/jadwal_ronda_card.dart';
import 'package:wargify/widgets/warga/ronda/riwayat_ronda_item.dart';

// ─── Data dummy per bulan ──────────────────────────────────────────────────

/// Jadwal dummy — hanya Oktober 2024 yang terisi, bulan lain kosong.
const Map<String, List<Map<String, String>>> _jadwalPerBulan = {
  'September 2024': [],
  'Oktober 2024': [
    {
      'hariSingkat': 'KAM',
      'tanggal': '03',
      'nama': 'Patroli Utama',
      'waktu': '22:00 - 02:00',
      'lokasi': 'Pos kamling',
    },
    {
      'hariSingkat': 'SAB',
      'tanggal': '12',
      'nama': 'Patroli Keliling',
      'waktu': '22:00 - 02:00',
      'lokasi': 'Pos kamling',
    },
    {
      'hariSingkat': 'KAM',
      'tanggal': '17',
      'nama': 'Patroli Utama',
      'waktu': '22:00 - 02:00',
      'lokasi': 'Pos kamling',
    },
    {
      'hariSingkat': 'SEL',
      'tanggal': '22',
      'nama': 'Patroli Keliling',
      'waktu': '22:00 - 02:00',
      'lokasi': 'Pos kamling',
    },
  ],
  'November 2024': [],
};

/// Riwayat dummy — hanya Oktober 2024 yang terisi.
const Map<String, List<Map<String, String>>> _riwayatPerBulan = {
  'September 2024': [],
  'Oktober 2024': [
    {
      'hariSingkat': 'SAB',
      'tanggal': '21',
      'nama': 'Sektor B-2 Patroli',
      'waktu': '22:00 - 06:00',
      'durasi': '08:00:00',
      'lokasi': 'Pos kamling Sektor B-2',
    },
    {
      'hariSingkat': 'JUM',
      'tanggal': '20',
      'nama': 'Pos Utama Shift Malam',
      'waktu': '21:00 - 05:00',
      'durasi': '08:00:00',
      'lokasi': 'Gerbang Utama',
    },
    {
      'hariSingkat': 'KAM',
      'tanggal': '19',
      'nama': 'Patroli Keliling Sektor A',
      'waktu': '22:00 - 02:00',
      'durasi': '04:00:00',
      'lokasi': 'Pos Satpam Sektor A',
    },
  ],
  'November 2024': [],
};

/// Urutan bulan sebagai list (untuk navigasi prev/next)
const List<String> _daftarBulan = [
  'September 2024',
  'Oktober 2024',
  'November 2024',
];

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET: Jadwal Ronda
// ─────────────────────────────────────────────────────────────────────────────

void showJadwalBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _JadwalBottomSheet(),
  );
}

class _JadwalBottomSheet extends StatefulWidget {
  const _JadwalBottomSheet();

  @override
  State<_JadwalBottomSheet> createState() => _JadwalBottomSheetState();
}

class _JadwalBottomSheetState extends State<_JadwalBottomSheet> {
  int _bulanIndex = 1; // Oktober 2024 = index 1

  void _prevBulan() {
    if (_bulanIndex > 0) setState(() => _bulanIndex--);
  }

  void _nextBulan() {
    if (_bulanIndex < _daftarBulan.length - 1) setState(() => _bulanIndex++);
  }

  @override
  Widget build(BuildContext context) {
    final bulanLabel = _daftarBulan[_bulanIndex];
    final jadwal = _jadwalPerBulan[bulanLabel] ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jadwal Ronda Saya',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Navigasi bulan
          _BulanNavigator(
            label: bulanLabel.toUpperCase(),
            canPrev: _bulanIndex > 0,
            canNext: _bulanIndex < _daftarBulan.length - 1,
            onPrev: _prevBulan,
            onNext: _nextBulan,
          ),
          const SizedBox(height: 16),

          // Konten
          if (jadwal.isEmpty)
            _EmptyState(pesan: 'Tidak ada jadwal di $bulanLabel')
          else
            ...jadwal.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _JadwalItem(
                  hariSingkat: item['hariSingkat'] ?? '',
                  tanggal: item['tanggal'] ?? '',
                  nama: item['nama'] ?? '',
                  waktu: item['waktu'] ?? '',
                  lokasi: item['lokasi'] ?? '',
                ),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET: Riwayat Ronda
// ─────────────────────────────────────────────────────────────────────────────

void showRiwayatBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RiwayatBottomSheet(),
  );
}

class _RiwayatBottomSheet extends StatefulWidget {
  const _RiwayatBottomSheet();

  @override
  State<_RiwayatBottomSheet> createState() => _RiwayatBottomSheetState();
}

class _RiwayatBottomSheetState extends State<_RiwayatBottomSheet> {
  int _bulanIndex = 1; // Oktober 2024

  void _prevBulan() {
    if (_bulanIndex > 0) setState(() => _bulanIndex--);
  }

  void _nextBulan() {
    if (_bulanIndex < _daftarBulan.length - 1) setState(() => _bulanIndex++);
  }

  @override
  Widget build(BuildContext context) {
    final bulanLabel = _daftarBulan[_bulanIndex];
    final riwayat = _riwayatPerBulan[bulanLabel] ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RIWAYAT RONDA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Navigasi bulan
          _BulanNavigator(
            label: bulanLabel.toUpperCase(),
            canPrev: _bulanIndex > 0,
            canNext: _bulanIndex < _daftarBulan.length - 1,
            onPrev: _prevBulan,
            onNext: _nextBulan,
          ),
          const SizedBox(height: 16),

          // Konten
          if (riwayat.isEmpty)
            _EmptyState(pesan: 'Tidak ada riwayat di $bulanLabel')
          else
            ...riwayat.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RiwayatItem(
                  hariSingkat: item['hariSingkat'] ?? '',
                  tanggal: item['tanggal'] ?? '',
                  nama: item['nama'] ?? '',
                  waktu: item['waktu'] ?? '',
                  durasi: item['durasi'] ?? '',
                  lokasi: item['lokasi'] ?? '',
                ),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Navigasi bulan — kiri/kanan dengan tombol dinonaktifkan di ujung.
class _BulanNavigator extends StatelessWidget {
  final String label;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _BulanNavigator({
    required this.label,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: canPrev ? onPrev : null,
            icon: Icon(
              Icons.chevron_left,
              color: canPrev ? AppColors.primary : Colors.grey.shade400,
            ),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: canNext ? onNext : null,
            icon: Icon(
              Icons.chevron_right,
              color: canNext ? AppColors.primary : Colors.grey.shade400,
            ),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Item jadwal mendatang — sesuai desain gambar 2.
class _JadwalItem extends StatelessWidget {
  final String hariSingkat;
  final String tanggal;
  final String nama;
  final String waktu;
  final String lokasi;

  const _JadwalItem({
    required this.hariSingkat,
    required this.tanggal,
    required this.nama,
    required this.waktu,
    required this.lokasi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          // Tanggal bubble
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  hariSingkat,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  tanggal,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      waktu,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      lokasi,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Item riwayat ronda — sesuai desain gambar 3.
class _RiwayatItem extends StatelessWidget {
  final String hariSingkat;
  final String tanggal;
  final String nama;
  final String waktu;
  final String durasi;
  final String lokasi;

  const _RiwayatItem({
    required this.hariSingkat,
    required this.tanggal,
    required this.nama,
    required this.waktu,
    required this.durasi,
    required this.lokasi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanggal bubble
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  hariSingkat,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  tanggal,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      waktu,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Status selesai + durasi
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF2A6B2C)),
                    const SizedBox(width: 4),
                    Text(
                      'Selesai',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      ' ($durasi)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lokasi,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tampilan kosong jika tidak ada data di bulan tersebut.
class _EmptyState extends StatelessWidget {
  final String pesan;
  const _EmptyState({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              pesan,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RONDA SCREEN (tidak berubah dari versi asli kecuali bagian "Lihat Semua")
// ─────────────────────────────────────────────────────────────────────────────

class RondaScreen extends StatefulWidget {
  const RondaScreen({super.key});

  @override
  State<RondaScreen> createState() => _RondaScreenState();
}

class _RondaScreenState extends State<RondaScreen> {
  int _currentNavIndex = 4;

  bool _sudahScan = false;
  bool _rondaBerjalan = false;
  bool _rondaSelesai = false;
  int _detikBerjalan = 0;
  Timer? _timer;

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
    return '${jam.toString().padLeft(2, '0')}:'
        '${menit.toString().padLeft(2, '0')}:'
        '${detik.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _detikBerjalan++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetRonda() {
    _stopTimer();
    setState(() {
      _rondaBerjalan = false;
      _rondaSelesai = false;
      _sudahScan = false;
      _detikBerjalan = 0;
    });
  }

  void _handleScanQr() {
    // TODO: integrasi QR scanner sesungguhnya ke pos ronda
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
    _startTimer();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatrolInProgressPage(
          initialDetik: _detikBerjalan,
          onTimerTick: (_) {},
          onComplete: () {
            _stopTimer();
            if (mounted) {
              setState(() {
                _rondaSelesai = true;
                _rondaBerjalan = false;
              });
              _showRondaSelesaiSnackbar();
            }
          },
        ),
      ),
    ).then((_) {
      if (mounted && !_rondaSelesai) {
        if (_timer == null || !(_timer!.isActive)) {
          _startTimer();
        }
      }
    });
  }

  void _showRondaSelesaiSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ronda selesai! Terima kasih, $_timerDisplay tercatat.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleSelesaiRonda() {
    _resetRonda();
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

            // ── Timer Card ─────────────────────────────────────────────
            RondaTimerCard(
              timer: _timerDisplay,
              lokasi: _lokasi,
              isMulai: _rondaBerjalan,
              onLokasiTap: () {
                if (_rondaBerjalan) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatrolInProgressPage(
                        initialDetik: _detikBerjalan,
                        onTimerTick: (_) {},
                        onComplete: () {
                          _stopTimer();
                          if (mounted) {
                            setState(() {
                              _rondaSelesai = true;
                              _rondaBerjalan = false;
                            });
                            _showRondaSelesaiSnackbar();
                          }
                        },
                      ),
                    ),
                  );
                }
                // TODO: buka maps jika belum mulai ronda
              },
            ),
            const SizedBox(height: 16),

            // ── Persiapan Card ─────────────────────────────────────────
            if (!_rondaBerjalan && !_rondaSelesai)
              RondaPersiapanCard(
                sudahScan: _sudahScan,
                onScanTap: _handleScanQr,
                onMulaiTap: _handleMulaiRonda,
              ),

            // ── Tombol saat ronda berjalan ─────────────────────────────
            if (_rondaBerjalan) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _handleMulaiRonda,
                  icon: const Icon(Icons.map_outlined, size: 20),
                  label: Text(
                    'LANJUT KE PATROL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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

            // ── Ronda selesai ──────────────────────────────────────────
            if (_rondaSelesai) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ronda Selesai!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Durasi: $_timerDisplay',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resetRonda,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.success),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Mulai Ronda Baru',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Jadwal Mendatang ───────────────────────────────────────
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
                // ↓ DIUBAH: memanggil showJadwalBottomSheet
                GestureDetector(
                  onTap: () => showJadwalBottomSheet(context),
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

            // ── Riwayat Ronda ──────────────────────────────────────────
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
                // ↓ DIUBAH: memanggil showRiwayatBottomSheet
                GestureDetector(
                  onTap: () => showRiwayatBottomSheet(context),
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