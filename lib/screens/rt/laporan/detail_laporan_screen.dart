import 'package:wargify/core/utils/app_error.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';

import 'laporan_screen.dart';

class DetailLaporanScreen extends StatefulWidget {
  final FacilityReport report;

  const DetailLaporanScreen({super.key, required this.report});

  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _noteController = TextEditingController();

  late String _currentStatus;
  XFile? _selectedResolvedPhoto;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report.status;
    _noteController.text = widget.report.responseMessage;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

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

  Future<void> _pickResolvedPhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );

    if (image == null || !mounted) return;
    setState(() => _selectedResolvedPhoto = image);
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final note = _noteController.text.trim();
    if (_currentStatus == 'RESOLVED' && note.isEmpty) {
      _showSnack('Catatan penyelesaian wajib diisi.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_currentStatus == 'RESOLVED') {
        final formData = FormData.fromMap({
          'response_message': note,
          if (_selectedResolvedPhoto != null)
            'resolved_photo_file': await MultipartFile.fromFile(
              _selectedResolvedPhoto!.path,
              filename: _selectedResolvedPhoto!.name,
            ),
        });

        await _apiService.patchMultipart(
          '${ApiEndpoints.facilityReports}/${widget.report.id}/response',
          formData,
        );
      } else {
        await _apiService.patch(
          '${ApiEndpoints.facilityReports}/${widget.report.id}/status',
          {'status': _currentStatus},
        );
      }

      if (!mounted) return;
      _showSnack('Laporan berhasil diperbarui.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Gagal memperbarui laporan: ${AppError.userFriendly(error)}', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final statusColor = _statusColor(_currentStatus);

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
          'Detail Laporan',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ID: ${widget.report.id}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(_currentStatus).toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildReportImage(),
          const SizedBox(height: 16),
          _buildReportDetail(dateFormatter, timeFormatter),
          const SizedBox(height: 18),
          _buildStatusCard(),
          const SizedBox(height: 18),
          _buildResponseCard(),
          const SizedBox(height: 18),
          _buildTimeline(dateFormatter, timeFormatter),
        ],
      ),
    );
  }

  Widget _buildReportImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 210,
        width: double.infinity,
        color: const Color(0xFFE9EFF5),
        child: widget.report.imageUrl.isEmpty
            ? _buildNoImage('Tidak ada foto laporan')
            : Image.network(
                widget.report.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildNoImage('Foto gagal dimuat'),
              ),
      ),
    );
  }

  Widget _buildNoImage(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_rounded, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDetail(
    DateFormat dateFormatter,
    DateFormat timeFormatter,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0FA),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _categoryIcon(widget.report.category),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.report.category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.report.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0D1B2A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.report.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.person_rounded,
            'Pelapor',
            '${widget.report.reporterName} • ${widget.report.reporterPhone}',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.schedule_rounded,
            'Waktu laporan',
            '${dateFormatter.format(widget.report.createdAt)} • ${timeFormatter.format(widget.report.createdAt)} WIB',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubah Status',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusButton('SUBMITTED', Icons.access_time_rounded),
              const SizedBox(width: 8),
              _buildStatusButton('IN_PROGRESS', Icons.engineering_rounded),
              const SizedBox(width: 8),
              _buildStatusButton('RESOLVED', Icons.check_circle_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String status, IconData icon) {
    final selected = _currentStatus == status;
    final color = _statusColor(status);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentStatus = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 64,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.08)
                : const Color(0xFFF8FBFE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : const Color(0xFFE1EAF3),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? color : Colors.grey[400], size: 20),
              const SizedBox(height: 5),
              Text(
                _statusLabel(status),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: selected ? color : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseCard() {
    final resolving = _currentStatus == 'RESOLVED';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resolving ? 'Penyelesaian Laporan' : 'Catatan Penyelesaian',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            resolving
                ? 'Catatan akan dikirim ke warga dan status laporan menjadi selesai.'
                : 'Backend hanya menyimpan catatan ketika laporan diselesaikan.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            enabled: resolving,
            maxLines: 4,
            maxLength: 500,
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Contoh: Lampu jalan sudah diganti dan berfungsi.',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: resolving ? const Color(0xFFF8FBFE) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE1EAF3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE1EAF3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Foto Bukti Selesai',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          _buildResolvedPhoto(resolving),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedPhoto(bool enabled) {
    Widget content;

    if (_selectedResolvedPhoto != null) {
      content = Image.file(
        File(_selectedResolvedPhoto!.path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (widget.report.resolvedPhotoUrl.isNotEmpty) {
      content = Image.network(
        widget.report.resolvedPhotoUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildNoImage('Foto bukti gagal dimuat'),
      );
    } else {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: enabled ? AppColors.primary : Colors.grey[400],
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              enabled ? 'Pilih foto bukti' : 'Aktif saat status selesai',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: enabled ? const Color(0xFF0D1B2A) : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: enabled ? _pickResolvedPhoto : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 126,
          width: double.infinity,
          color: const Color(0xFFF8FBFE),
          child: Stack(
            children: [
              Positioned.fill(child: content),
              if (_selectedResolvedPhoto != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedResolvedPhoto = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 16,
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

  Widget _buildTimeline(DateFormat dateFormatter, DateFormat timeFormatter) {
    final items = <({String title, String subtitle, bool active})>[
      (
        title: 'Laporan diterima',
        subtitle:
            '${widget.report.reporterName} mengirim laporan pada ${dateFormatter.format(widget.report.createdAt)} ${timeFormatter.format(widget.report.createdAt)} WIB.',
        active: widget.report.status == 'SUBMITTED',
      ),
      if (widget.report.status == 'IN_PROGRESS' ||
          widget.report.status == 'RESOLVED')
        (
          title: 'Laporan diproses',
          subtitle: 'Pengurus RT mulai menangani laporan ini.',
          active: widget.report.status == 'IN_PROGRESS',
        ),
      if (widget.report.status == 'RESOLVED')
        (
          title: 'Laporan selesai',
          subtitle: widget.report.responseMessage.isEmpty
              ? 'Laporan ditandai selesai.'
              : widget.report.responseMessage,
          active: true,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Aktivitas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0D1B2A),
          ),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.active ? AppColors.primary : Colors.white,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 74,
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7EEF7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
