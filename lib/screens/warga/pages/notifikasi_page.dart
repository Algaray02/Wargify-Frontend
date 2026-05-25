import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  // --- Dummy Data ---
  static const List<Map<String, dynamic>> _notifikasi = [
    {
      'type': 'pengumuman',
      'sender': 'Ketua RT 04',
      'waktu': '2 jam yang lalu',
      'pesan': 'mengirimkan pengumuman',
      'highlight': '"Kerja Bakti"',
      'suffix': 'ke Semua Warga.',
      'iconBg': Color(0xFF2C2C2C),
      'badgeColor': Color(0xFF1565C0),
      'badgeIcon': Icons.campaign_outlined,
    },
    {
      'type': 'sistem',
      'sender': 'Sistem Wargify',
      'waktu': '3 jam yang lalu',
      'pesan': 'Sistem: Pengingat Iuran Bulanan telah dikirim ke ',
      'highlight': '150 warga',
      'suffix': '.',
      'iconBg': Color(0xFF00468B),
      'badgeColor': null,
      'badgeIcon': null,
      'isSystem': true,
    },
    {
      'type': 'sos',
      'sender': 'Darurat SOS',
      'waktu': '08:00',
      'pesan': 'Pak Rusdi memencet tombol SOS: ',
      'highlight': '"Anakku ilang"',
      'suffix': '',
      'iconBg': Color(0xFFAD1114),
      'badgeColor': null,
      'badgeIcon': null,
      'isSos': true,
    },
    {
      'type': 'ronda',
      'sender': 'Ketua RT 04',
      'waktu': 'Kemarin',
      'pesan': 'Anda membuat jadwal ronda baru.',
      'highlight': null,
      'suffix': '',
      'iconBg': Color(0xFF2C2C2C),
      'badgeColor': Color(0xFF2E7D32),
      'badgeIcon': Icons.calendar_today,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Aktivitas & Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _notifikasi.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _notifikasi[index];
          return _NotifCard(item: item);
        },
      ),
    );
  }
}

// ─── Notif Card ───────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _NotifCard({required this.item});

  bool get _isSos => item['isSos'] == true;
  bool get _isSystem => item['isSystem'] == true;

  Color get _cardBg {
    if (_isSos) return const Color(0xFFFFEBEB);
    if (_isSystem) return AppColors.secondary;
    return AppColors.white;
  }

  Color get _senderColor {
    if (_isSos) return AppColors.danger;
    if (_isSystem) return AppColors.primary;
    return AppColors.textPrimary;
  }

  Color get _waktuColor {
    if (_isSos) return AppColors.danger;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final iconBg = item['iconBg'] as Color;
    final badgeColor = item['badgeColor'] as Color?;
    final badgeIcon = item['badgeIcon'] as IconData?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isSos || _isSystem
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _isSystem
                    ? const Icon(
                        Icons.wallet_outlined,
                        color: AppColors.white,
                        size: 26,
                      )
                    : _isSos
                    ? const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.white,
                        size: 26,
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 26,
                      ),
              ),
              if (badgeColor != null && badgeIcon != null)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Icon(badgeIcon, size: 11, color: AppColors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['sender'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _senderColor,
                      ),
                    ),
                    Text(
                      item['waktu'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _waktuColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildPesan(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesan() {
    final pesan = item['pesan'] as String? ?? '';
    final highlight = item['highlight'] as String?;
    final suffix = item['suffix'] as String? ?? '';

    if (highlight == null) {
      return Text(
        pesan,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        children: [
          TextSpan(text: pesan),
          TextSpan(
            text: highlight,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _isSos ? AppColors.danger : AppColors.primary,
            ),
          ),
          TextSpan(text: suffix),
        ],
      ),
    );
  }
}
