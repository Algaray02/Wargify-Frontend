import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import 'add_ronda_screen.dart';

class RondaScreen extends StatelessWidget {
  const RondaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Dashboard Ronda',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 20),
          
          // Security Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF004E92), Color(0xFF001F3F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF004E92).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS KEAMANAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '3 Sektor Terpantau',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'PETUGAS AKTIF',
                  value: '4 Orang',
                  icon: Icons.groups_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  label: 'TITIK CEK',
                  value: '3/15',
                  icon: Icons.check_circle_outline_rounded,
                  valueColor: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Recent Activity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivitas Terkini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitoring pergerakan petugas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Lihat Peta',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Activity List
          _buildActivityItem('Bpk. Ahmad Suhendar', 'Ketua koordinator', 'Scan QR Checkpoint 3', 'https://i.pravatar.cc/150?u=ahmad'),
          _buildActivityItem('Ibu Rini Astuti', 'Petugas patroli', 'Melaporkan kondisi aman', 'https://i.pravatar.cc/150?u=rini'),
          _buildActivityItem('Bpk. Bambang Pamungkas', 'Petugas pos', 'Menjaga portal utama', 'https://i.pravatar.cc/150?u=bambang'),
          
          const SizedBox(height: 32),
          
          // Patrol Schedule Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jadwal Ronda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddRondaScreen()),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Jadwal Ronda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004E92),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Shift Malam Ini (22:00 - 04:00)',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF004E92)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Schedule Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        children: [
                          Text('SEN', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text('24', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REGU ELANG (4 ORANG)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildAvatarGroup(['https://i.pravatar.cc/150?u=1', 'https://i.pravatar.cc/150?u=2', 'https://i.pravatar.cc/150?u=3']),
                              const SizedBox(width: 8),
                              Text('+1', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pengingat otomatis telah dikirim ke semua anggota.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Incident Reports
          Text(
            'Laporan Kejadian',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 16),
          _buildIncidentCard(
            title: 'Lampu Jalan Mati',
            description: 'Tiang No. 14 Sektor B berkedip dan mulai padam. Mohon tindak lanjut.',
            reporter: 'Bpk. Doni',
            time: '2 Jam lalu',
            type: 'URGENT',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildIncidentCard(
            title: 'Portal Rusak',
            description: 'Engsel portal barat sedikit seret saat dibuka dini hari tadi.',
            reporter: 'Ibu Rini',
            time: '6 Jam lalu',
            type: 'INFO',
            icon: Icons.info_outline_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String label, required String value, required IconData icon, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? const Color(0xFF0D1B2A),
                ),
              ),
              Icon(icon, color: Colors.grey[300], size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String name, String role, String status, String avatarUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundImage: NetworkImage(avatarUrl), radius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(role, style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 10)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(status, style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'LIVE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGroup(List<String> urls) {
    return SizedBox(
      height: 24,
      width: 60,
      child: Stack(
        children: List.generate(urls.length, (index) {
          return Positioned(
            left: index * 14.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(radius: 10, backgroundImage: NetworkImage(urls[index])),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIncidentCard({
    required String title,
    required String description,
    required String reporter,
    required String time,
    required String type,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600], height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const CircleAvatar(radius: 10, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=reporter')),
                    const SizedBox(width: 8),
                    Text(
                      'Dilaporkan oleh $reporter • $time',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
