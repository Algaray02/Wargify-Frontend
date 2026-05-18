import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/user_model.dart';
import 'add_pengumuman_screen.dart';
import 'edit_pengumuman_screen.dart';
import 'detail_pengumuman_screen.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String type; // Penting, Kegiatan, Himbauan, Keuangan, Lainnya
  final String targetAudience; // Semua Warga, Kepala Keluarga, Kelompok Ronda, Pengurus RT
  final String status; // Aktif, Draft, Terjadwal
  final String date;
  final String author;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.targetAudience,
    required this.status,
    required this.date,
    required this.author,
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
  String _selectedTab = 'Semua';
  String _searchQuery = '';

  // Initial rich sample data
  final List<Announcement> _announcements = [
    Announcement(
      id: '1',
      title: 'Himbauan Keamanan Malam & Ronda Bersama',
      content: 'Dihimbau kepada seluruh warga RT 05 untuk senantiasa mengunci pagar rumah masing-masing sebelum pukul 22.00 WIB demi keamanan bersama. Bagi warga yang mendapat jadwal ronda malam ini harap berkumpul tepat waktu di Pos Ronda Utama.',
      type: 'Himbauan',
      targetAudience: 'Semua Warga',
      status: 'Aktif',
      date: '18 Mei 2026',
      author: 'Budi Santoso (Ketua RT)',
    ),
    Announcement(
      id: '2',
      title: 'Rapat Bulanan Warga Mei 2026',
      content: 'Agenda rapat bulanan akan diselenggarakan untuk membahas rencana renovasi gapura masuk RT 05 dan laporan bulanan keuangan kas RT. Kehadiran Bapak/Ibu sekalian sangat diharapkan demi kelancaran kegiatan bersama.',
      type: 'Kegiatan',
      targetAudience: 'Kepala Keluarga',
      status: 'Terjadwal',
      date: '22 Mei 2026',
      author: 'Budi Santoso (Ketua RT)',
    ),
    Announcement(
      id: '3',
      title: 'Laporan Pertanggungjawaban Kas RT Q1',
      content: 'Laporan rincian pemasukan dan pengeluaran kas RT selama periode Januari - Maret 2026 telah selesai disusun oleh Bendahara. Silakan unduh atau tinjau dokumen terlampir pada portal ini.',
      type: 'Keuangan',
      targetAudience: 'Semua Warga',
      status: 'Aktif',
      date: '10 Apr 2026',
      author: 'Sri Rahayu (Bendahara)',
    ),
    Announcement(
      id: '4',
      title: 'Pemberitahuan Fogging Nyamuk DBD',
      content: 'Sehubungan dengan adanya kasus DBD di wilayah sekitar, Puskesmas bekerja sama dengan pengurus RT akan mengadakan penyemprotan fogging. Mohon warga menutup makanan/minuman rapat-rapat saat penyemprotan berlangsung.',
      type: 'Penting',
      targetAudience: 'Semua Warga',
      status: 'Draft',
      date: '20 Mei 2026',
      author: 'Budi Santoso (Ketua RT)',
    ),
  ];

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
        final matchesContent = announcement.content.toLowerCase().contains(query);
        final matchesType = announcement.type.toLowerCase().contains(query);
        return matchesTitle || matchesContent || matchesType;
      }
      return true;
    }).toList();
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

  void _confirmDelete(BuildContext context, Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 28),
            const SizedBox(width: 12),
            Text(
              'Hapus Pengumuman',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF0D1B2A),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengumuman "${announcement.title}"? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _announcements.removeWhere((item) => item.id == announcement.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pengumuman berhasil dihapus',
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              children: ['Semua', 'Aktif', 'Terjadwal', 'Draft'].map((tab) {
                bool isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: isSelected,
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: filteredItems.isEmpty
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
              builder: (context) => AddPengumumanScreen(
                user: widget.user,
              ),
            ),
          );
          if (result != null) {
            setState(() {
              _announcements.insert(0, result);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pengumuman berhasil diterbitkan!',
                  style: GoogleFonts.plusJakartaSans(),
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            child: Icon(Icons.campaign_outlined, size: 64, color: AppColors.primary.withOpacity(0.3)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          Icon(Icons.people_alt_outlined, size: 13, color: Colors.grey[500]),
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
                          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
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

                // Edit & Delete Actions
                Row(
                  children: [
                    // Edit
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      onPressed: () async {
                        final result = await Navigator.push<Announcement>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPengumumanScreen(
                              announcement: item,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            int index = _announcements.indexWhere((a) => a.id == item.id);
                            if (index != -1) {
                              _announcements[index] = result;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Pengumuman berhasil diperbarui',
                                style: GoogleFonts.plusJakartaSans(),
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 14),

                    // Delete
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                      onPressed: () => _confirmDelete(context, item),
                      tooltip: 'Hapus',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
