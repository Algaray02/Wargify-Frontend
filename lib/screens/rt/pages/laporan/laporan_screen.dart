import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/user_model.dart';
import 'detail_laporan_screen.dart';

class Report {
  final String id;
  final String title;
  final String description;
  final String category; // URGENT, NORMAL, dll
  final String status; // Menunggu, Diproses, Selesai
  final String date;
  final String time;
  final String location;
  final String reporterName;
  final String reporterRole;
  final String imageUrl;
  final List<TimelineLog> timeline;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.date,
    required this.time,
    required this.location,
    required this.reporterName,
    required this.reporterRole,
    required this.imageUrl,
    required this.timeline,
  });

  Report copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? status,
    String? date,
    String? time,
    String? location,
    String? reporterName,
    String? reporterRole,
    String? imageUrl,
    List<TimelineLog>? timeline,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      reporterName: reporterName ?? this.reporterName,
      reporterRole: reporterRole ?? this.reporterRole,
      imageUrl: imageUrl ?? this.imageUrl,
      timeline: timeline ?? this.timeline,
    );
  }
}

class TimelineLog {
  final String time;
  final String content;
  final bool isHighlight;

  TimelineLog({
    required this.time,
    required this.content,
    this.isHighlight = false,
  });
}

class LaporanScreen extends StatefulWidget {
  final UserModel user;
  const LaporanScreen({super.key, required this.user});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'Home'; // Home, Menunggu, Diproses, Selesai
  String _searchQuery = '';

  // Mock initial reports based on references
  late final List<Report> _reports;

