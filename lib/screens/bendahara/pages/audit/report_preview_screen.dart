import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';

class ReportPreviewScreen extends StatelessWidget {
  const ReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0D1B2A)),
          label: Text(
            'BACK',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D1B2A),
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
              label: const Text('Cetak PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E92),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500), // Slightly smaller max width
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32), // Reduced padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wargify – Laporan Keuangan RT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF004E92),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ringkasan Laporan Bulanan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'PERIODE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Oktober 2026',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D1B2A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '25 Okt 2026',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Summary Row - Fixed Overflows with LayoutBuilder and Smaller sizes
                  Row(
                    children: [
                      _buildSummaryBox('Total Masuk', 'Rp 18.2jt', Colors.blue[800]!),
                      const SizedBox(width: 8),
                      _buildSummaryBox('Total Keluar', 'Rp 2.7jt', Colors.red[800]!),
                      const SizedBox(width: 8),
                      _buildSummaryBox('Saldo Akhir', 'Rp 15.4jt', const Color(0xFF004E92), isHighlighted: true),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Iuran Summary Section
                  _buildSectionLabel('Iuran Summary'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5EEF5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IURAN BULANAN (OKT 2026)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF004E92),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildMiniInfo('TOTAL KK', '60'),
                                      const SizedBox(width: 16),
                                      _buildMiniInfo('NOMINAL', '150k'),
                                      const SizedBox(width: 16),
                                      _buildMiniInfo('LUNAS', '51', color: Colors.green[700]),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF004E92),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('85%', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TERKUMPUL', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('Rp 7.650.000', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF004E92))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Expense Table
                  _buildSectionLabel('Rincian Pengeluaran'),
                  const SizedBox(height: 12),
                  _buildExpenseTable(),
                  const SizedBox(height: 32),

                  // Signature Footer
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary, width: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Column(
                                children: [
                                  Text('VERIFY', style: GoogleFonts.plusJakartaSans(fontSize: 4, fontWeight: FontWeight.bold)),
                                  Text('REPORT', style: GoogleFonts.plusJakartaSans(fontSize: 4, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Generated by Wargify System',
                                style: GoogleFonts.plusJakartaSans(fontSize: 7, color: Colors.grey[500]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Bendahara RT,', style: GoogleFonts.plusJakartaSans(fontSize: 9)),
                          const SizedBox(height: 24),
                          Container(width: 80, height: 0.5, color: Colors.black),
                          const SizedBox(height: 4),
                          Text('BENDAHARA RT', style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, Color color, {bool isHighlighted = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlighted ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isHighlighted ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(width: 2, height: 12, color: const Color(0xFF004E92)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 6, color: Colors.grey[500], fontWeight: FontWeight.bold)),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF0D1B2A))),
      ],
    );
  }

  Widget _buildExpenseTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5EEF5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: const Color(0xFFF0F4F8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Pengeluaran', style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Nominal', style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Ket', style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          _buildExpenseRow('Lampu Jalan', 'Rp 850k', 'LED Blok B'),
          _buildExpenseRow('Iuran Sampah', 'Rp 1.2jt', 'Gaji petugas'),
          _buildExpenseRow('Konsumsi', 'Rp 700k', 'Rapat bulanan'),
          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: const Color(0xFFFFEBEE).withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL', style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold)),
                Text('Rp 2.750.000', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.red[800])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(String title, String amount, String note) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5EEF5))),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 8))),
          Expanded(flex: 2, child: Text(amount, style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(note, style: GoogleFonts.plusJakartaSans(fontSize: 7, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
