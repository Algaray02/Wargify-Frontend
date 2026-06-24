import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isFlashOn = false;
  bool _isProcessingScan = false;

  final _apiService = ApiService();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // 🌟 HELPER REGEX: Memvalidasi apakah kode yang dipindai adalah UUID murni yang sah
  bool _isValidUuid(String str) {
    final regExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return regExp.hasMatch(str);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Match dark premium background of RT/Bendahara
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(
            controller: controller,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kamera tidak dapat diakses.\nPastikan izin kamera sudah diberikan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _handleScannedCode(barcodes.first.rawValue);
              }
            },
          ),

          // 2. Curved Background Circles
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 40,
                ),
              ),
            ),
          ),

          // 3. UI Layer floating on top
          SafeArea(
            child: Column(
              children: [
                // Header (Sama persis RT)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Scan QR Warga',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),
                // Scanner Mode Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC1F3AF).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.payments_rounded,
                        size: 18,
                        color: Color(0xFF2A6B2C),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PEMBAYARAN IURAN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2A6B2C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Scan QR Keluarga',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Scan QR keluarga warga untuk menampilkan daftar tunggakan dan memproses iuran.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(flex: 2),

                // Viewfinder
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Stack(
                      children: [
                        _buildCorner(top: 0, left: 0, angle: 0),
                        _buildCorner(top: 0, right: 0, angle: 90),
                        _buildCorner(bottom: 0, left: 0, angle: -90),
                        _buildCorner(bottom: 0, right: 0, angle: 180),

                        // Viewfinder Flash controls
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildControlButton(
                                isFlashOn
                                    ? Icons.flashlight_off_rounded
                                    : Icons.flashlight_on_rounded,
                                onTap: () {
                                  setState(() => isFlashOn = !isFlashOn);
                                  controller.toggleTorch();
                                },
                                isActive: isFlashOn,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BACKEND INTEGRATION
  // =========================================================================
  Future<void> _handleScannedCode(String? code) async {
    // Bersihkan dari spasi atau karakter whitespace ilegal yang tak sengaja terscan
    final scannedCode = code?.replaceAll(RegExp(r'\s+'), '');

    if (scannedCode == null || scannedCode.isEmpty || _isProcessingScan) return;

    setState(() => _isProcessingScan = true);

    await Future.delayed(const Duration(milliseconds: 200));
    await controller.stop();

    // Mengirim langsung string QR (UUID Family) tanpa validasi prefix
    try {
      final response = await _apiService.post(ApiEndpoints.checkArrears, {
        'family_id': scannedCode,
      });

      final dataToPass = response['data'] ?? response;

      if (dataToPass is! Map<String, dynamic>) {
        await _showScanErrorDialog('Format data iuran tidak sesuai.');
        return;
      }

      await _showArrearsBottomSheet(dataToPass);
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ??
                'QR tidak valid atau gagal memeriksa tunggakan.')
          : 'QR tidak valid atau gagal memeriksa tunggakan.';
      if (!mounted) return;
      await _showScanErrorDialog(message);
    } catch (e) {
      if (!mounted) return;
      await _showScanErrorDialog('Terjadi kesalahan memproses data keluarga.');
    } finally {
      if (mounted) setState(() => _isProcessingScan = false);
    }
  }

  Future<void> _showArrearsBottomSheet(Map<String, dynamic> data) {
    final String familyId = data['family_id'] ?? '';
    final List<dynamic> details = data['details'] ?? [];
    final Set<String> selectedPeriods = {};

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double selectedTotal = details
                .where(
                  (item) =>
                      selectedPeriods.contains(item['period_id'].toString()),
                )
                .fold(
                  0,
                  (sum, item) =>
                      sum +
                      (num.tryParse(item['amount']?.toString() ?? '0') ?? 0)
                          .toDouble(),
                );
            final double totalOutstanding = details.fold(
              0,
              (sum, item) =>
                  sum +
                  (num.tryParse(item['amount']?.toString() ?? '0') ?? 0)
                      .toDouble(),
            );

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tagihan Iuran Warga',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kode KK: ${data['family_id']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  if (details.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          '🎉 Semua iuran keluarga ini LUNAS!',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Tunggakan Kumulatif:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              if (selectedPeriods.length == details.length) {
                                selectedPeriods.clear();
                              } else {
                                selectedPeriods.addAll(
                                  details.map((e) => e['period_id'].toString()),
                                );
                              }
                            });
                          },
                          child: Text(
                            selectedPeriods.length == details.length
                                ? 'Batal Semua'
                                : 'Pilih Semua',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: details.length,
                        itemBuilder: (context, index) {
                          final item = details[index];
                          final periodId = item['period_id'].toString();
                          final isSelected = selectedPeriods.contains(periodId);

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedPeriods.remove(periodId);
                                } else {
                                  selectedPeriods.add(periodId);
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.white24,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['period_name'] ?? '',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          item['category_name'] ?? '',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatRupiah(item['amount']),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.amber[200],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Outstanding:',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatRupiah(totalOutstanding),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Dipilih:',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _formatRupiah(selectedTotal),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            controller.start();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (details.isNotEmpty)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedPeriods.isEmpty
                                ? null
                                : () async {
                                    Navigator.pop(context);
                                    _processDirectPayment(
                                      selectedPeriods.toList(),
                                      data['family_id'],
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: Colors.white10,
                              disabledForegroundColor: Colors.white38,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Bayar Sekarang',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processDirectPayment(
    List<String> targetPeriodIds,
    String familyId,
  ) async {
    setState(() => _isProcessingScan = true);
    try {
      await _apiService.post(ApiEndpoints.processIuranPayments, {
        'family_id': familyId,
        'selected_periods': targetPeriodIds,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sukses! Pembayaran iuran terpilih berhasil dicatat.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showScanErrorDialog('Gagal memproses transaksi pembayaran massal.');
    } finally {
      if (mounted) {
        setState(() => _isProcessingScan = false);
        controller.start();
      }
    }
  }

  Future<void> _showScanErrorDialog(String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'QR Tidak Valid',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.start();
            },
            child: Text(
              'Scan Lagi',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Selesai',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(Object? value) {
    final amount = value is num
        ? value
        : num.tryParse(value?.toString() ?? '') ?? 0;
    final raw = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp $buffer';
  }

  Widget _buildCorner({
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
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 4),
              left: BorderSide(color: AppColors.primary, width: 4),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon, {
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFF0D1B2A),
          size: 24,
        ),
      ),
    );
  }
}