  @override
  void initState() {
    super.initState();
    _reports = [
      Report(
        id: '#WRG-8821',
        title: 'Kebocoran Pipa Utama',
        description: 'Pipa distribusi air bersih mengalami retakan besar. Air menggenangi area parkir dan mengancam panel listrik terdekat.',
        category: 'URGENT',
        status: 'Diproses',
        date: '12 OKT 2023',
        time: '10:45 WIB',
        location: 'Blok C - Area Parkir B1',
        reporterName: 'Budi Santoso',
        reporterRole: 'Warga',
        imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800',
        timeline: [
          TimelineLog(time: '10:52 WIB', content: 'Laporan divalidasi oleh RT 04. Teknisi plumbing eksternal telah dihubungi.'),
          TimelineLog(time: '10:45 WIB', content: 'Laporan diterima oleh sistem Wargify Sentinel dari Budi Santoso.'),
        ],
      ),
      Report(
        id: '#WRG-8822',
        title: 'Pipa Bocor Blok C',
        description: 'Air merembes dari langit-langit kamar mandi di Blok C No. 12. Mohon segera dicek karena berisiko merusak plafon rumah.',
        category: 'NORMAL',
        status: 'Menunggu',
        date: '12 OKT 2023',
        time: '08:15 WIB',
        location: 'Blok C - No. 12',
        reporterName: 'Ahmad Subarjo',
        reporterRole: 'Warga',
        imageUrl: 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=800',
        timeline: [
          TimelineLog(time: '08:15 WIB', content: 'Laporan dikirimkan oleh Ahmad Subarjo dan menunggu verifikasi RT.'),
        ],
      ),
      Report(
        id: '#WRG-8823',
        title: 'Lampu Jalan Padam',
        description: 'Lampu jalan di depan pos keamanan mati total sejak kemarin sore. Kondisi jalan menjadi sangat gelap gulita di malam hari.',
        category: 'NORMAL',
        status: 'Diproses',
        date: '11 OKT 2023',
        time: '19:30 WIB',
        location: 'Depan Pos Keamanan RT',
        reporterName: 'Siti Aminah',
        reporterRole: 'Warga',
        imageUrl: 'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
        timeline: [
          TimelineLog(time: '20:00 WIB', content: 'Status diubah menjadi Diproses. Pengadaan bohlam baru sedang diajukan oleh RT.'),
          TimelineLog(time: '19:30 WIB', content: 'Laporan dikirimkan oleh Siti Aminah.'),
        ],
      ),
      Report(
        id: '#WRG-8824',
        title: 'Sampah Menumpuk di Selokan',
        description: 'Tumpukan sampah plastik menyumbat aliran air selokan di dekat Balai Warga, memicu bau tidak sedap dan genangan air saat hujan.',
        category: 'NORMAL',
        status: 'Selesai',
        date: '10 OKT 2023',
        time: '09:00 WIB',
        location: 'Dekat Balai Warga',
        reporterName: 'Supriadi',
        reporterRole: 'Warga',
        imageUrl: 'https://images.unsplash.com/photo-1611284446314-60a58ac0deb9?w=800',
        timeline: [
          TimelineLog(time: '14:20 WIB', content: 'Pekerjaan selesai. Selokan dibersihkan secara gotong royong oleh warga.', isHighlight: true),
          TimelineLog(time: '11:00 WIB', content: 'Laporan disetujui. Kerja bakti dadakan dijadwalkan oleh RT.'),
          TimelineLog(time: '09:00 WIB', content: 'Laporan dikirimkan oleh Supriadi.'),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Report> _getFilteredReports() {
    return _reports.where((report) {
      // 1. Tab Status Filter
      if (_selectedTab != 'Home') {
        if (report.status.toLowerCase() != _selectedTab.toLowerCase()) {
          return false;
        }
      }
      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = report.title.toLowerCase().contains(query);
        final matchesDesc = report.description.toLowerCase().contains(query);
        final matchesLocation = report.location.toLowerCase().contains(query);
        return matchesTitle || matchesDesc || matchesLocation;
      }
      return true;
    }).toList();
  }

  int _getActiveReportsCount() {
    // Active reports are those in 'Menunggu' or 'Diproses' status
    return _reports.where((r) => r.status == 'Menunggu' || r.status == 'Diproses').length;
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Menunggu':
        return const Color(0xFFFFF3E0); // Light Orange
      case 'Diproses':
        return const Color(0xFFE3F2FD); // Light Blue
      case 'Selesai':
        return const Color(0xFFE8F5E9); // Light Green
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Menunggu':
        return const Color(0xFFE65100); // Dark Orange
      case 'Diproses':
        return const Color(0xFF0D47A1); // Dark Blue
      case 'Selesai':
        return const Color(0xFF2E7D32); // Dark Green
      default:
        return Colors.grey[800]!;
    }
  }

  IconData _getCategoryIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('pipa') || titleLower.contains('bocor') || titleLower.contains('air')) {
      return Icons.plumbing_rounded;
    } else if (titleLower.contains('lampu') || titleLower.contains('listrik') || titleLower.contains('padam')) {
      return Icons.lightbulb_outline_rounded;
    } else if (titleLower.contains('sampah') || titleLower.contains('selokan') || titleLower.contains('kotor')) {
      return Icons.delete_outline_rounded;
    } else {
      return Icons.report_problem_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _getFilteredReports();
    final activeCount = _getActiveReportsCount();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manajemen laporan warga',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          // Horizontal Custom Tab Filter (Home, Menunggu, Diproses, Selesai)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EFF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: ['Home', 'Menunggu', 'Diproses', 'Selesai'].map((tab) {
                  bool isSelected = _selectedTab == tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = tab;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          tab,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? const Color(0xFF00468B) : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Active Report Status Card (Blue Gradient Card)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0056B3), Color(0xFF003C80)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00468B).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUS LAPORAN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$activeCount Laporan Aktif',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Memerlukan penanganan segera',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari laporan...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Report List
                  filteredReports.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            return _buildReportCard(context, report);
                          },
                        ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.report_gmailerrorred_rounded, size: 48, color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Laporan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: const Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Belum ada laporan dari warga dalam kategori ini.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Report report) {
    final statusBg = _getStatusBgColor(report.status);
    final statusText = _getStatusTextColor(report.status);
    final categoryIcon = _getCategoryIcon(report.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9F1F8), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon, color: const Color(0xFF00468B), size: 24),
              ),
              const SizedBox(width: 14),

              // Title and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          report.date,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                        // Status badge top right
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            report.status.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: statusText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D1B2A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description Excerpt
          Text(
            '"${report.description}"',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(color: Colors.grey.withOpacity(0.08), height: 1),
          const SizedBox(height: 14),

          // Reporter info and Kelola link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFE0E6ED),
                    child: Text(
                      report.reporterName.substring(0, 1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00468B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    report.reporterName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  final updatedReport = await Navigator.push<Report>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailLaporanScreen(report: report),
                    ),
                  );
                  if (updatedReport != null) {
                    setState(() {
                      int index = _reports.indexWhere((r) => r.id == report.id);
                      if (index != -1) {
                        _reports[index] = updatedReport;
                      }
                    });
                  }
                },
                child: Text(
                  'Kelola Laporan ›',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0056B3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
