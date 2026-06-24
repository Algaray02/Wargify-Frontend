import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/screens/bendahara/qr/qr_scanner_screen.dart';
import 'package:wargify/widgets/common/scan/manual_payment_sheet.dart';

class ShowContributionQrScreen extends StatelessWidget {
  final Map<String, dynamic>? periodData;

  const ShowContributionQrScreen({super.key, this.periodData});

  @override
  Widget build(BuildContext context) {
    final String periodName = periodData?['period_name'] ?? 'Iuran Bulanan';
    final String qrData = periodData?['payment_qr_code'] ?? 'Wargify_Generic_Contribution';
    final String categoryName = periodData?['category']?['name'] ?? 'Umum';
    
    // Mengekstrak ID Periode dari database Supabase agar bisa dipakai oleh sheet centang manual
    final String periodId = periodData?['period_id'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D47A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'QR $periodName',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0D47A1),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.grey),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Bendahara&background=00468B&color=fff'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E6ED)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Wargify',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    Text(
                      categoryName.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[500],
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1565C0), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$qrData',
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      periodName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scan QR statis ini untuk melakukan pencatatan pembayaran pada kategori terkait.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Tombol Centang Manual terintegrasi penuh dengan ID Periode aktif
              OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ManualPaymentSheet(
                      periodId: periodId,
                    ),
                  );
                },
                icon: const Icon(Icons.checklist_rtl_rounded, size: 20),
                label: const Text('Centang Manual'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF004E92),
                  side: const BorderSide(color: Color(0xFF004E92)),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Sistem iuran aman & terenkripsi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QrScannerScreen()),
          );
        },
        backgroundColor: const Color(0xFF004E92),
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
      ),
    );
  }
}