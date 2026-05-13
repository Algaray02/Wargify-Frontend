import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';

class ResidentsScreen extends StatelessWidget {
  const ResidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Daftar Warga',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola data dan status pembayaran iuran warga',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5EEF5)),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama atau blok...',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChipFilter('Bulan: ', 'Agustus', Icons.calendar_month_rounded),
                const SizedBox(width: 12),
                _buildChipFilter('Status: ', 'Semua Status', Icons.payments_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Residents List
          _buildResidentItem('Budi Santoso', 'Blok C-12', true),
          _buildResidentItem('Ani Putri', 'Blok A-05', false),
          _buildResidentItem('Rizky Kurniawan', 'Blok B-21', true),
          _buildResidentItem('Dewi Wijaya', 'Blok C-01', false),
          _buildResidentItem('Herman Maulana', 'Blok A-10', true),
          _buildResidentItem('Siti Nurhaliza', 'Blok B-08', true),
          
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Scroll untuk data lainnya...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChipFilter(String prefix, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EEF5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[700]),
              children: [
                TextSpan(text: prefix),
                TextSpan(
                  text: label,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildResidentItem(String name, String block, bool isLunas) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EEF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isLunas ? const Color(0xFFE3F2FD) : const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                name.split(' ').map((e) => e[0]).take(2).join(),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: isLunas ? AppColors.primary : Colors.purple[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                Text(
                  block,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLunas ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isLunas ? 'Lunas' : 'Belum Bayar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isLunas ? Colors.green[700] : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
