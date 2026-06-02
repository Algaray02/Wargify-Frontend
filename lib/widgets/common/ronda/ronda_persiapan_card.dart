import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

class RondaPersiapanCard extends StatelessWidget {
  final bool sudahScan;
  final VoidCallback onScanTap;
  final VoidCallback onMulaiTap;

  const RondaPersiapanCard({
    super.key,
    required this.sudahScan,
    required this.onScanTap,
    required this.onMulaiTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PERSIAPAN RONDA',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scan QR Button
          GestureDetector(
            onTap: onScanTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 40,
                    color: sudahScan ? AppColors.primary : AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan QR Pos',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status scan
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                sudahScan ? Icons.check_circle : Icons.check_circle_outline,
                size: 16,
                color: sudahScan ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                sudahScan ? 'POS TERSCAN' : 'BELUM SCAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sudahScan ? AppColors.primary : AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tombol Mulai Ronda
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: sudahScan ? onMulaiTap : null,
              icon: Icon(
                sudahScan ? Icons.play_arrow_rounded : Icons.lock_outline,
                size: 20,
              ),
              label: Text(
                'MULAI RONDA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: sudahScan ? AppColors.success : Colors.grey.shade300,
                foregroundColor: sudahScan ? AppColors.white : Colors.grey.shade500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}