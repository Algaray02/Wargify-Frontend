import 'package:wargify/core/utils/app_error.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/services/api_service.dart';
import 'add_pengumuman_screen.dart';
import 'detail_pengumuman_screen.dart';
import 'edit_pengumuman_screen.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String type; // Penting, Kegiatan, Himbauan, Keuangan, Lainnya
  final String
  targetAudience; // Semua Warga, Kepala Keluarga, Kelompok Ronda, Pengurus RT
  final String status; // Aktif, Draft, Terjadwal
  final String date;
  final String author;
  final String? bannerUrl;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.targetAudience,
    required this.status,
    required this.date,
    required this.author,
    this.bannerUrl,
  });

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    String? targetAudience,
    String? status,
    String? date,
    String? author,
    String? bannerUrl,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      targetAudience: targetAudience ?? this.targetAudience,
      status: status ?? this.status,
      date: date ?? this.date,
      author: author ?? this.author,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }
}

class PengumumanScreen extends StatefulWidget {
  final UserModel user;
  const PengumumanScreen({super.key, required this.user});

  @override
  State<PengumumanScreen> createState() => _PengumumanScreenState();
}

class _PengumumanScreenState extends State<PengumumanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  String _selectedTab = 'Semua';
  String _searchQuery = '';
  bool _isLoading = true;

  final List<Announcement> _announcements = [];

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final rows = await _apiService.getList(ApiEndpoints.announcements);
      final formatter = DateFormat('dd MMM yyyy');
      final items = rows.map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        final creator = Map<String, dynamic>.from(
          (data['creator'] ?? {}) as Map,
        );
        final status = data['status'] == 'PUBLISHED' ? 'Aktif' : 'Draft';
        final activity = data['activity'];
        final title = data['title']?.toString() ?? 'Pengumuman';
        final category = data['category']?.toString();

        return Announcement(
          id: data['announcement_id']?.toString() ?? '',
          title: title,
          content: data['content']?.toString() ?? '',
          type:
              _categoryLabel(category) ??
              (activity != null
                  ? 'Kegiatan'
                  : title.toLowerCase().contains('iuran')
                  ? 'Keuangan'
                  : 'Himbauan'),
          targetAudience: 'Semua Warga',
          status: status,
          date: formatter.format(
            DateTime.tryParse('${data['created_at']}') ?? DateTime.now(),
          ),
          author: creator['full_name']?.toString() ?? widget.user.fullName,
          bannerUrl: data['banner_url']?.toString(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _announcements
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _categoryLabel(String? code) {
    switch (code) {
      case 'PENTING':
        return 'Penting';
      case 'KEGIATAN':
        return 'Kegiatan';
      case 'HIMBAUAN':
        return 'Himbauan';
      case 'KEUANGAN':
        return 'Keuangan';
      case 'LAINNYA':
        return 'Lainnya';
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Announcement> _getFilteredAnnouncements() {
    return _announcements.where((announcement) {
      // 1. Status Filter
      if (_selectedTab != 'Semua' && announcement.status != _selectedTab) {
        return false;
      }
      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = announcement.title.toLowerCase().contains(query);
        final matchesContent = announcement.content.toLowerCase().contains(
          query,
        );
        final matchesType = announcement.type.toLowerCase().contains(query);
        return matchesTitle || matchesContent || matchesType;
      }
      return true;
    }).toList();
  }

  Future<void> _publishAnnouncement(Announcement announcement) async {
    if (announcement.id.isEmpty) return;
    try {
      await _apiService.post(
        '${ApiEndpoints.announcements}/${announcement.id}/publish',
        {},
      );
      await _fetchAnnouncements();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengumuman berhasil diterbitkan ke semua warga.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menerbitkan pengumuman: ${AppError.userFriendly(error)}',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    if (announcement.id.isEmpty || announcement.status != 'Draft') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Hapus draf?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Draf "${announcement.title}" akan dihapus permanen.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.delete(
        '${ApiEndpoints.announcements}/${announcement.id}',
      );
      await _fetchAnnouncements();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Draf pengumuman berhasil dihapus.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus draf: ${AppError.userFriendly(error)}',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _openEditAnnouncement(Announcement announcement) async {
    final result = await Navigator.push<Announcement>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPengumumanScreen(announcement: announcement),
      ),
    );
    if (result != null) {
      await _fetchAnnouncements();
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Penting':
        return AppColors.danger;
      case 'Kegiatan':
        return AppColors.primary;
      case 'Himbauan':
        return const Color(0xFFE65100); // Premium Orange
      case 'Keuangan':
        return AppColors.success;
      default:
        return Colors.grey[700]!;
    }
  }

  Color _getTypeBgColor(String type) {
    switch (type) {
      case 'Penting':
        return AppColors.danger.withOpacity(0.1);
      case 'Kegiatan':
        return AppColors.primary.withOpacity(0.1);
      case 'Himbauan':
        return const Color(0xFFFFF3E0); // Light Orange
      case 'Keuangan':
        return AppColors.success.withOpacity(0.1);
      default:
        return Colors.grey[100]!;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Penting':
        return Icons.campaign_rounded;
      case 'Kegiatan':
        return Icons.event_note_rounded;
      case 'Himbauan':
        return Icons.info_outline_rounded;
      case 'Keuangan':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aktif':
        return AppColors.success;
      case 'Terjadwal':
        return AppColors.primary;
      case 'Draft':
        return Colors.grey[600]!;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredAnnouncements();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manajemen Pengumuman',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title and desc
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Pengumuman',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Buat, atur, dan siarkan informasi penting bagi seluruh warga RT.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari pengumuman atau topik...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Horizontal Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['Semua', 'Aktif', 'Draft'].map((tab) {
                bool isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: isSelected,
                    showCheckmark:
                        false, // Menghilangkan ikon centang saat aktif
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTab = tab;
                        });
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.withOpacity(0.1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Total Items Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredItems.length} Pengumuman ditemukan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  'Filter: $_selectedTab',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Announcement List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildAnnouncementCard(context, item);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<Announcement>(
            context,
            MaterialPageRoute(
              builder: (context) => AddPengumumanScreen(user: widget.user),
            ),
          );
          if (result != null) {
            await _fetchAnnouncements();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.status == 'Aktif'
                      ? 'Pengumuman berhasil diterbitkan!'
                      : 'Draf pengumuman berhasil disimpan!',
                  style: GoogleFonts.plusJakartaSans(),
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(
          'Buat Pengumuman',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak Ada Pengumuman',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'Kami tidak dapat menemukan hasil pencarian untuk "$_searchQuery". Silakan coba kata kunci lain.'
                  : 'Saat ini belum ada pengumuman dalam kategori ini. Ketuk tombol di bawah untuk membuat pengumuman baru.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, Announcement item) {
    final typeColor = _getTypeColor(item.type);
    final typeBg = _getTypeBgColor(item.type);
    final typeIcon = _getTypeIcon(item.type);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPengumumanScreen(announcement: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Category and Status Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 14, color: typeColor),
                      const SizedBox(width: 6),
                      Text(
                        item.type.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: typeColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Indicator dot
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(item.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.status,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(item.status),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Announcement Title
            Text(
              item.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D1B2A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Excerpt Content
            Text(
              item.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Divider
            Divider(color: Colors.grey.withOpacity(0.1), height: 1),
            const SizedBox(height: 12),

            // Metadata & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Target and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Target: ${item.targetAudience}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.date,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (item.status == 'Draft')
                  Wrap(
                    spacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Edit draf',
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        color: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _openEditAnnouncement(item),
                      ),
                      IconButton(
                        tooltip: 'Hapus draf',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        color: AppColors.danger,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteAnnouncement(item),
                      ),
                      TextButton.icon(
                        onPressed: () => _publishAnnouncement(item),
                        icon: const Icon(Icons.campaign_rounded, size: 16),
                        label: Text(
                          'Terbitkan',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Tersiar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
