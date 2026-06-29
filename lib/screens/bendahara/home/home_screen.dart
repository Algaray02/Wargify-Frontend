import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/screens/bendahara/scan/show_contribution_qr_screen.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/user_model.dart';
import '../../../../services/api_service.dart';
import '../../../../widgets/bendahara/payment/manual_payment_sheet.dart';
import '../contribution/add_contribution_screen.dart';
import '../financial/add_income_screen.dart';
import '../financial/add_expense_screen.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';

class BendaharaHomePage extends StatefulWidget {
  final UserModel user;
  const BendaharaHomePage({super.key, required this.user});

  @override
  State<BendaharaHomePage> createState() => _BendaharaHomePageState();
}

class _BendaharaHomePageState extends State<BendaharaHomePage> {
  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    String cleanStr = value.toString().split('.')[0]; 
    int? numValue = int.tryParse(cleanStr);
    if (numValue == null) return value.toString();
    
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numValue.toString().replaceAllMapped(reg, (Match match) => '${match[1]}.');
  }
  
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _summaryData = {};
  Map<String, dynamic>? _activePeriod = {}; // ⬅️ 1. TAMBAHKAN VARIABEL UNTUK MENAMPUNG PERIODE IURAN
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTreasuryAndPeriodData(); // ⬅️ Panggil fungsi gabungan baru
  }

  // 2. FUNGSI BARU: Mengambil Data Keuangan SEKALIGUS Periode Iuran Aktif
 Future<void> _fetchTreasuryAndPeriodData() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // A. Ambil Data Summary Kas
      final summaryData = await _apiService.getMap(ApiEndpoints.treasurySummary);
      
      // B. Ambil Data List Periode (Pakai getList karena terbukti bisa ONLINE)
      final periodResponse = await _apiService.getList(ApiEndpoints.iuranPeriods);
    
      if (!mounted) return;

      setState(() {
        _summaryData = summaryData;
        
        if (periodResponse != null && periodResponse is List && periodResponse.isNotEmpty) {
          _activePeriod = periodResponse.first; // Ambil data iuran paling terbaru
        } else {
          _activePeriod = null; 
        }
        
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is DioException && e.response != null) {
          _errorMessage = "Error ${e.response?.statusCode}: ${e.response?.data['message'] ?? e.response?.data.toString()}";
        } else {
          _errorMessage = e.toString();
        }
        _isLoading = false;
      });
    }
  }

  @override 
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchTreasuryAndPeriodData,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTreasuryAndPeriodData, // ⬅️ Refresh akan memperbarui kas & list iuran lunas
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              'Sore, ${widget.user.fullName.trim().split(' ')[0]}.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 24),
            
            // Card Kas Utama
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
                        _formatNumber(_summaryData?['current_balance'] ?? '0'),
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
                      ).then((_) {
                        _fetchTreasuryAndPeriodData();
                      });
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
            
            // Card Status Penagihan Warga
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
                            'Status Penagihan Warga',
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
                              _activePeriod?['period_name'] ?? 'Tidak ada periode aktif',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.assessment_rounded, size: 20, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sistem Penagihan Aktif', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
                      Text(
                        _activePeriod != null && _activePeriod!.isNotEmpty ? 'Online' : 'Offline', 
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, 
                          fontWeight: FontWeight.w800, 
                          color: _activePeriod != null && _activePeriod!.isNotEmpty ? Colors.green : Colors.red
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: Color(0xFFE5EEF5),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gunakan menu scanner untuk melihat tunggakan per KK secara real-time',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 20),
                  
                  // 3. SEKARANG DATA YANG DIOPER SUDAH REAL PERIOD DATA (ANTI-EROR)
                  OutlinedButton(
                    onPressed: (_activePeriod == null || _activePeriod!.isEmpty) ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowContributionQrScreen(periodData: _activePeriod),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                    ),
                    child: Text(
                      'Tampilkan Iuran',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold, 
                        color: (_activePeriod == null || _activePeriod!.isEmpty) ? Colors.grey : AppColors.primary
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Sisa kode Keuangan & Summary ke bawah tetap sama persis milikmu...
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
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
                      );
                    },
                    child: _buildFinancialButton(
                      label: 'Pemasukan',
                      subtitle: 'Tambah saldo baru',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFFE8EAF6),
                      iconColor: const Color(0xFF3F51B5),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
                      );
                    },
                    child: _buildFinancialButton(
                      label: 'Pengeluaran',
                      subtitle: 'Catat biaya rutin',
                      icon: Icons.trending_down_rounded,
                      color: const Color(0xFFFFEBEE),
                      iconColor: const Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
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
                  _buildSummaryRow('TOTAL MASUK', 'Rp ${_formatNumber(_summaryData?['total_income'] ?? '0')}', Colors.blue[800]!, Icons.show_chart_rounded),
                  const SizedBox(height: 12),
                  _buildSummaryRow('TOTAL KELUAR', 'Rp ${_formatNumber(_summaryData?['total_expense'] ?? '0')}', Colors.red[800]!, Icons.auto_graph_rounded),
                ],
              ),
            ),
            const SizedBox(height: 24),
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