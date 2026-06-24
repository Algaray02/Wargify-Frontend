import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'report_preview_screen.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMsg;

  // State Penampung Data Riil Database
  Map<String, dynamic> _summaryData = {};
  List<dynamic> _expenseList = [];
  Map<String, dynamic> _iuranStats = {};

  @override
  void initState() {
    super.initState();
    _fetchAuditFinancialData();
  }

  Future<void> _fetchAuditFinancialData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });

      final response = await _apiService.getMap(ApiEndpoints.treasuryAuditSummary);

      if (response != null && response.containsKey('summary')) {
        if (!mounted) return;
        setState(() {
          // 🔄 Kita bypass langsung tembak ke root JSON tanpa response['data']
          _summaryData = response['summary'] ?? {};
          _expenseList = response['expenses'] ?? [];
          _iuranStats = response['iuran_stats'] ?? {};
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMsg = "Gagal memuat struktur data audit.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = "Koneksi bermasalah: $e";
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(Object? value) {
    final amount = value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
    final raw = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp $buffer';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF004E92))),
      );
    }

    if (_errorMsg != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text(_errorMsg!, style: GoogleFonts.plusJakartaSans(color: Colors.red))),
      );
    }

    double pemasukan = double.tryParse(_summaryData['total_income']?.toString() ?? '0') ?? 0.0;
    double pengeluaran = double.tryParse(_summaryData['total_expense']?.toString() ?? '0') ?? 0.0;
    double saldoAkhir = double.tryParse(_summaryData['current_balance']?.toString() ?? '0') ?? 0.0;

    // Ekstrak statistik iuran bulanan
    int totalKk = int.tryParse(_iuranStats['total_kk']?.toString() ?? '0') ?? 0;
    int sudahBayar = int.tryParse(_iuranStats['sudah_bayar_kk']?.toString() ?? '0') ?? 0;
    int belumBayar = totalKk - sudahBayar;
    
    double progressPercent = totalKk > 0 ? (sudahBayar / totalKk) : 0.0;
    double totalIuranTerkumpul = double.tryParse(_iuranStats['total_collected']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchAuditFinancialData,
        color: const Color(0xFF004E92),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Report Title
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(4),
                      ),
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
                      'Periode: ${_summaryData['current_period_label'] ?? 'Oktober 2026'}',
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
                value: _formatRupiah(pemasukan),
                icon: Icons.trending_up_rounded,
                color: Colors.green[700]!,
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                label: 'TOTAL PENGELUARAN',
                value: _formatRupiah(pengeluaran),
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
                          _formatRupiah(saldoAkhir),
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
                        Text('${(progressPercent * 100).toStringAsFixed(0)}% Selesai', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE5EEF5),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF004E92)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildMiniStat('Total KK', '$totalKk KK')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMiniStat('Sudah Bayar', '$sudahBayar KK')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildMiniStat('Belum Bayar', '$belumBayar KK', valueColor: Colors.red[700])),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMiniStat('Nominal/KK', _formatRupiah(_iuranStats['tariff_per_kk'] ?? 150000))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Terkumpul', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        Text(_formatRupiah(totalIuranTerkumpul), style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF004E92))),
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
                    
                    // Loop Dinamis List Pengeluaran dari Database
                    ..._expenseList.map((expense) => _buildExpenseItem(
                          expense['title'] ?? 'Pengeluaran',
                          expense['notes'] ?? 'Keterangan',
                          _formatRupiah(expense['amount']),
                        )),

                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFFFFF5F5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Pengeluaran', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.red[800])),
                          Text(_formatRupiah(pengeluaran), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.red[800])),
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
                    MaterialPageRoute(
                      builder: (context) => ReportPreviewScreen(
                        summary: _summaryData,
                        expenses: _expenseList,
                        iuranStats: _iuranStats,
                      ),
                    ),
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