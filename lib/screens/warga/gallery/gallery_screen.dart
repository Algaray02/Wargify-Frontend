import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/widgets/common/gallery/gallery_filter_chip.dart';
import 'package:wargify/widgets/common/gallery/gallery_group_section.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ApiService _apiService = ApiService();
  String _activeFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _search = '';
  List<Map<String, dynamic>> _galleries = [];

  @override
  void initState() {
    super.initState();
    _fetchGalleries();
  }

  Future<void> _fetchGalleries() async {
    try {
      final rows = await _apiService.getList(ApiEndpoints.galleries);
      if (!mounted) return;
      setState(() {
        _galleries = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _filters {
    final labels =
        _galleries
            .map(
              (gallery) =>
                  _activityTypeLabel(_activityMap(gallery)['type']?.toString()),
            )
            .toSet()
            .toList()
          ..sort();
    return ['Semua', ...labels];
  }

  List<Map<String, dynamic>> get _filteredGroups {
    final keyword = _search.trim().toLowerCase();
    return _galleries.where((gallery) {
      final activity = _activityMap(gallery);
      final typeLabel = _activityTypeLabel(activity['type']?.toString());
      final matchesFilter =
          _activeFilter == 'Semua' || typeLabel == _activeFilter;
      final matchesSearch =
          keyword.isEmpty ||
          [
            gallery['album_name'],
            gallery['event_date'],
            activity['title'],
            activity['location_name'],
            typeLabel,
          ].any((value) => '$value'.toLowerCase().contains(keyword));
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _formatDate(String? value) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  List<String> _imageUrls(Map<String, dynamic> gallery) {
    final images = gallery['images'];
    if (images is! List) return const [];
    return images
        .whereType<Map>()
        .map((image) => image['image_url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }

  String _subtitle(Map<String, dynamic> gallery, int photoCount) {
    final activity = _activityMap(gallery);
    final typeLabel = _activityTypeLabel(activity['type']?.toString());
    final location = activity['location_name']?.toString() ?? '';
    final locationText = location.isEmpty ? '' : ' • $location';
    return '${_formatDate(gallery['event_date']?.toString())} • $typeLabel$locationText • $photoCount Foto';
  }

  void _showPhotoPreview(List<String> urls, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            color: Colors.black,
            height: MediaQuery.of(context).size.height * 0.62,
            child: PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: urls.length,
              itemBuilder: (context, index) => InteractiveViewer(
                child: Image.network(
                  urls[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _fetchGalleries,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                onChanged: (value) => setState(() => _search = value),
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

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredGroups.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredGroups.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 28),
                itemBuilder: (context, index) {
                  final group = _filteredGroups[index];
                  final images = _imageUrls(group);
                  return GalleryGroupSection(
                    judul: group['album_name']?.toString() ?? 'Album',
                    tanggal: _subtitle(group, images.length),
                    imageUrls: images,
                    onFotoTap: images.isEmpty
                        ? null
                        : (photoIndex) => _showPhotoPreview(images, photoIndex),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.photo_library_outlined,
              color: AppColors.primary,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada galeri yang cocok.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
