import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/widgets/warga/warga_header.dart';
import 'package:wargify/widgets/warga/warga_bottom_nav.dart';
import 'package:wargify/widgets/warga/iuran/total_dana_card.dart';
import 'package:wargify/widgets/warga/iuran/iuran_item_card.dart';
import 'package:wargify/screens/warga/home/home_screen.dart';
import 'package:wargify/screens/warga/gallery/gallery_screen.dart';
import 'package:wargify/screens/warga/ronda/ronda_screen.dart';
import 'package:wargify/screens/warga/qr/qr_scanner_screen.dart';

class IuranScreen extends StatefulWidget {
  const IuranScreen({super.key});

  @override
  State<IuranScreen> createState() => _IuranScreenState();
}

class _IuranScreenState extends State<IuranScreen> {
  int _currentNavIndex = 1;

  final String _totalDana = 'Rp 42.500.000';
  final bool _semuaLunas = true;

  final List<Map<String, String>> _daftarIuran = [
    {
      'bulan': 'SEP',
      'tanggal': '02',
      'judul': 'Monthly Iuran - September',
      'status': 'Lunas',
      'jumlah': 'Rp 50.000',
    },
    {
      'bulan': 'AUG',
      'tanggal': '05',
      'judul': 'Monthly Iuran - August',
      'status': 'Lunas',
      'jumlah': 'Rp 50.000',
    },
    {
      'bulan': 'JUL',
      'tanggal': '12',
      'judul': 'Monthly Iuran - Juli',
      'status': 'Lunas',
      'jumlah': 'Rp 50.000',
    },
    {
      'bulan': 'JUL',
      'tanggal': '01',
      'judul': 'Monthly Iuran - July',
      'status': 'Lunas',
      'jumlah': 'Rp 150.000',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: WargaHeader(onNotificationTap: () {}),
      bottomNavigationBar: WargaBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WargaHomeScreen()),
            );
            return;
          }
          if (index == 2) {
            Navigator.push(
              // ← push bukan pushReplacement
              context,
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            );
            return;
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GalleryScreen()),
            );
            return;
          }
          if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RondaScreen()),
            );
            return;
          }

          setState(() => _currentNavIndex = index);
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Detail Iuran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monthly neighborhood contribution and financial transparency.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (_semuaLunas)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4EDDA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SEMUA IURAN LUNAS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            TotalDanaCard(totalDana: _totalDana),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Iuran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tune,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Filter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _daftarIuran.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _daftarIuran[index];
                return IuranItemCard(
                  bulan: item['bulan'] ?? '',
                  tanggal: item['tanggal'] ?? '',
                  judul: item['judul'] ?? '',
                  status: item['status'] ?? '',
                  jumlah: item['jumlah'] ?? '',
                  onTap: () {},
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Lebih Banyak',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
