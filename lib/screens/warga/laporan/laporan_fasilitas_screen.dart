import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';

class LaporanFasilitasScreen extends StatefulWidget {
  const LaporanFasilitasScreen({super.key});

  @override
  State<LaporanFasilitasScreen> createState() => _LaporanFasilitasScreenState();
}

class _LaporanFasilitasScreenState extends State<LaporanFasilitasScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _reports = [];
  String _selectedStatus = 'ALL';
  String _search = '';
  bool _isLoading = true;
  String? _errorMessage;

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
      if (!mounted) return;
      setState(() {
        _reports = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat laporan. Silakan coba lagi.';
        });
      }
      // Logging untuk debugging
      debugPrint('Error fetching reports: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredReports {
    final keyword = _search.trim().toLowerCase();
    return _reports.where((report) {
      final status = report['status']?.toString() ?? '';
      final matchesStatus =
          _selectedStatus == 'ALL' || status == _selectedStatus;
      final text = [
        report['title'],
        report['category'],
        report['description'],
        (report['reporter'] as Map?)?['full_name'],
      ].join(' ').toLowerCase();
      final matchesSearch = keyword.isEmpty || text.contains(keyword);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'SUBMITTED':
        return 'Menunggu';
      case 'IN_PROGRESS':
        return 'Diproses';
      case 'RESOLVED':
        return 'Selesai';
      default:
        return 'Semua';
    }
  }

  Color _statusTextColor(String? status) {
    switch (status) {
      case 'SUBMITTED':
        return const Color(0xFFE65100);
      case 'IN_PROGRESS':
        return const Color(0xFF0D47A1);
      case 'RESOLVED':
        return const Color(0xFF2E7D32);
      default:
        return AppColors.primary;
    }
  }

  Color _statusBgColor(String? status) {
    switch (status) {
      case 'SUBMITTED':
        return const Color(0xFFE65100).withOpacity(0.1);
      case 'IN_PROGRESS':
        return const Color(0xFF0D47A1).withOpacity(0.1);
      case 'RESOLVED':
        return const Color(0xFF2E7D32).withOpacity(0.1);
      default:
        return Colors.white;
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'Listrik':
        return Icons.lightbulb_outline_rounded;
      case 'Air':
        return Icons.water_drop_outlined;
      case 'Jalan':
        return Icons.map_outlined;
      case 'Kebersihan':
        return Icons.delete_outline_rounded;
      default:
        return Icons.construction_rounded;
    }
  }

  Future<void> _openAddReportSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _AddFacilityReportSheet(
        apiService: _apiService,
        imagePicker: _imagePicker,
      ),
    );

    if (created == true) {
      await _fetchReports();
    }
  }

  void _showReportDetail(Map<String, dynamic> report) {
    final imageUrl = report['image_url']?.toString() ?? '';
    final resolvedPhotoUrl = report['resolved_photo_url']?.toString() ?? '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report['title']?.toString() ?? 'Detail Laporan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D1B2A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusPill(report['status']?.toString()),
                  const SizedBox(height: 16),
                  _detailText('Kategori', report['category']),
                  _detailText('Tanggal', _formatDate(report['created_at'])),
                  _detailText(
                    'Pelapor',
                    (report['reporter'] as Map?)?['full_name'] ?? 'Warga',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    report['description']?.toString() ?? '-',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _detailImage('Foto Laporan', imageUrl),
                  ],
                  if ((report['response_message']?.toString() ?? '')
                      .isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _detailText('Tanggapan RT', report['response_message']),
                  ],
                  if (resolvedPhotoUrl.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _detailImage('Bukti Perbaikan', resolvedPhotoUrl),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailText(String label, Object? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: label == 'Kategori' ? AppColors.primary : const Color(0xFF0D1B2A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailImage(String label, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0D1B2A),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              color: const Color(0xFFE8F2FC),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = _filteredReports;

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
          'Laporan Fasilitas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddReportSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Tambah Laporan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 110),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 22),
            _buildStatusFilters(),
            const SizedBox(height: 28),
            _buildSummaryCard(),
            const SizedBox(height: 26),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _buildErrorState()
            else if (reports.isEmpty)
              _buildEmptyState()
            else
              ...reports.map((report) => _buildReportCard(report)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9F1F8)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _search = value),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Cari laporan',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey[400],
          ),
          icon: const Icon(
            Icons.search_rounded,
            size: 22,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    final filters = {
      'ALL': 'Semua',
      'SUBMITTED': 'Menunggu',
      'IN_PROGRESS': 'Diproses',
      'RESOLVED': 'Selesai',
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: filters.entries.map((entry) {
          final active = _selectedStatus == entry.key;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedStatus = entry.key),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                height: 44,
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: active ? AppColors.primary : Colors.grey[700],
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
    final activeCount = _reports
        .where((report) => report['status'] != 'RESOLVED')
        .length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS LAPORAN',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$activeCount Laporan Aktif',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Terima kasih atas kontribusi Anda dalam menjaga fasilitas lingkungan.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.72),
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['status']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9F1F8)),
      ),
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
                  _categoryIcon(report['category']?.toString()),
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const Spacer(),
              _buildStatusPill(status),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _formatDate(report['created_at']),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report['title']?.toString() ?? '-',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            report['description']?.toString() ?? '-',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              height: 1.42,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showReportDetail(report),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xFFE9F1F8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Lihat Detail',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _statusBgColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: _statusTextColor(status),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'Belum ada laporan fasilitas.',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

   Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchReports,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFacilityReportSheet extends StatefulWidget {
  const _AddFacilityReportSheet({
    required this.apiService,
    required this.imagePicker,
  });

  final ApiService apiService;
  final ImagePicker imagePicker;

  @override
  State<_AddFacilityReportSheet> createState() =>
      _AddFacilityReportSheetState();
}

class _AddFacilityReportSheetState extends State<_AddFacilityReportSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  XFile? _image;
  bool _isSaving = false;

  static const _categoryValues = ['Listrik', 'Air', 'Jalan', 'Kebersihan', 'Lainnya'];

  IconData _categoryIconFromValue(String value) {
    switch (value) {
      case 'Listrik':
        return Icons.lightbulb_outline_rounded;
      case 'Air':
        return Icons.water_drop_outlined;
      case 'Jalan':
        return Icons.map_outlined;
      case 'Kebersihan':
        return Icons.delete_outline_rounded;
      default:
        return Icons.construction_rounded;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Sumber Foto',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE9F1F8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Ambil Foto dari Kamera',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D1B2A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE9F1F8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Pilih dari Galeri',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D1B2A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final image = await widget.imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image != null) setState(() => _image = image);
  }

  Widget _buildCategoryPicker() {
    final hasValue = _selectedCategory != null;

    return InkWell(
      onTap: _showCategoryPicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD7E8FF)),
        ),
        child: Row(
          children: [
            Icon(
              hasValue
                  ? _categoryIconFromValue(_selectedCategory!)
                  : Icons.category_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? _selectedCategory! : 'Pilih Kategori',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: hasValue
                      ? const Color(0xFF0D1B2A)
                      : Colors.grey[400],
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Kategori',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._categoryValues.map((value) {
                    final active = value == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedCategory = value);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary.withOpacity(0.08)
                                : const Color(0xFFF4F8FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active ? AppColors.primary : const Color(0xFFE9F1F8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _categoryIconFromValue(value),
                                color: active ? AppColors.primary : Colors.grey[600],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                value,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: active
                                      ? AppColors.primary
                                      : const Color(0xFF0D1B2A),
                                ),
                              ),
                              const Spacer(),
                              if (active)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _selectedCategory == null ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul, kategori, dan deskripsi wajib diisi.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final formData = FormData.fromMap({
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'description': _descriptionController.text.trim(),
    });

    if (_image != null) {
      formData.files.add(
        MapEntry(
          'image_file',
          await MultipartFile.fromFile(_image!.path, filename: _image!.name),
        ),
      );
    }

    try {
      await widget.apiService.postMultipart(
        ApiEndpoints.facilityReports,
        formData,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan fasilitas berhasil dikirim.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim laporan.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Laporan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 18),
              _textField(_titleController, 'Judul Laporan'),
              const SizedBox(height: 12),
              _buildCategoryPicker(),
              const SizedBox(height: 12),
              _textField(_descriptionController, 'Deskripsi', maxLines: 4),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD7E8FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _image?.name ?? 'Upload Foto Fasilitas',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D1B2A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_isSaving ? 'Mengirim...' : 'Kirim Laporan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
