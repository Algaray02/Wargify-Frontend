import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/screens/warga/pages/home_page.dart';
import 'package:wargify/screens/warga/pages/iuran_page.dart';
import 'package:wargify/widgets/warga/warga_header.dart';
import 'package:wargify/widgets/warga/warga_bottom_nav.dart';
import 'package:wargify/widgets/warga/gallery/gallery_filter_chip.dart';
import 'package:wargify/widgets/warga/gallery/gallery_group_section.dart';
import 'package:wargify/screens/warga/pages/ronda_page.dart';
import 'package:wargify/screens/warga/pages/qr_scanner_page.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _currentNavIndex = 3; // gallery = index 3
  String _activeFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'Semua',
    'Festival',
    'Kegiatan Sosial',
    'Ronda',
    'Rapat',
  ];

  // --- Dummy Data ---
  final List<Map<String, dynamic>> _galleryGroups = [
    {
      'judul': 'HUT RI 79',
      'tanggal': '17 Agustus 2024',
      'kategori': 'Festival',
      'imageUrls': [
        'https://picsum.photos/300/200',
        'https://picsum.photos/301/200',
        'https://picsum.photos/302/200',
        'https://picsum.photos/303/200',
      ], // 4 foto
    },
    {
      'judul': 'Kerja Bakti Minggu',
      'tanggal': '12 September 2024',
      'kategori': 'Kegiatan Sosial',
      'imageUrls': [
        'https://apps.codepolitan.com/sites/learn/uploads/original/202308/salammeme.png',
        'https://picsum.photos/303/200',
        'https://picsum.photos/304/200',
      ], // 3 foto
    },
  ];

  List<Map<String, dynamic>> get _filteredGroups {
    if (_activeFilter == 'Semua') return _galleryGroups;
    return _galleryGroups.where((g) => g['kategori'] == _activeFilter).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: WargaHeader(
        onNotificationTap: () {
          // TODO: navigate to notifications
        },
      ),
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
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const IuranScreen()),
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
            const SizedBox(height: 12),

            // --- Search Bar ---
            Container(
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari kenangan warga...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // --- Filter Chips ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GalleryFilterChip(
                      label: filter,
                      isActive: _activeFilter == filter,
                      onTap: () => setState(() => _activeFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // --- Gallery Groups ---
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredGroups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 28),
              itemBuilder: (context, index) {
                final group = _filteredGroups[index];
                return GalleryGroupSection(
                  judul: group['judul'] ?? '',
                  tanggal: group['tanggal'] ?? '',
                  imageUrls: List<String>.from(group['imageUrls'] ?? []),
                  onFotoTap: () {
                    // TODO: navigate to foto detail
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
