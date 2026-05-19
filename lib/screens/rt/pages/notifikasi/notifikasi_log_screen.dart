import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';

class ActivityLog {
  final String title;
  final String content;
  final String time;
  final String type; // 'rt', 'system', 'sos', 'ronda'
  final String imagePath; // Optional mock image or avatar
  final IconData? icon;

  ActivityLog({
    required this.title,
    required this.content,
    required this.time,
    required this.type,
    required this.imagePath,
    this.icon,
  });
}

class NotifikasiLogScreen extends StatelessWidget {
  const NotifikasiLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Exact logs from your screenshot
    final List<ActivityLog> logs = [
      ActivityLog(
        title: 'Ketua RT 04',
        time: '2 jam yang lalu',
        content: 'Anda mengirim pengumuman "Kerja Bakti" ke Semua Warga.',
        type: 'rt',
        imagePath: 'https://ui-avatars.com/api/?name=RT+04&background=222&color=fff',
        icon: Icons.campaign_rounded,
      ),
      ActivityLog(
        title: 'Sistem Wargify',
        time: '3 jam yang lalu',
        content: 'Sistem: Pengingat Iuran Bulanan telah dikirim ke 150 warga.',
        type: 'system',
        imagePath: '',
        icon: Icons.account_balance_wallet,
      ),
      ActivityLog(
        title: 'Ketua RT 04',
        time: '5 jam yang lalu',
        content: 'Anda mengundang Ibu-Ibu PKK ke rapat "Arisan Bulanan".',
        type: 'rt_meeting',
        imagePath: 'https://ui-avatars.com/api/?name=PKK&background=7f8c8d&color=fff',
        icon: Icons.people_alt_rounded,
      ),
      ActivityLog(
        title: 'Darurat SOS',
        time: '08:00',
        content: 'Pak Rusdi memencet tombol SOS: "Anakku ilang"',
        type: 'sos',
        imagePath: '',
        icon: Icons.warning_rounded,
      ),
      ActivityLog(
        title: 'Ketua RT 04',
        time: 'Kemarin',
        content: 'Anda membuat jadwal ronda baru.',
        type: 'ronda',
        imagePath: 'https://ui-avatars.com/api/?name=Ronda&background=2c3e50&color=fff',
        icon: Icons.calendar_month_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Aktivitas & Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'LOG AKTIVITAS TERBARU',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey[500],
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: logs.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogCard(log);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(ActivityLog log) {
    Color cardBgColor = Colors.white;
    Color iconBgColor = AppColors.primary;
    Color badgeBgColor = AppColors.primary;

    if (log.type == 'system') {
      cardBgColor = const Color(0xFFE3F2FD); // Subtle light blue
      iconBgColor = const Color(0xFF0F4C81);
    } else if (log.type == 'sos') {
      cardBgColor = const Color(0xFFFFEBEE); // Subtle light red
      iconBgColor = AppColors.danger;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: log.type == 'system'
              ? const Color(0xFFD4E6F1)
              : log.type == 'sos'
                  ? const Color(0xFFFADBD8)
                  : Colors.grey.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Icon Avatar with Badge
          Stack(
            children: [
              if (log.type == 'system' || log.type == 'sos')
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    log.icon,
                    color: Colors.white,
                    size: 26,
                  ),
                )
              else
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(log.imagePath),
                ),
              if (log.type != 'system' && log.type != 'sos')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      log.icon,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: log.type == 'sos' ? AppColors.danger : const Color(0xFF0D1B2A),
                      ),
                    ),
                    Text(
                      log.time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: log.type == 'sos' ? AppColors.danger : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    children: _buildContentSpans(log.content),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Highlight bold text inside activity content
  List<TextSpan> _buildContentSpans(String text) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'("[^"]*"|\d+[\w]*)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D1B2A),
          ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }
}
