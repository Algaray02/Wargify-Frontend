import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';

class HomeQrScannerScreen extends StatefulWidget {
  const HomeQrScannerScreen({super.key});

  @override
  State<HomeQrScannerScreen> createState() => _HomeQrScannerScreenState();
}

class _HomeQrScannerScreenState extends State<HomeQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;
  bool _isFlashOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String? value) async {
    final code = value?.replaceAll(RegExp(r'\s+'), '').trim();
    if (code == null || code.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    try {
      final households = await _apiService.getList(ApiEndpoints.households);
      final household = households
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (row) => row?['qr_code_data']?.toString() == code,
            orElse: () => null,
          );

      if (!mounted) return;
      if (household == null) {
        await _showError('QR rumah tidak ditemukan.');
      } else {
        await _showHouseholdDetail(household);
      }
    } on DioException catch (error) {
      final message = error.response?.data is Map
          ? error.response?.data['message']?.toString() ??
                'Gagal memuat data rumah.'
          : 'Gagal memuat data rumah.';
      if (mounted) {
        await _showError(message);
      }
    } catch (_) {
      if (mounted) {
        await _showError('Terjadi kesalahan saat memproses QR rumah.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showError(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text(
              'QR Tidak Valid',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Scan Lagi',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ).whenComplete(() => _controller.start());
  }

  Future<void> _showHouseholdDetail(Map<String, dynamic> household) {
    final families = household['families'] is List
        ? household['families'] as List
        : const [];
    final familyRows = families.whereType<Map>().toList();
    final memberCount = familyRows.fold<int>(0, (total, family) {
      final members = family['members'];
      return total + (members is List ? members.length : 0);
    });

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0B63B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detail Rumah',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Blok ${household['block_number'] ?? '-'} / No. ${household['house_number'] ?? '-'}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _summaryChip(
                          Icons.groups_rounded,
                          '${familyRows.length}',
                          'Family',
                        ),
                        const SizedBox(width: 10),
                        _summaryChip(
                          Icons.people_alt_rounded,
                          '$memberCount',
                          'Anggota',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Family di Rumah Ini',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 12),
              if (familyRows.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Belum ada family pada rumah ini.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
                  ),
                )
              else
                ...familyRows.asMap().entries.map(
                  (entry) => _familyCard(
                    entry.key,
                    Map<String, dynamic>.from(entry.value),
                  ),
                ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(
                  'Scan Rumah Lain',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => _controller.start());
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _familyCard(int index, Map<String, dynamic> family) {
    final members = family['members'] is List
        ? family['members'] as List
        : const [];
    final head = members.whereType<Map>().firstWhere(
      (member) =>
          member['user_id']?.toString() ==
          family['head_of_family_id']?.toString(),
      orElse: () => const {},
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EEF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family ${index + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0D1B2A),
                      ),
                    ),
                    Text(
                      head.isEmpty
                          ? '${members.length} anggota'
                          : 'Kepala: ${head['full_name']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            Text(
              'Belum ada anggota.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          else
            ...members.whereType<Map>().map(
              (member) => _memberRow(Map<String, dynamic>.from(member)),
            ),
        ],
      ),
    );
  }

  Widget _memberRow(Map<String, dynamic> user) {
    final name = user['full_name']?.toString() ?? 'Warga';
    final photoUrl = user['profile_picture_url']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.primary,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'W',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                Text(
                  user['phone_number']?.toString() ??
                      user['role']?.toString() ??
                      '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double angle,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle * 3.14159 / 180,
        child: Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 5),
              left: BorderSide(color: Colors.white, width: 5),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) => _handleScan(
              capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Scan QR Rumah',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            await _controller.toggleTorch();
                            if (mounted) {
                              setState(() => _isFlashOn = !_isFlashOn);
                            }
                          },
                          icon: Icon(
                            _isFlashOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC1F3AF).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.home_work_outlined,
                          size: 18,
                          color: Color(0xFF2A6B2C),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SCAN DATA RUMAH',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF2A6B2C),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Arahkan kamera ke QR rumah',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Untuk melihat family dan seluruh anggota yang tinggal di rumah tersebut.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Stack(
                        children: [
                          _corner(top: 0, left: 0, angle: 0),
                          _corner(top: 0, right: 0, angle: 90),
                          _corner(bottom: 0, left: 0, angle: -90),
                          _corner(bottom: 0, right: 0, angle: 180),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pastikan QR rumah berada di dalam kotak scan.',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isProcessing)
                    const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
