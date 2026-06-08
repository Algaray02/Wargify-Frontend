import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/models/user_model.dart';
import 'package:wargify/screens/warga/gallery/gallery_screen.dart';
import 'package:wargify/screens/warga/kegiatan/kegiatan_detail_screen.dart';
import 'package:wargify/screens/warga/laporan/laporan_fasilitas_screen.dart';
import 'package:wargify/screens/warga/sos/sos_screen.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/widgets/common/lapor_fasilitas_card.dart';
import 'package:wargify/widgets/common/sos_card.dart';

class WargaHomePage extends StatefulWidget {
  final UserModel user;
  const WargaHomePage({super.key, required this.user});

  @override
  State<WargaHomePage> createState() => _WargaHomePageState();
}

class _WargaHomePageState extends State<WargaHomePage> {
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  static const _bulanIndo = [
    '', 'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
    'JUL', 'AGT', 'SEP', 'OKT', 'NOV', 'DES',
  ];

  // --- Dari GET /me ---
  String _rtRw = 'Memuat...';

  // --- Dari GET /me/iuran ---
  String _iuranBulan = 'Memuat...';
  String _statusIuran = '-';
  String _totalTagihan = 'Rp 0';

  // --- Dari GET /activities ---
  List<Map<String, dynamic>> _upcomingEvents = [];

  // --- Dari GET /galleries ---
  List<Map<String, dynamic>> _galleryAlbums = [];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  Future<void> _fetchDashboardData() async {
    try {
      final meResult = _apiService.getMap(ApiEndpoints.me);
      final iuranResult = _apiService.getList(ApiEndpoints.myIuran);
      final activitiesResult = _apiService.getList(ApiEndpoints.activities);
      final galleryResult = _apiService.getList(ApiEndpoints.galleries);

      final results = await Future.wait([meResult, iuranResult, activitiesResult, galleryResult]);

      final profile = results[0] is Map<String, dynamic>
          ? results[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final iuranRaw = results[1];
      final activityRaw = results[2];
      final galleryRaw = results[3];

      final iuranRows = iuranRaw is List
          ? iuranRaw.whereType<Map>().toList()
          : <Map>[];
      final activityRows = activityRaw is List
          ? activityRaw.whereType<Map>().toList()
          : <Map>[];

      if (!mounted) return;
      setState(() {
        // ── RT/RW dari profile ──
        final family = profile['family'];
        final household = family is Map ? family['household'] : null;
        if (household is Map) {
          final block = household['block_number']?.toString() ?? '';
          final number = household['house_number']?.toString() ?? '';
          _rtRw = [if (block.isNotEmpty) 'Blok $block', if (number.isNotEmpty) 'No. $number'].join(' / ');
        } else {
          _rtRw = 'Alamat belum lengkap';
        }

        // ── Iuran ──
        if (iuranRows.isNotEmpty) {
          final latest = Map<String, dynamic>.from(iuranRows.first);
          final period = latest['period'] is Map
              ? Map<String, dynamic>.from(latest['period'] as Map)
              : <String, dynamic>{};
          _iuranBulan = period['period_name']?.toString() ?? 'Iuran Terbaru';
          _statusIuran = latest['status']?.toString() == 'paid'
              ? 'LUNAS'
              : 'BELUM LUNAS';
          _totalTagihan = _formatCurrency(latest['amount_paid']);
        } else {
          _iuranBulan = 'Belum ada riwayat';
          _statusIuran = 'BELUM LUNAS';
          _totalTagihan = 'Rp 0';
        }

        // ── Upcoming Events ──
        final now = DateTime.now();
        final upcoming = <Map<String, dynamic>>[];

        for (final act in activityRows.map((e) => Map<String, dynamic>.from(e))) {
          final status = act['status']?.toString() ?? '';
          final dateStr = act['activity_date']?.toString();
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

          if (status == 'ANNOUNCED' && date != null && !date.isBefore(DateTime(now.year, now.month, now.day))) {
            upcoming.add(act);
          }
        }

        upcoming.sort((a, b) {
          final aDate = DateTime.tryParse(a['activity_date'] ?? '');
          final bDate = DateTime.tryParse(b['activity_date'] ?? '');
          return (aDate ?? now).compareTo(bDate ?? now);
        });

        _upcomingEvents = upcoming;

        // ── Galeri ──
        _galleryAlbums = galleryRaw is List
            ? galleryRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _rtRw = 'Tidak tersedia';
          _iuranBulan = 'Gagal memuat';
        });
      }
    }
  }

