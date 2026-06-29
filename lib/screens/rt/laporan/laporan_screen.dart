import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/core/utils/wib_datetime.dart';
import 'package:wargify/models/user_model.dart';
import 'package:wargify/services/api_service.dart';

import 'detail_laporan_screen.dart';

class FacilityReport {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String reporterName;
  final String reporterPhone;
  final String imageUrl;
  final String responseMessage;
  final String resolvedPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FacilityReport({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.reporterName,
    required this.reporterPhone,
    required this.imageUrl,
    required this.responseMessage,
    required this.resolvedPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FacilityReport.fromJson(Map<String, dynamic> json) {
    final reporter = Map<String, dynamic>.from((json['reporter'] ?? {}) as Map);
    final createdAt = parseWibDateTime(json['created_at']);
    final updatedAt = parseWibDateTime(json['updated_at']);

    return FacilityReport(
      id: json['report_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Laporan fasilitas',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Lainnya',
      status: json['status']?.toString() ?? 'SUBMITTED',
      reporterName: reporter['full_name']?.toString() ?? 'Warga',
      reporterPhone: reporter['phone_number']?.toString() ?? '-',
      imageUrl: json['image_url']?.toString() ?? '',
      responseMessage: json['response_message']?.toString() ?? '',
      resolvedPhotoUrl: json['resolved_photo_url']?.toString() ?? '',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? createdAt ?? DateTime.now(),
    );
  }

  FacilityReport copyWith({
    String? status,
    String? responseMessage,
    String? resolvedPhotoUrl,
    DateTime? updatedAt,
  }) {
    return FacilityReport(
      id: id,
      title: title,
      description: description,
      category: category,
      status: status ?? this.status,
      reporterName: reporterName,
      reporterPhone: reporterPhone,
      imageUrl: imageUrl,
      responseMessage: responseMessage ?? this.responseMessage,
      resolvedPhotoUrl: resolvedPhotoUrl ?? this.resolvedPhotoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LaporanScreen extends StatefulWidget {
  final UserModel user;

  const LaporanScreen({super.key, required this.user});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  List<FacilityReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await _apiService.getList(ApiEndpoints.facilityReports);
      final reports =
          rows
              .whereType<Map>()
              .map(
                (row) =>
                    FacilityReport.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat laporan fasilitas.';
      });
    }
  }

  List<FacilityReport> get _filteredReports {
    final query = _searchQuery.trim().toLowerCase();

    return _reports.where((report) {
      final matchesStatus =
          _selectedStatus == 'ALL' || report.status == _selectedStatus;
      final matchesSearch =
          query.isEmpty ||
          [
            report.title,
            report.description,
            report.category,
            report.reporterName,
            _statusLabel(report.status),
          ].any((value) => value.toLowerCase().contains(query));

      return matchesStatus && matchesSearch;
    }).toList();
  }

  int _countByStatus(String status) =>
      _reports.where((report) => report.status == status).length;

  int get _activeCount =>
      _countByStatus('SUBMITTED') + _countByStatus('IN_PROGRESS');

  String _statusLabel(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'Diproses';
      case 'RESOLVED':
        return 'Selesai';
      default:
        return 'Menunggu';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return const Color(0xFF0D47A1);
      case 'RESOLVED':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFFE65100);
    }
  }

  Color _statusBgColor(String status) =>
      _statusColor(status).withValues(alpha: 0.1);

  IconData _categoryIcon(String category) {
    final text = category.toLowerCase();
    if (text.contains('lampu') || text.contains('listrik')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (text.contains('air') || text.contains('pipa')) {
      return Icons.plumbing_rounded;
    }
    if (text.contains('sampah') || text.contains('selokan')) {
      return Icons.delete_outline_rounded;
    }
    if (text.contains('jalan')) {
      return Icons.add_road_rounded;
    }
    return Icons.report_problem_outlined;
  }

  Future<void> _openDetail(FacilityReport report) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLaporanScreen(report: report),
      ),
    );

    if (changed == true) {
      await _fetchReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _filteredReports;

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
          'Manajemen Laporan',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildStatusTabs(),
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 16),
            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else if (filteredReports.isEmpty)
              _buildEmptyState()
            else
              ...filteredReports.map(_buildReportCard),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    final tabs = [
      ('ALL', 'Semua'),
      ('SUBMITTED', 'Menunggu'),
      ('IN_PROGRESS', 'Diproses'),
      ('RESOLVED', 'Selesai'),
    ];

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: tabs.map((tab) {
          final selected = _selectedStatus == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab.$2,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.primary : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0056B3), Color(0xFF003C80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS LAPORAN FASILITAS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.72),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_activeCount Laporan Aktif',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMiniStat('Menunggu', _countByStatus('SUBMITTED')),
              _buildMiniStat('Diproses', _countByStatus('IN_PROGRESS')),
              _buildMiniStat('Selesai', _countByStatus('RESOLVED')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Cari judul, kategori, pelapor, atau status',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: Colors.grey[400],
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Colors.grey,
          size: 22,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _fetchReports,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.report_gmailerrorred_rounded,
              size: 48,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Laporan',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada laporan fasilitas pada filter ini.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(FacilityReport report) {
    final statusColor = _statusColor(report.status);
    final statusBg = _statusBgColor(report.status);
    final dateFormatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9F1F8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openDetail(report),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _categoryIcon(report.category),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateFormatter.format(report.createdAt),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusLabel(report.status).toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        report.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.grey.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: const Color(0xFFE0E6ED),
                  child: Text(
                    report.reporterName.isEmpty
                        ? 'W'
                        : report.reporterName[0].toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${report.reporterName} • ${timeFormatter.format(report.createdAt)} WIB',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Text(
                  'Kelola',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
