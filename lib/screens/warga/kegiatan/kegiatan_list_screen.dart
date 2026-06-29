import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/colors.dart';
import 'kegiatan_detail_screen.dart';

class KegiatanListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const KegiatanListScreen({super.key, required this.activities});

  String _statusLabel(String? status) {
    switch (status) {
      case 'ANNOUNCED':
        return 'AKAN DATANG';
      case 'COMPLETED':
        return 'SELESAI';
      case 'DRAFT':
        return 'DRAFT';
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

  @override
  Widget build(BuildContext context) {
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
          'Kegiatan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: activities.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy_outlined,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada kegiatan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = activities[index];
                final type = item['type']?.toString() ?? '';
                final status = item['status']?.toString() ?? '';
                final title = item['title']?.toString() ?? 'Kegiatan';
                final dateStr = item['activity_date']?.toString();
                final date =
                    dateStr != null ? DateTime.tryParse(dateStr) : null;
                final dateText = date != null
                    ? DateFormat('dd MMM yyyy').format(date)
                    : '-';

                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          KegiatanDetailScreen(activity: item),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _typeColor(type).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            type == 'RAPAT'
                                ? Icons.people_outline
                                : Icons.event_outlined,
                            color: _typeColor(type),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dateText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
