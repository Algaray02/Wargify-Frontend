import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'add_gallery_screen.dart';
import 'edit_gallery_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _galleries = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchGalleries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGalleries() async {
    try {
      final rows = await _apiService.getList(ApiEndpoints.galleries);
      if (!mounted) return;
      setState(() {
        _galleries = rows
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredGalleries {
    final keyword = _search.trim().toLowerCase();
    if (keyword.isEmpty) return _galleries;
    return _galleries.where((gallery) {
      final activity = _activityMap(gallery);
      return [
        gallery['album_name'],
        activity['title'],
        activity['location_name'],
        _activityTypeLabel(activity['type']?.toString()),
      ].any((value) => '$value'.toLowerCase().contains(keyword));
    }).toList();
  }

  int get _totalPhotos {
    return _galleries.fold(0, (sum, gallery) {
      final images = gallery['images'];
      return sum + (images is List ? images.length : 0);
    });
  }

  String _formatDate(String? value) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  List<String> _imageUrls(Map<String, dynamic> gallery) {
    final images = gallery['images'];
    if (images is! List) return const [];
    return images
        .map(
          (image) =>
              Map<String, dynamic>.from(
                image as Map,
              )['image_url']?.toString() ??
              '',
        )
        .where((url) => url.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _activityMap(Map<String, dynamic> gallery) {
    final activity = gallery['activity'];
    if (activity is Map) return Map<String, dynamic>.from(activity);
    return {};
  }

  String _activityTypeLabel(String? type) {
    switch (type) {
      case 'RAPAT':
        return 'Rapat';
      case 'KEGIATAN_UMUM':
        return 'Kegiatan Umum';
      default:
        return 'Album Mandiri';
    }
  }

  String _gallerySubtitle(Map<String, dynamic> gallery, int photoCount) {
    final activity = _activityMap(gallery);
    final date = _formatDate(gallery['event_date']?.toString());
    final typeLabel = _activityTypeLabel(activity['type']?.toString());
    final location = activity['location_name']?.toString() ?? '';
    final locationText = location.isEmpty ? '' : ' • $location';
    return '$date • $typeLabel$locationText • $photoCount Foto';
  }

  void _showPhotoPreview(List<String> urls, int initialIndex, String title) {
    if (urls.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        urls[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                              size: 48,
                            ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGalleries;

    return RefreshIndicator(
      onRefresh: _fetchGalleries,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'TOTAL ALBUM',
                    value: _galleries.length.toString(),
                    icon: Icons.collections_bookmark_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    label: 'TOTAL FOTO',
                    value: _totalPhotos.toString(),
                    icon: Icons.photo_library_outlined,
                    valueColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddGalleryScreen(),
                    ),
                  );
                  _fetchGalleries();
                },
                icon: const Icon(Icons.add_circle, size: 24),
                label: Text(
                  'Tambah Galeri Baru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: 'Cari album, kegiatan, atau lokasi...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[500],
                  ),
                  icon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              _buildEmptyState()
            else
              ...filtered.map((gallery) {
                final images = _imageUrls(gallery);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: _buildGallerySection(
                    context,
                    gallery: gallery,
                    title: gallery['album_name']?.toString() ?? 'Album',
                    date: _gallerySubtitle(gallery, images.length),
                    images: images,
                  ),
                );
              }),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? const Color(0xFF0D1B2A),
                ),
              ),
              Icon(icon, color: Colors.grey[300], size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          'Belum ada galeri yang cocok.',
          style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildGallerySection(
    BuildContext context, {
    required Map<String, dynamic> gallery,
    required String title,
    required String date,
    required List<String> images,
  }) {
    final previewImages = images.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, size: 28),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditGalleryScreen(gallery: gallery),
                  ),
                );
                _fetchGalleries();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (previewImages.isEmpty)
          Container(
            height: 140,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Belum ada foto',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: previewImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showPhotoPreview(images, index, title),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        previewImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE5EEF5),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.open_in_full_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
