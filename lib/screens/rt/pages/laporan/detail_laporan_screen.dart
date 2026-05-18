import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import 'laporan_screen.dart';

class DetailLaporanScreen extends StatefulWidget {
  final Report report;
  const DetailLaporanScreen({super.key, required this.report});

  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  final TextEditingController _noteController = TextEditingController();
  late String _currentStatus;
  int _charCount = 0;
  String? _mockUploadedPhotoUrl;
  bool _isUploading = false;
  late List<TimelineLog> _timelineLogs;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report.status;
    _timelineLogs = List.from(widget.report.timeline);
    _noteController.addListener(() {
      setState(() {
        _charCount = _noteController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handleStatusSelect(String status) {
    setState(() {
      _currentStatus = status;
    });
  }

  void _simulatePhotoUpload() async {
    setState(() {
      _isUploading = true;
    });
    // Simulate minor lag for premium feel
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isUploading = false;
        _mockUploadedPhotoUrl = 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800'; // Repaired pipe mock
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto bukti berhasil diunggah!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _removeUploadedPhoto() {
    setState(() {
      _mockUploadedPhotoUrl = null;
    });
  }

  void _handleSave() {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harap tuliskan catatan perkembangan perbaikan.', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Add new timeline log
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
    
    // Add to top of list as the latest activity
    final newLog = TimelineLog(
      time: timeStr,
      content: 'Status diubah menjadi $_currentStatus oleh Ketua RT. Catatan: "$note"',
      isHighlight: true,
    );

    // Remove highlight state from previous logs
    final updatedLogs = _timelineLogs.map((l) => TimelineLog(time: l.time, content: l.content, isHighlight: false)).toList();
    updatedLogs.insert(0, newLog);

    final updatedReport = widget.report.copyWith(
      status: _currentStatus,
      timeline: updatedLogs,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status laporan berhasil diperbarui!', style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Return the updated report object back to the main list screen
    Navigator.pop(context, updatedReport);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu':
        return const Color(0xFFE65100);
      case 'Diproses':
        return const Color(0xFF0D47A1);
      case 'Selesai':
        return const Color(0xFF2E7D32);
      default:
        return Colors.black;
    }
  }

  Color _getCategoryBadgeBg(String cat) {
    if (cat.toUpperCase() == 'URGENT') {
      return const Color(0xFFFFEBEE); // Light Red
    }
    return const Color(0xFFE3F2FD); // Light Blue
  }

  Color _getCategoryBadgeText(String cat) {
    if (cat.toUpperCase() == 'URGENT') {
      return const Color(0xFFC62828); // Dark Red
    }
    return const Color(0xFF1565C0); // Dark Blue
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_currentStatus);

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
          'Detail & Update Status',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subheader ID & Urgency Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID LAPORAN: ${widget.report.id}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryBadgeBg(widget.report.category),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.report.category,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: _getCategoryBadgeText(widget.report.category),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Premium Image Header Block
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Full cover Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      widget.report.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image_rounded, size: 48),
                        );
                      },
                    ),
                  ),
                  // Dark shadow overlay at bottom for visibility of location badge
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                  // Location badge floating bottom left
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.report.location,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Status floating top right
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentStatus.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Report Details Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3F9).withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.report.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.report.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.withOpacity(0.12), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DILAPORKAN OLEH',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.report.reporterName} (${widget.report.reporterRole})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D1B2A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WAKTU',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.report.time,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D1B2A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Status Update Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0056B3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pembaruan Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'PILIH STATUS SAAT INI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Three Row Status Buttons
                  Row(
                    children: [
                      _buildStatusSelectButton('Menunggu', Icons.access_time_rounded),
                      const SizedBox(width: 8),
                      _buildStatusSelectButton('Diproses', Icons.engineering_rounded),
                      const SizedBox(width: 8),
                      _buildStatusSelectButton('Selesai', Icons.check_circle_outline_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CATATAN UNTUK WARGA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$_charCount/140 karakter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: _charCount > 140 ? AppColors.danger : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Text area
                  TextFormField(
                    controller: _noteController,
                    maxLines: 4,
                    maxLength: 140,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tuliskan perkembangan perbaikan di sini...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[350]),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF8FBFE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'BUKTI FOTO (OPSIONAL)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Upload photo block
                  _mockUploadedPhotoUrl != null
                      ? _buildUploadedPhotoThumbnail()
                      : _buildPhotoUploadPlaceholder(),

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        'Simpan',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056B3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Riwayat Aktivitas (Vertical Timeline)
            Text(
              'Riwayat Aktivitas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline List View
            _buildTimelineListView(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelectButton(String status, IconData icon) {
    bool isSelected = _currentStatus == status;
    Color colorTheme = _getStatusColor(status);

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleStatusSelect(status),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? colorTheme.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colorTheme : Colors.grey.withOpacity(0.15),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? colorTheme : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? colorTheme : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadPlaceholder() {
    return GestureDetector(
      onTap: _isUploading ? null : _simulatePhotoUpload,
      child: Container(
        width: double.infinity,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD0DFEF),
            width: 1.0,
            style: BorderStyle.solid, // Uses standard borders since custom dash border requires external painter
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _isUploading
              ? [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mengunggah...',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500]),
                  ),
                ]
              : [
                  const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF0056B3), size: 30),
                  const SizedBox(height: 8),
                  Text(
                    'Unggah Foto Progres',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D1B2A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Format JPG, PNG max 5MB',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildUploadedPhotoThumbnail() {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              _mockUploadedPhotoUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              color: Colors.black.withOpacity(0.15),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: _removeUploadedPhoto,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 12,
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFFACF44A), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Foto terpilih',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
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
    );
  }

  Widget _buildTimelineListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _timelineLogs.length,
      itemBuilder: (context, index) {
        final log = _timelineLogs[index];
        bool isLast = index == _timelineLogs.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Circle/Dot and Vertical Line Timeline Painter
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: log.isHighlight ? const Color(0xFFE3F2FD) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: log.isHighlight ? const Color(0xFF0056B3) : const Color(0xFF0056B3).withOpacity(0.5),
                      width: log.isHighlight ? 4 : 2.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2.0,
                    height: 90, // Taller line to match description height
                    color: const Color(0xFF0056B3).withOpacity(0.2),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Timeline Card Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blue Highlight Box for new/latest status
                  log.isHighlight
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF5FC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD2E4F7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0056B3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'BARU SAJA',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                log.content,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D47A1),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEBF2F7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.time,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                log.content,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF0D1B2A),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
