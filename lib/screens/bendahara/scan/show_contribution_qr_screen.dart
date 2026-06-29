import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/screens/bendahara/qr/qr_scanner_screen.dart';
import 'package:wargify/widgets/bendahara/payment/manual_payment_sheet.dart';

class ShowContributionQrScreen extends StatefulWidget {
  final Map<String, dynamic>? periodData;

  const ShowContributionQrScreen({super.key, this.periodData});

  @override
  State<ShowContributionQrScreen> createState() => _ShowContributionQrScreenState();
}

class _ShowContributionQrScreenState extends State<ShowContributionQrScreen> {
  
  // Fungsi Helper mengubah angka bulan (1-12) menjadi Teks Bahasa Indonesia
  String _getNamaBulanIndo(int monthNumber) {
    const List<String> months = [
      "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    if (monthNumber >= 1 && monthNumber <= 12) {
      return months[monthNumber - 1];
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 SINKRONISASI DATA MANDIRI: Ekstrak angka month & year dari database
    final int monthVal = int.tryParse(widget.periodData?['month']?.toString() ?? '') ?? 0;
    final int yearVal = int.tryParse(widget.periodData?['year']?.toString() ?? '') ?? 0;
    
    // 🌟 FORMULASI TEKS DINAMIS: Jika month & year valid, rangkai teks cantik. Jika tidak, gunakan period_name mentah sebagai fallback.
    String displayPeriod = "Iuran Bulanan";
    if (monthVal >= 1 && monthVal <= 12 && yearVal > 0) {
      displayPeriod = "${_getNamaBulanIndo(monthVal)} $yearVal";
    } else {
      displayPeriod = widget.periodData?['period_name'] ?? 'Iuran Bulanan';
    }

    // Mengekstrak ID Periode agar bisa dipakai oleh sheet centang manual
    final String periodId = widget.periodData?['period_id'] ?? '';

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
          'Konsol Pengurus',
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
              // 🌟 PANEL INFORMASI & KONSOL KAS UTAMA
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0E6ED)),
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
                    // Tag Status Periode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Wargify Kas RT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green[100]!),
                          ),
                          child: Text(
                            'PERIODE AKTIF',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Rincian Periode Utama (Menggantikan Tarif Kategori Tunggal)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF004E92).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFF004E92),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Periode Penagihan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                displayPeriod, // 🌟 Menggunakan displayPeriod bersih ("Agustus 2026")
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D1B2A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1, color: Color(0xFFF0F4F8)),
                    ),

                    // Panduan Penggunaan untuk Bendahara
                    Text(
                      'PANDUAN OPERASIONAL:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D1B2A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow(
                      '1',
                      'Centang Manual',
                      'Gunakan tombol di bawah jika warga melakukan pembayaran tunai langsung di tempat.',
                    ),
                    const SizedBox(height: 10),
                    _buildStepRow(
                      '2',
                      'Scan Barcode Warga',
                      'Tekan tombol kamera melayang di kanan bawah untuk memotong otomatis tunggakan via scan kartu warga.',
                    ),
                    const SizedBox(height: 10),
                    _buildStepRow(
                      '3',
                      'Otomasi Keuangan',
                      'Seluruh transaksi pembayaran yang dicatat otomatis disinkronkan ke dalam grafik rekap kas RT.',
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

  // Widget Pembantu untuk menampilkan list panduan numerik yang estetik
  Widget _buildStepRow(String number, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF0D47A1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}