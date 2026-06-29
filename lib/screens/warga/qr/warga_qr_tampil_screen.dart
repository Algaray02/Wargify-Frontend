import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/auth/auth_service.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/models/user_model.dart';

class WargaQrTampilScreen extends StatefulWidget {
  final bool isFamilyQr;
  const WargaQrTampilScreen({super.key, this.isFamilyQr = true});

  @override
  State<WargaQrTampilScreen> createState() => _WargaQrTampilScreenState();
}

class _WargaQrTampilScreenState extends State<WargaQrTampilScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  UserModel? _currentUser;
  Map<String, dynamic>? _profileData;
  late bool _isFamilyQr;

  @override
  void initState() {
    super.initState();
    _isFamilyQr = widget.isFamilyQr;
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

  Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _currentUser?.fullName ?? 'Memuat...';
    final family = _asMap(_profileData?['family']);
    final household = _asMap(family?['household']);

    final rawFamilyId = family?['family_id']?.toString() ?? family?['id']?.toString();
    final familyId = rawFamilyId?.replaceAll(RegExp(r'\s+'), '').trim();

    final rawHouseholdQr = household?['qr_code_data']?.toString();
    final householdQr = rawHouseholdQr?.replaceAll(RegExp(r'\s+'), '').trim();

    final String displayCode;
    final bool hasCode;
    final String badgeLabel;
    final String cardTitle;
    final String description;
    final String bottomDescription;

    if (_isFamilyQr) {
      displayCode = (familyId != null && familyId.isNotEmpty) ? familyId : 'QR-FAMILY-BELUM-TERSEDIA';
      hasCode = familyId != null && familyId.isNotEmpty;
      badgeLabel = 'QR FAMILY';
      cardTitle = 'QR Family';
      description = hasCode
          ? 'Tunjukkan QR ini ke pengurus RT untuk konfirmasi iuran bulanan'
          : 'Family belum terhubung, QR family belum tersedia';
      bottomDescription = hasCode
          ? 'QR ini digunakan untuk verifikasi family dan iuran'
          : 'Lengkapi data family agar QR bisa digunakan';
    } else {
      displayCode = (householdQr != null && householdQr.isNotEmpty) ? householdQr : 'QR-RUMAH-BELUM-TERSEDIA';
      hasCode = householdQr != null && householdQr.isNotEmpty;
      badgeLabel = 'QR RUMAH';
      cardTitle = 'QR Rumah';
      description = hasCode
          ? 'Tunjukkan QR ini ke petugas/RT untuk konfirmasi data hunian'
          : 'Data hunian belum terhubung, QR rumah belum tersedia';
      bottomDescription = hasCode
          ? 'QR ini digunakan untuk verifikasi data rumah/tempat tinggal'
          : 'Lengkapi data hunian agar QR bisa digunakan';
    }

    final blockNumber = household?['block_number']?.toString();
    final houseNumber = household?['house_number']?.toString();
    final householdLabel = [
      if (blockNumber != null && blockNumber.isNotEmpty) 'Blok $blockNumber',
      if (houseNumber != null && houseNumber.isNotEmpty) 'No. $houseNumber',
    ].join(' / ');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Curved Background Circles
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
          SafeArea(
            child: Column(
              children: [
                // Header
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
                        'My QR Code',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                  badgeLabel,
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
                            cardTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
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
                                    data: displayCode,
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
                                // Container(
                                //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                //   decoration: BoxDecoration(
                                //     color: AppColors.primary.withOpacity(0.2),
                                //     borderRadius: BorderRadius.circular(10),
                                //   ),
                                //   child: Text(
                                //     displayCode,
                                //     style: GoogleFonts.plusJakartaSans(
                                //       fontSize: 12,
                                //       fontWeight: FontWeight.w600,
                                //       color: Colors.blue[100],
                                //       letterSpacing: 1,
                                //     ),
                                //   ),
                                // ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.info_outline, size: 13, color: Colors.white38),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        bottomDescription,
                                        textAlign: Navigator.canPop(context) ? TextAlign.start : TextAlign.center,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