  String _formatCurrency(dynamic value) {
    final amount = value is num
        ? value.round()
        : (double.tryParse(value?.toString() ?? '') ?? 0).round();
    final number = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $number';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // --- Role Label ---
            Text(
              widget.user.role.toUpperCase(),
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
                    text: widget.user.fullName.trim().split(' ')[0],
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // --- RT/RW ---
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
                mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),

            // --- Iuran Card ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
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
                          color: _statusIuran == 'LUNAS' ? AppColors.success : AppColors.danger,
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
                              color: _statusIuran == 'LUNAS' ? AppColors.textPrimary : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- SOS Card ---
            SosCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WargaSosScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // --- Lapor Fasilitas ---
            LaporFasilitasCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LaporanFasilitasScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // --- Preview Foto Kegiatan ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preview Foto Kegiatan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: AppColors.background,
                        appBar: AppBar(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          ),
                          title: Text(
                            'Galeri',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        body: const GalleryScreen(),
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'Lihat Semua',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- Horizontal Scroll Galeri Cards ---
            if (_galleryAlbums.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Belum ada galeri',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _galleryAlbums.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final album = _galleryAlbums[index];
                    final images = album['images'] is List ? album['images'] as List : <dynamic>[];
                    final firstImage = images.isNotEmpty
                        ? (images.first is Map ? (images.first as Map)['image_url']?.toString() : null)
                        : null;
                    return _KegiatanCard(
                      kategori: album['album_name']?.toString() ?? 'Album',
                      judul: album['activity'] is Map
                          ? (album['activity'] as Map)['title']?.toString() ?? ''
                          : '',
                      imageUrl: firstImage,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                        backgroundColor: AppColors.background,
                        appBar: AppBar(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          ),
                          title: Text(
                            'Galeri',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        body: const GalleryScreen(),
                      ),
                        ),
                      ),
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
                  onSelengkapnya: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KegiatanDetailScreen(
                        activity: event,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_upcomingEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Tidak ada kegiatan mendatang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
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
  final String? imageUrl;
  final VoidCallback? onTap;

  const _KegiatanCard({
    required this.kategori,
    required this.judul,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Ink(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withOpacity(0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: imageUrl != null ? null : AppColors.secondary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Icon(
                      Icons.event_note_outlined,
                      size: 40,
                      color: AppColors.primary.withOpacity(0.5),
                    )
                  : null,
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
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      kategori,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
  final Map<String, dynamic> event;
  final VoidCallback? onSelengkapnya;

  const _UpcomingEventCard({
    required this.event,
    this.onSelengkapnya,
  });

  @override
  Widget build(BuildContext context) {
    final type = event['type']?.toString() ?? '';
    final title = event['title']?.toString() ?? 'Kegiatan';
    final location = event['location_name']?.toString() ?? '';
    final dateStr = event['activity_date']?.toString();
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    final bulan = date != null ? _WargaHomePageState._bulanIndo[date.month] : '';
    final tanggal = date != null ? DateFormat('dd').format(date) : '';
    final waktu = date != null ? DateFormat('HH:mm').format(date) : '';
    final countdown = date != null ? _countdownText(date) : '';

    final icon = _eventIcon(type);
    final label = _eventLabel(type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Pengingat',
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
                    'MULAI DALAM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    countdown,
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      bulan,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      tanggal,
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
                      title,
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
                          waktu,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle,
                            size: 4,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
              onPressed: onSelengkapnya,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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

IconData _eventIcon(String type) {
  switch (type) {
    case 'RAPAT':
      return Icons.people_outline;
    default:
      return Icons.event_outlined;
  }
}

String _eventLabel(String type) {
  switch (type) {
    case 'RAPAT':
      return 'Rapat Mendatang';
    case 'KEGIATAN_UMUM':
      return 'Kegiatan Mendatang';
    default:
      return 'Kegiatan Mendatang';
  }
}

String _countdownText(DateTime date) {
  final diff = date.difference(DateTime.now());
  if (diff.inDays > 7) {
    final weeks = (diff.inDays / 7).ceil();
    return '$weeks Minggu';
  } else if (diff.inDays > 0) {
    return '${diff.inDays} Hari';
  } else if (diff.inHours > 0) {
    return '${diff.inHours} Jam';
  } else {
    return 'Hari Ini';
  }
}
