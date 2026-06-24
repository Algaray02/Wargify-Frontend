import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/auth/auth_service.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/models/user_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isFlashOn = false;
  bool isModeScan = true; // true = scan, false = tampil QR
  bool _isProcessingScan = false;

  final _authService = AuthService();
  final _apiService = ApiService();
  UserModel? _currentUser;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final profile = await _apiService.getMap(ApiEndpoints.me);
      final user = UserModel.fromJson(profile);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _profileData = profile;
        });
      }
    } catch (e) {
      final cachedUser = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = cachedUser;
        });
      }
    }
  }

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
          // 1. Camera View (Only in Scan Mode)
          if (isModeScan)
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

          // 2. Tampil QR Mode Screen
          if (!isModeScan) _buildTampilQrScreen(),

          // 3. Curved Background Circles (Matches RT layout ornament)
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

          // 4. UI Layer floating on top
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
                        isModeScan ? 'Scan QR' : 'My QR Code',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isModeScan) ...[
                  const Spacer(flex: 1),
                  // Attendance Mode Badge (Sama persis RT)
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
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: Color(0xFF2A6B2C),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SCAN PRESENSI / IURAN',
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
                    'Scan QR',
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
                      'Scan QR presensi kegiatan atau QR family untuk mencatat iuran bulanan',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),

                  // Viewfinder (Sama persis RT)
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
                ] else ...[
                  const Spacer(),
                ],

                // Toggle Mode Selector (Glassmorphic & Premium)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 30,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isModeScan = true),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isModeScan
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Mode Scan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isModeScan = false),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: !isModeScan
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Mode Tampil',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay saat memproses data API
          if (_isProcessingScan)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // METHOD 1: GENERATE & TAMPILKAN QR CODE WARGA (MURNI VALUE UUID FAMILY_ID)
  // =========================================================================
  Widget _buildTampilQrScreen() {
    final displayName = _currentUser?.fullName ?? 'Memuat...';
    final family = _asMap(_profileData?['family']);
    final household = _asMap(family?['household']);
    
    // 🌟 PERBAIKAN 1: Ambil family_id, ubah ke String, lalu bersihkan secara total dari spasi, tab, enter (\n)
    final rawFamilyId = family?['family_id']?.toString() ?? family?['id']?.toString();
    final familyId = rawFamilyId?.replaceAll(RegExp(r'\s+'), '').trim();

    // 🌟 PERBAIKAN 2: Sesuai permintaan, QR Code kini murni berisi nilai family_id (UUID) saja tanpa prefix teks!
    final displayCode = (familyId != null && familyId.isNotEmpty)
        ? familyId
        : 'QR-FAMILY-BELUM-TERSEDIA';

    final blockNumber = household?['block_number']?.toString();
    final houseNumber = household?['house_number']?.toString();
    final householdLabel = [
      if (blockNumber != null && blockNumber.isNotEmpty) 'Blok $blockNumber',
      if (houseNumber != null && houseNumber.isNotEmpty) 'No. $houseNumber',
    ].join(' / ');
    final hasFamilyQr = familyId != null && familyId.isNotEmpty;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'QR FAMILY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[300],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'QR Family',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasFamilyQr
                    ? 'Tunjukkan QR ini ke pengurus RT untuk konfirmasi iuran bulanan'
                    : 'Family belum terhubung, QR family belum tersedia',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // Premium QR Glass Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      householdLabel.isNotEmpty
                          ? householdLabel
                          : 'Data family belum lengkap',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // QR Image Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: QrImageView(
                        data: displayCode, // 🌟 Menghasilkan QR Code murni UUID sebaris lurus!
                        version: QrVersions.auto,
                        size: 180,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dynamic ID Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        displayCode,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[100],
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 13,
                          color: Colors.white38,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hasFamilyQr
                                ? 'QR ini digunakan untuk verifikasi family dan iuran'
                                : 'Lengkapi data family agar QR bisa digunakan',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // METHOD 2: HANDLER PEMINDAIAN KAMERA (CLEAN & ANTI ERROR)
  // =========================================================================
  Future<void> _handleScannedCode(String? code) async {
    // 🌟 PERBAIKAN 3: Bersihkan seluruh teks QR dari spasi, enter (\n) yang merusak parsing UUID
    final scannedCode = code?.replaceAll(RegExp(r'\s+'), '').trim();
    if (scannedCode == null || scannedCode.isEmpty || _isProcessingScan) return;

    setState(() => _isProcessingScan = true);
    await controller.stop();

    // 🌟 PERBAIKAN 4: Deteksi format secara adaptif (Mendukung UUID murni maupun prefix lama)
    bool isFamilyQr = _isValidUuid(scannedCode) || 
                      scannedCode.startsWith('family_id:') || 
                      scannedCode.startsWith('family_id');

    if (isFamilyQr) {
      String cleanFamilyId = scannedCode;
      
      // Potong prefix jika pengurus tidak sengaja memindai format lama
      if (scannedCode.startsWith('family_id:')) {
        cleanFamilyId = scannedCode.substring('family_id:'.length).trim();
      } else if (scannedCode.startsWith('family_id')) {
        cleanFamilyId = scannedCode.replaceAll('family_id', '').replaceAll(':', '').trim();
      }

      print("Parsed Family ID untuk checkArrears: $cleanFamilyId");

      try {
        // Tembak API check arrears menggunakan key 'family_id' sesuai spesifikasi Laravel baru
        final response = await _apiService.post(ApiEndpoints.checkArrears, {
          'family_id': cleanFamilyId,
        });

        // 🌟 SAFETY CHECK: Pastikan API mengembalikan data sukses sebelum membuka bottom sheet
        if (response != null && response['success'] == true && response['data'] != null) {
          if (!mounted) return;
          await _showArrearsBottomSheet(response['data']);
        } else {
          // Tampilkan pesan eror asli yang dilempar oleh Laravel backend!
          final message = response?['message']?.toString() ?? 'Gagal memeriksa tunggakan iuran.';
          if (!mounted) return;
          await _showScanErrorDialog(message);
        }
      } on DioException catch (e) {
        // 🌟 PRINT DEBUG SANGAT DETIL: Mengeluarkan kode eror HTTP asli di popup dialog biar gampang dibaca!
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        String message = 'Gagal memeriksa tunggakan iuran.';

        // Print prominently to the console so Vian can see it in terminal!
        debugPrint("🚨🚨🚨 [API ERROR DETECTED] 🚨🚨🚨");
        debugPrint("Path: ${e.requestOptions.path}");
        debugPrint("Status Code: $statusCode");
        debugPrint("Error Type: ${e.type}");
        debugPrint("Response Type: ${responseData?.runtimeType}");
        debugPrint("Raw Response: $responseData");
        debugPrint("🚨🚨🚨================================🚨🚨🚨");

        if (e.response == null) {
          message = "Koneksi Bermasalah:\nTidak dapat terhubung ke server Laravel di IP ${ApiEndpoints.baseUrl}. Pastikan laptop dan HP tersambung di Wi-Fi yang SAMA.\nDetail: ${e.message}";
        } else {
          String errorDetail = '';
          if (responseData is Map) {
            errorDetail = responseData['message']?.toString() ?? responseData.toString();
          } else if (responseData is String) {
            // Jika respons berupa HTML (Eror khas Laravel), ambil judul HTML-nya agar jelas terbaca
            if (responseData.contains('<title>')) {
              final start = responseData.indexOf('<title>') + 7;
              final end = responseData.indexOf('</title>');
              if (end > start) {
                errorDetail = responseData.substring(start, end).trim();
              }
            }
            if (errorDetail.isEmpty) {
              errorDetail = responseData.length > 200 
                  ? "${responseData.substring(0, 200)}..." 
                  : responseData;
            }
          } else {
            errorDetail = responseData?.toString() ?? e.message ?? 'Unknown Error';
          }

          message = "Error $statusCode (${e.type.toString().split('.').last}):\n$errorDetail";
        }

        if (!mounted) return;
        await _showScanErrorDialog(message);
      } catch (e, stack) {
        // 🌟 PRINT DEBUG: Cetak detail crash log jika ada tipe data yang tidak cocok di Flutter
        debugPrint("CRASH LOG FLUTTER DETECTED: $e");
        debugPrint("STACKTRACE: $stack");
        if (!mounted) return;
        await _showScanErrorDialog('Terjadi kesalahan internal aplikasi: $e');
      } finally {
        if (mounted) {
          setState(() => _isProcessingScan = false);
        }
      }
    } else {
      // Jalankan skenario pemindaian umum (seperti Presensi Kegiatan/Ronda)
      try {
        final result = await _apiService.post(ApiEndpoints.qrScan, {
          'code': scannedCode,
        });

        if (!mounted) return;
        await _showScanResultDialog(result);
      } on DioException catch (e) {
        final message = e.response?.data is Map
            ? (e.response?.data['message']?.toString() ?? 'QR gagal diproses.')
            : 'QR gagal diproses.';

        if (!mounted) return;
        await _showScanErrorDialog(message);
      } catch (e) {
        if (!mounted) return;
        await _showScanErrorDialog('Terjadi kesalahan saat memproses QR: $e');
      } finally {
        if (mounted) {
          setState(() => _isProcessingScan = false);
        }
      }
    }
  }

  // =========================================================================
  // INTERAKTIF CHECKLIST DI BOTTOM SHEET & PROSES TRANSAKSI MASAL
  // =========================================================================
  Future<void> _showArrearsBottomSheet(Map<String, dynamic> data) {
    final String familyId = data['family_id'] ?? '';
    final List<dynamic> details = data['details'] ?? [];

    List<dynamic> selectedPeriodIds = details.map((item) => item['period_id']).toList();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            
            double totalTerpilih = 0;
            for (var item in details) {
              if (selectedPeriodIds.contains(item['period_id'])) {
                totalTerpilih += (item['amount'] as num).toDouble();
              }
            }

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
                      const Icon(Icons.admin_panel_settings_rounded, color: Colors.blue, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Tagihan Iuran Warga',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kode Teks QR: ${data['qr_code_data'] ?? '-'}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white54),
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
                    Text(
                      'Pilih komponen iuran yang dibayar tunai:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: details.length,
                        itemBuilder: (context, index) {
                          final item = details[index];
                          final periodId = item['period_id'];
                          final bool isChecked = selectedPeriodIds.contains(periodId);

                          return Theme(
                            data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white30),
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: Colors.blue,
                              checkColor: Colors.white,
                              value: isChecked,
                              onChanged: (bool? val) {
                                setSheetState(() {
                                  if (val == true) {
                                    selectedPeriodIds.add(periodId);
                                  } else {
                                    selectedPeriodIds.remove(periodId);
                                  }
                                });
                              },
                              title: Text(
                                item['period_name'] ?? '',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                item['category_name'] ?? '',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                              secondary: Text(
                                _formatRupiah(item['amount']),
                                style: GoogleFonts.plusJakartaSans(
                                  color: isChecked ? Colors.amber[200] : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
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
                        'Total Terpilih:',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        _formatRupiah(totalTerpilih),
                        style: GoogleFonts.plusJakartaSans(
                          color: totalTerpilih > 0 ? Colors.greenAccent : Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedPeriodIds.isEmpty
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  _processSelectedPayments(familyId, selectedPeriodIds);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.white10,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Catat Pembayaran (${selectedPeriodIds.length})',
                            style: GoogleFonts.plusJakartaSans(
                              color: selectedPeriodIds.isEmpty ? Colors.white30 : Colors.white,
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

  // MENEMBAK API PROCESS-PAYMENT CICILAN MASSAL
  Future<void> _processSelectedPayments(String familyId, List<dynamic> periodIds) async {
    setState(() => _isProcessingScan = true);
    try {
      // 🌟 Menggunakan Endpoint ApiEndpoints.makePayment yang sinkron dengan Laravel baru Anda
      final response = await _apiService.post(ApiEndpoints.makePayment, {
        'family_id': familyId,
        'selected_periods': periodIds,
      });

      if (!mounted) return;
      
      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Sukses mencatat pembayaran warga! 🎉'),
            backgroundColor: Colors.green[800],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showScanErrorDialog('Gagal memproses transaksi pembayaran massal.');
    } finally {
      if (mounted) {
        setState(() => _isProcessingScan = false);
        controller.start();
      }
    }
  }

  Future<void> _showScanResultDialog(Map<String, dynamic> result) {
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

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            const SizedBox(height: 14),
            ...details,
          ],
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

  Widget _detailLine(String label, Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
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

  Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
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