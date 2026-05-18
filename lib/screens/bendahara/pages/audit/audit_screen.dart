import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import 'report_preview_screen.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Title
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(4),
                    )
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Laporan Keuangan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Periode: Oktober 2026',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Financial Summary Cards
            _buildReportCard(
              label: 'TOTAL PEMASUKAN',
              value: 'Rp 12.450.000',
              icon: Icons.trending_up_rounded,
              color: Colors.green[700]!,
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              label: 'TOTAL PENGELUARAN',
              value: 'Rp 4.800.000',
              icon: Icons.trending_down_rounded,
              color: Colors.red[700]!,
            ),
            const SizedBox(height: 16),
            
            // Saldo Akhir Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF004E92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF004E92).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SALDO AKHIR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp 7.650.000',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white.withOpacity(0.3), size: 32),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Iuran Bulanan Section
            _buildSectionHeader('Iuran Bulanan'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5EEF5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Koleksi Iuran', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('85% Selesai', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.85,
                      minHeight: 10,
                      backgroundColor: Color(0xFFE5EEF5),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004E92)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildMiniStat('Total KK', '60 KK')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniStat('Sudah Bayar', '51 KK')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMiniStat('Belum Bayar', '9 KK', valueColor: Colors.red[700])),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniStat('Nominal/KK', 'Rp 150rb')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Terkumpul', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      Text('Rp 7.650.000', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF004E92))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Rincian Pengeluaran Section
            _buildSectionHeader('Rincian Pengeluaran'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5EEF5)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: const Color(0xFFF0F5F9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pengeluaran', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        Text('Nominal', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  _buildExpenseItem('Keamanan & Kebersihan', 'Gaji 2 Petugas', 'Rp 2.500.000'),
                  _buildExpenseItem('Listrik Fasum', 'Lampu Jalan & Mushola', 'Rp 850.000'),
                  _buildExpenseItem('Perbaikan Drainase', 'Blok C No. 12', 'Rp 1.450.000'),
                  _buildExpenseItem('Dana kematian', 'Mr x wafat', 'Rp 1.450.000'),
                  _buildExpenseItem('Anak pak indro sunatan', 'HAri Ahad 14 Agustus 2026', 'Rp 1.450.000'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFFFF5F5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Pengeluaran', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.red[800])),
                        Text('Rp 4.800.000', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.red[800])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportPreviewScreen()),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Unduh PDF Laporan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E92),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EEF5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0D1B2A)),
              ),
            ],
          ),
          Icon(icon, color: color, size: 28),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0D1B2A)),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF004E92))),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(String title, String subtitle, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(amount, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
