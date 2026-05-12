import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';

class SosDashboardScreen extends StatelessWidget {
  const SosDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dashbord SOS',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 24),
                const SizedBox(width: 8),
                Text(
                  'CRITICAL ALERT LEVEL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'SOS\nDashboard',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: const Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Real-time surveillance for District 07. Immediate response required for active distress signals.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.emergency_share_rounded,
                    value: '01',
                    label: 'ACTIVE SOS',
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle_outline_rounded,
                    value: '6',
                    label: 'REPORT',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Recent Alerts Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Alerts',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      Text(
                        'View Full Ledger',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9EAF7).withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildTableHeader('NAME')),
                        Expanded(child: _buildTableHeader('ALAMAT')),
                        _buildTableHeader('TIME'),
                      ],
                    ),
                  ),
                  // Table Rows
                  _buildTableRow('Ibu Siti Aminah', 'Block A, No. 12', 'Yesterday, 22:15', isEven: false),
                  _buildTableRow('Pak Bambang', 'Block M No. 05', 'Oct 24, 11:30', isEven: true),
                  _buildTableRow('Yuda Pratama', 'Block B, No. 21', 'Oct 23, 09:10', isEven: false, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTableRow(String name, String address, String time, {required bool isEven, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFD9EAF7).withOpacity(0.2) : Colors.white,
        borderRadius: isLast ? const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D1B2A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              address,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            time,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertCard({
    required String name,
    required String location,
    required String time,
    required String message,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9EAF7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 8,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home_outlined, color: AppColors.danger),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0D1B2A),
                                ),
                              ),
                              Text(
                                '$location • $time',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD6D6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D1B2A).withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
