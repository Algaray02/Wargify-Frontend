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

class _WargaQrScanScreenState extends State<WargaQrScanScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool isFlashOn = false;
  bool _isProcessingScan = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Viewfinder size
    final double scanWindowSize = 260.0;
    final scanWindow = Rect.fromLTWH(
      (screenWidth - scanWindowSize) / 2,
      (screenHeight - scanWindowSize) / 2 - 30,
      scanWindowSize,
      scanWindowSize,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
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

          // 2. Custom Mask Overlay (darkens area outside viewfinder)
          CustomPaint(
            painter: ScannerOverlayPainter(scanWindow: scanWindow, borderRadius: 24),
            child: const SizedBox.expand(),
          ),

          // 3. Viewfinder Outer Subtle Border
          Positioned(
            left: scanWindow.left,
            top: scanWindow.top,
            width: scanWindow.width,
            height: scanWindow.height,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Corner brackets
                  _buildViewfinderCorner(top: 0, left: 0, isTop: true, isLeft: true),
                  _buildViewfinderCorner(top: 0, right: 0, isTop: true, isLeft: false),
                  _buildViewfinderCorner(bottom: 0, left: 0, isTop: false, isLeft: true),
                  _buildViewfinderCorner(bottom: 0, right: 0, isTop: false, isLeft: false),
                ],
              ),
            ),
          ),

          // 4. Moving Glow Laser Line
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final topOffset = scanWindow.top + 16 + (_animation.value * (scanWindowSize - 36));
              return Positioned(
                top: topOffset,
                left: scanWindow.left + 20,
                width: scanWindow.width - 40,
                height: 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.01),
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.01),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 5. User Interface Floating Layer
          SafeArea(
            child: Column(
              children: [
                // Header Bar (Glassmorphic)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Material(
                          color: Colors.white.withOpacity(0.12),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Scan QR Presensi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Material(
                          color: isFlashOn ? AppColors.primary : Colors.white.withOpacity(0.12),
                          child: InkWell(
                            onTap: () {
                              setState(() => isFlashOn = !isFlashOn);
                              controller.toggleTorch();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                isFlashOn ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Instruction Banner
                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 32, bottom: 48),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pindai QR Presensi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Posisikan QR Code presensi kegiatan di dalam bingkai untuk memproses presensi otomatis.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(12) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(12) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
          ),
        ),
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

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;

  ScannerOverlayPainter({required this.scanWindow, this.borderRadius = 24.0});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        scanWindow,
        Radius.circular(borderRadius),
      ));

    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(path, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

