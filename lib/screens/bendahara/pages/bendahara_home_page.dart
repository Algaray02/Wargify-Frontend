import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/user_model.dart';
import 'scan/show_contribution_qr_screen.dart';
import 'contribution/add_contribution_screen.dart';

class BendaharaHomePage extends StatelessWidget {
  final UserModel user;
  const BendaharaHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            'DASHBOARD BENDAHARA',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sore, ${user.fullName.split(' ')[0]}.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 24),
          
          // Total Kas Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D47A1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL KAS TERCATAT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Rp',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '15.450.000',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Dihitung dari iuran & pengeluaran yang dicatat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddContributionScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Tambah Iuran'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D47A1),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Iuran Progress
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EEF5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Iuran Oktober 2026',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D1B2A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Aktif',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress Penagihan', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
                    Text('75%', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: const Color(0xFFE5EEF5),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '45 dari 60 warga telah membayar',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ShowContributionQrScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Tampilkan QR Iuran',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // // Action Buttons
          // _buildActionCard(
          //   title: 'Tombol Darurat',
          //   subtitle: 'Gunakan jika ada situasi genting',
          //   icon: Icons.error_outline_rounded,
          //   color: const Color(0xFFB71C1C),
          //   onTap: () {},
          // ),
          // const SizedBox(height: 12),
          // _buildActionCard(
          //   title: 'Lapor Fasilitas',
          //   subtitle: 'Laporkan fasilitas rusak',
          //   icon: Icons.campaign_outlined,
          //   color: const Color(0xFF0288D1),
          //   isLight: true,
          //   onTap: () {},
          // ),
          // const SizedBox(height: 32),
          
          // Kelola Keuangan Section
          Text(
            'Kelola Keuangan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFinancialButton(
                  label: 'Pemasukan',
                  subtitle: 'Tambah saldo baru',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFFE8EAF6),
                  iconColor: const Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFinancialButton(
                  label: 'Pengeluaran',
                  subtitle: 'Catat biaya rutin',
                  icon: Icons.trending_down_rounded,
                  color: const Color(0xFFFFEBEE),
                  iconColor: const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Quick Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EEF5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Summary',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSummaryRow('TOTAL MASUK', 'Rp 18.2jt', Colors.blue[800]!, Icons.show_chart_rounded),
                const SizedBox(height: 12),
                _buildSummaryRow('TOTAL KELUAR', 'Rp 2.75jt', Colors.red[800]!, Icons.auto_graph_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isLight = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLight ? color.withOpacity(0.1) : color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isLight ? null : [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight ? color.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: isLight ? color : Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLight ? const Color(0xFF0D1B2A) : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isLight ? Colors.grey[600] : Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isLight ? Colors.grey : Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0D1B2A))),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0D1B2A))),
              ],
            ),
          ),
          Icon(icon, color: color.withOpacity(0.3), size: 24),
        ],
      ),
    );
  }
}
