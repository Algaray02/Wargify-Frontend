import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/colors.dart';

class KegiatanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const KegiatanDetailScreen({super.key, required this.activity});

  String _typeLabel(String? type) {
    switch (type) {
      case 'RAPAT':
        return 'Rapat';
      case 'KEGIATAN_UMUM':
        return 'Kegiatan Umum';
      default:
        return 'Kegiatan';
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'RAPAT':
        return Icons.people_outline;
      case 'KEGIATAN_UMUM':
        return Icons.event_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'RAPAT':
        return AppColors.primary;
      case 'KEGIATAN_UMUM':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'ANNOUNCED':
        return 'Akan Datang';
      case 'COMPLETED':
        return 'Selesai';
      case 'DRAFT':
        return 'Draft';
      default:
        return status ?? '-';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'ANNOUNCED':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = activity['type']?.toString() ?? '';
    final title = activity['title']?.toString() ?? 'Kegiatan';
    final description = activity['description']?.toString() ?? '';
    final status = activity['status']?.toString() ?? '';
    final dateStr = activity['activity_date']?.toString();
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final location = activity['location_name']?.toString() ?? '';
    final creator = activity['creator'] is Map
        ? Map<String, dynamic>.from(activity['creator'] as Map)
        : null;
    final creatorName = creator?['full_name']?.toString() ?? 'Pengurus RT';
    final household = activity['household'] is Map
        ? Map<String, dynamic>.from(activity['household'] as Map)
        : null;
    final block = household?['block_number']?.toString() ?? '';
    final houseNum = household?['house_number']?.toString() ?? '';
    final address =
        [if (block.isNotEmpty) 'Blok $block', if (houseNum.isNotEmpty) 'No. $houseNum'].join(' / ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Kegiatan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Type + Status badge ---
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _typeColor(type).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon(type), size: 14, color: _typeColor(type)),
                      const SizedBox(width: 4),
                      Text(
                        _typeLabel(type),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _typeColor(type),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Title ---
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // --- Info Cards ---
            if (date != null) _infoRow(Icons.calendar_today, 'Tanggal',
                DateFormat('EEEE, dd MMMM yyyy', 'id').format(date)),
            if (date != null)
              _infoRow(
                  Icons.access_time, 'Waktu', DateFormat('HH:mm').format(date)),
            if (location.isNotEmpty)
              _infoRow(Icons.location_on_outlined, 'Lokasi', location),
            if (address.isNotEmpty)
              _infoRow(Icons.home_outlined, 'Alamat', address),
            _infoRow(Icons.person_outline, 'Diselenggarakan oleh', creatorName),

            const SizedBox(height: 24),

            // --- Description ---
            if (description.isNotEmpty) ...[
              Text(
                'Deskripsi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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
