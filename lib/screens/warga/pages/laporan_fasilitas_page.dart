import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/screens/warga/pages/detail_laporan_page.dart';
import 'package:wargify/screens/warga/pages/tambah_laporan_page.dart';

class LaporanFasilitasPage extends StatefulWidget {
  const LaporanFasilitasPage({super.key});

  @override
  State<LaporanFasilitasPage> createState() => _LaporanFasilitasPageState();
}

class _LaporanFasilitasPageState extends State<LaporanFasilitasPage> {
  int _selectedFilter = 0; // 0=Semua, 1=Menunggu, 2=Diproses, 3=Selesai
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _filters = ['Semua', 'Menunggu', 'Diproses', 'Selesai'];

  // --- Dummy Data Laporan ---
  final List<Map<String, dynamic>> _laporanList = [
    {
      'id': '001',
      'icon': Icons.lightbulb_outline,
      'kategori': 'electricity',
      'tanggal': '12 Okt 2023',
      'judul': 'Lampu Jalan Mati Blok C',
      'deskripsi':
          'Lampu penerangan di depan rumah C-12 padam sejak 2 hari yang lalu, membuat area gelap saat malam.',
      'status': 'Menunggu',
      'tanggalLengkap': '12 Oktober 2023, 08:00 WIB',
      'deskripsiLengkap':
          'Lampu jalan di pertigaan Blok C mati total sejak tadi malam. Kondisi jalan menjadi sangat gelap dan membahayakan warga yang melintas saat malam hari. Mohon segera dilakukan perbaikan demi keamanan warga.',
      'kategoriLabel': 'Fasilitas Umum',
      'timeline': [
        {
          'status': 'Laporan Terkirim',
          'waktu': '12 Okt, 08:00',
          'done': true,
          'catatan': null,
        },
        {
          'status': 'Menunggu',
          'waktu': null,
          'done': false,
          'catatan': 'tunggu bos, mekanik lagi makan',
        },
        {'status': 'Selesai', 'waktu': null, 'done': false, 'catatan': null},
      ],
    },
    {
      'id': '002',
      'icon': Icons.water_drop_outlined,
      'kategori': 'water',
      'tanggal': '10 Okt 2023',
      'judul': 'Pipa Bocor Dekat Taman',
      'deskripsi':
          'Terjadi rembesan air yang cukup besar di dekat pintu masuk taman warga Blok A.',
      'status': 'Diproses',
      'tanggalLengkap': '10 Oktober 2023, 09:30 WIB',
      'deskripsiLengkap':
          'Pipa air utama di dekat taman blok A mengalami kebocoran cukup parah. Air merembes ke jalan dan menyebabkan genangan. Sudah dilaporkan ke petugas namun belum ada tindak lanjut.',
      'kategoriLabel': 'Fasilitas Umum',
      'timeline': [
        {
          'status': 'Laporan Terkirim',
          'waktu': '10 Okt, 09:30',
          'done': true,
          'catatan': null,
        },
        {
          'status': 'Sedang Diproses',
          'waktu': '11 Okt, 10:00',
          'done': true,
          'catatan': 'besok pagi selesai bos',
        },
        {'status': 'Selesai', 'waktu': null, 'done': false, 'catatan': null},
      ],
    },
    {
      'id': '003',
      'icon': Icons.delete_outline,
      'kategori': 'cleanliness',
      'tanggal': '08 Okt 2023',
      'judul': 'TPS Penuh & Berbau',
      'deskripsi':
          'Tempat pembuangan sampah sementara sudah melebihi kapasitas dan belum diangkut.',
      'status': 'Selesai',
      'tanggalLengkap': '08 Oktober 2023, 07:00 WIB',
      'deskripsiLengkap':
          'TPS di ujung gang blok B sudah penuh sejak 3 hari lalu. Sampah meluap hingga ke jalan dan menimbulkan bau tidak sedap. Mohon segera dilakukan pengangkutan.',
      'kategoriLabel': 'Kebersihan',
      'timeline': [
        {
          'status': 'Laporan Terkirim',
          'waktu': '08 Okt, 07:00',
          'done': true,
          'catatan': null,
        },
        {
          'status': 'Sedang Diproses',
          'waktu': '08 Okt, 13:00',
          'done': true,
          'catatan': 'petugas sudah dikirim',
        },
        {
          'status': 'Selesai',
          'waktu': '09 Okt, 08:00',
          'done': true,
          'catatan': 'sampah telah diangkut',
        },
      ],
    },
    {
      'id': '004',
      'icon': Icons.construction_outlined,
      'kategori': 'road',
      'tanggal': '05 Okt 2023',
      'judul': 'Trotoar Rusak Blok D',
      'deskripsi':
          'Beberapa bagian paving block terlepas dan membahayakan pejalan kaki di area pertigaan.',
      'status': 'Diproses',
      'tanggalLengkap': '05 Oktober 2023, 14:00 WIB',
      'deskripsiLengkap':
          'Trotoar di depan blok D pertigaan utama mengalami kerusakan parah. Beberapa paving block sudah terangkat dan bisa membahayakan pejalan kaki terutama lansia dan anak-anak.',
      'kategoriLabel': 'Infrastruktur',
      'timeline': [
        {
          'status': 'Laporan Terkirim',
          'waktu': '05 Okt, 14:00',
          'done': true,
          'catatan': null,
        },
        {
          'status': 'Sedang Diproses',
          'waktu': '06 Okt, 09:00',
          'done': true,
          'catatan': 'jadwal perbaikan minggu ini',
        },
        {'status': 'Selesai', 'waktu': null, 'done': false, 'catatan': null},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredList {
    List<Map<String, dynamic>> list = _laporanList;

    if (_selectedFilter != 0) {
      final filterStatus = _filters[_selectedFilter];
      list = list.where((item) => item['status'] == filterStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (item) =>
                item['judul'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                item['deskripsi'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return list;
  }

  int get _totalAktif =>
      _laporanList.where((l) => l['status'] != 'Selesai').length;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu':
        return const Color(0xFFE6A817);
      case 'Diproses':
        return AppColors.primary;
      case 'Selesai':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Menunggu':
        return const Color(0xFFFFF3CD);
      case 'Diproses':
        return AppColors.secondary;
      case 'Selesai':
        return const Color(0xFFD4EDDA);
      default:
        return AppColors.background;
    }
  }

  IconData _getKategoriIcon(String kategori) {
    switch (kategori) {
      case 'electricity':
        return Icons.lightbulb_outline;
      case 'water':
        return Icons.water_drop_outlined;
      case 'road':
        return Icons.construction_outlined;
      case 'cleanliness':
        return Icons.delete_outline;
      case 'security':
        return Icons.shield_outlined;
      default:
        return Icons.report_outlined;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Laporan Fasilitas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
            ),
            onPressed: () {
              // TODO: navigate to notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // --- Search Bar ---
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari laporan',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Filter Tabs ---
                Row(
                  children: List.generate(_filters.length, (i) {
                    final isSelected = _selectedFilter == i;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i < _filters.length - 1 ? 8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            _filters[i],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // --- Status Summary Card ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS LAPORAN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white.withOpacity(0.8),
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_totalAktif Laporan Aktif',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Terima kasih atas kontribusi Anda dalam menjaga fasilitas lingkungan.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.engineering_outlined,
                          size: 56,
                          color: AppColors.white.withOpacity(0.25),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Laporan List ---
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.textSecondary.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada laporan ditemukan',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map(
                      (laporan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LaporanCard(
                          laporan: laporan,
                          statusColor: _getStatusColor(laporan['status']),
                          statusBgColor: _getStatusBgColor(laporan['status']),
                          icon: _getKategoriIcon(laporan['kategori']),
                          onDetailTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailLaporanPage(laporan: laporan),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // --- FAB Tambah Laporan ---
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TambahLaporanPage()),
            );
          },
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 4,
          icon: const Icon(Icons.add),
          label: Text(
            'Tambah Laporan',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── Laporan Card ─────────────────────────────────────────────────────────────

class _LaporanCard extends StatelessWidget {
  final Map<String, dynamic> laporan;
  final Color statusColor;
  final Color statusBgColor;
  final IconData icon;
  final VoidCallback onDetailTap;

  const _LaporanCard({
    required this.laporan,
    required this.statusColor,
    required this.statusBgColor,
    required this.icon,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laporan['tanggal'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      laporan['judul'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  laporan['status'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            laporan['deskripsi'],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: onDetailTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Lihat Detail',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
