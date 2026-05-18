import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/widgets/common/sos_card.dart';
import 'package:wargify/widgets/common/lapor_fasilitas_card.dart';
import 'package:wargify/widgets/warga/warga_header.dart';
import 'package:wargify/widgets/warga/warga_bottom_nav.dart';
import 'package:wargify/screens/warga/iuran/iuran_screen.dart';
import 'package:wargify/screens/warga/gallery/gallery_screen.dart';
import 'package:wargify/screens/warga/ronda/ronda_screen.dart';
import 'package:wargify/screens/warga/qr/qr_scanner_screen.dart';
import 'package:wargify/models/user_model.dart';
import 'package:wargify/services/auth/auth_service.dart';
import 'package:wargify/screens/profile/profile_screen.dart';

class WargaHomeScreen extends StatefulWidget {
  final UserModel? user;
  const WargaHomeScreen({super.key, this.user});

  @override
  State<WargaHomeScreen> createState() => _WargaHomeScreenState();
}

class _WargaHomeScreenState extends State<WargaHomeScreen> {
  int _currentNavIndex = 0;
  UserModel? _user;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    if (_user == null) {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    final u = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = u;
      });
    }
  }

  // --- Dynamic Getters ---
  String get _namaWarga => _user?.fullName ?? 'Budi Santoso';
  String get _roleWarga => _user != null ? _user!.role.toUpperCase().replaceAll('_', ' ') : 'Kepala Keluarga';
  final String _rtRw = 'RT 004 / RW 012';
  final bool _isVerified = true;

  final String _iuranBulan = 'September 2023';
  final String _statusIuran = 'LUNAS';
  final String _totalTagihan = 'Rp 0';

  final List<Map<String, String>> _kegiatanTerbaru = [
    {
      'kategori': 'LINGKUNGAN',
      'judul': 'Minggu Bersih: Kerja Bakti Massal RT 04',
      'imageUrl':
          'https://i.pinimg.com/564x/6e/0f/05/6e0f057d6d82cb6a1f1054c2b3504f92.jpg',
      'color': 'green',
    },
    {
      'kategori': 'KEAMANAN',
      'judul': 'Penambahan Siskamling',
      'imageUrl':
          'https://froyonion.sgp1.cdn.digitaloceanspaces.com/images/blogdetail/858eb1bd32c0fc50cba8ba93e472de88e7082914.jpg',
      'color': 'blue',
    },
  ];

  final List<Map<String, String>> _upcomingEvents = [
    {
      'type': 'rapat',
      'label': 'Rapat Mendatang',
      'sublabel': 'Pengingat',
      'countdown': '2 Days',
      'countdownPrefix': 'MULAI DALAM',
      'tanggal': '28',
      'bulan': 'SEP',
      'judul': 'Pembahasan Anggaran RT 2024',
      'waktu': '19:30 - Selesai',
      'tempat': 'Balai Warga',
    },
    {
      'type': 'ronda',
      'label': 'Shift Ronda',
      'sublabel': 'Giliran anda untuk\nmenjaga keamanan\ndesa',
      'countdown': 'Minggu\nDepan',
      'countdownPrefix': 'TUGAS MENDATANG',
      'tanggal': '24',
      'bulan': 'OKT',
      'judul': 'Malam Rabu',
      'waktu': '22:00 - 02:00',
      'tempat': 'Post Ronda RT 04',
    },
    {
      'type': 'kegiatan',
      'label': 'Kegiatan Mendatang',
      'sublabel': 'Pengingat',
      'countdown': '2 Days',
      'countdownPrefix': 'MULAI DALAM',
      'tanggal': '28',
      'bulan': 'SEP',
      'judul': 'Kerja Bakti',
      'waktu': '06:00 - Selesai',
      'tempat': 'Sekitar Sungai',
    },
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  Color _getCategoryColor(String color) {
    switch (color) {
      case 'green':
        return AppColors.success;
      case 'red':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'ronda':
        return Icons.shield_outlined;
      case 'rapat':
        return Icons.people_outline;
      default:
        return Icons.people_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: WargaHeader(
        onProfileTap: () {
          if (_user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(user: _user!),
              ),
            );
          }
        },
        onNotificationTap: () {
          // TODO: navigate to notifications
        },
      ),
      bottomNavigationBar: WargaBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
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
          if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RondaScreen()),
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

            // --- Role Label ---
            Text(
              _roleWarga.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),

            // --- Greeting ---
            RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                children: [
                  TextSpan(text: '${_getGreeting()} '),
                  TextSpan(
                    text: _namaWarga,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // --- RT/RW & Verified Badge ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _rtRw,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4EDDA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Terverifikasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Iuran Card ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'IURAN BULAN INI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusIuran,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _iuranBulan,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Tagihan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _totalTagihan,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: navigate to kwitansi
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Lihat Kwitansi',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- SOS Card ---
            SosCard(onTap: () {}),
            const SizedBox(height: 12),

            // --- Lapor Fasilitas ---
            LaporFasilitasCard(onTap: () {}),
            const SizedBox(height: 24),

            // --- Kegiatan Terbaru ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kegiatan Terbaru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
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
            const SizedBox(height: 12),

            // --- Horizontal Scroll Kegiatan Cards ---
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _kegiatanTerbaru.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = _kegiatanTerbaru[index];
                  return _KegiatanCard(
                    kategori: item['kategori'] ?? '',
                    judul: item['judul'] ?? '',
                    categoryColor: _getCategoryColor(item['color'] ?? ''),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- Upcoming Events ---
            ..._upcomingEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _UpcomingEventCard(
                  event: event,
                  icon: _getEventIcon(event['type'] ?? ''),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Kegiatan Card ───────────────────────────────────────────────────────────

class _KegiatanCard extends StatelessWidget {
  final String kategori;
  final String judul;
  final Color categoryColor;

  const _KegiatanCard({
    required this.kategori,
    required this.judul,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: double.infinity,
              color: categoryColor.withOpacity(0.15),
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: categoryColor.withOpacity(0.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      kategori,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    judul,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Upcoming Event Card ─────────────────────────────────────────────────────

class _UpcomingEventCard extends StatelessWidget {
  final Map<String, String> event;
  final IconData icon;

  const _UpcomingEventCard({required this.event, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['label'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        event['sublabel'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    event['countdownPrefix'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    event['countdown'] ?? '',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.background),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      event['bulan'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      event['tanggal'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['judul'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event['waktu'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.circle,
                          size: 4,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event['tempat'] ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Selengkapnya',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
