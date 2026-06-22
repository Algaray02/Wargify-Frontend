import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:dio/dio.dart';

class WargaQrScanScreen extends StatefulWidget {
  const WargaQrScanScreen({super.key});

  @override
  State<WargaQrScanScreen> createState() => _WargaQrScanScreenState();
}

class _WargaQrScanScreenState extends State<WargaQrScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isFlashOn = false;
  bool _isProcessingScan = false;

  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            errorBuilder: (context, error, child) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.error_outline, color: Colors.white, size: 60),
                  SizedBox(height: 16),
                  Text('Kamera tidak dapat diakses.\nPastikan izin kamera sudah diberikan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _handleScannedCode(barcodes.first.rawValue);
              }
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(isFlashOn ? Icons.flashlight_off : Icons.flashlight_on, color: Colors.white),
                    onPressed: () {
                      setState(() => isFlashOn = !isFlashOn);
                      controller.toggleTorch();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScannedCode(String? code) async {
    final scanned = code?.replaceAll(RegExp(r'\s+'), '').trim();
    if (scanned == null || scanned.isEmpty || _isProcessingScan) return;
    setState(() => _isProcessingScan = true);
    await controller.stop();
    try {
      final result = await _apiService.post(ApiEndpoints.qrScan, {'code': scanned});
      if (!mounted) return;
      await _showScanResultDialog(result);
    } on DioException catch (e) {
      final message = e.response?.data is Map ? (e.response?.data['message']?.toString() ?? 'QR gagal diproses.') : 'QR gagal diproses.';
      if (!mounted) return;
      await _showScanErrorDialog(message);
    } catch (_) {
      if (!mounted) return;
      await _showScanErrorDialog('Terjadi kesalahan saat memproses QR.');
    } finally {
      if (mounted) setState(() => _isProcessingScan = false);
    }
  }

  Future<void> _showScanResultDialog(Map<String, dynamic> result) async {
    final type = result['type']?.toString();
    final message = result['message']?.toString() ?? 'QR berhasil diproses.';
    final isIuran = type == 'iuran';
    final title = isIuran ? 'Iuran Tercatat' : 'Presensi Berhasil';
    final icon = isIuran ? Icons.payments_rounded : Icons.check_circle;
    final details = isIuran
        ? [
            _detailLine('Periode', result['period_name']),
            _detailLine('Pembayar', result['payer_name']),
            _detailLine('Nominal', _formatRupiah(result['amount_paid'])),
          ]
        : [
            _detailLine('Kegiatan', result['activity_title']),
            _detailLine('Peserta', result['attendee_name']),
          ];
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(icon, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          const SizedBox(height: 14),
          ...details,
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); controller.start(); },
            child: Text('Scan Lagi', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Selesai', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showScanErrorDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: const [
          Icon(Icons.error_outline, color: AppColors.danger),
          SizedBox(width: 8),
          Expanded(child: Text('QR Tidak Valid', style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
        content: Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); controller.start(); },
            child: Text('Scan Lagi', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Selesai', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  String _formatRupiah(Object? value) {
    final amount = value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
    final raw = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final rev = raw.length - i;
      buffer.write(raw[i]);
      if (rev > 1 && rev % 3 == 1) buffer.write('.');
    }
    return 'Rp $buffer';
  }
}

