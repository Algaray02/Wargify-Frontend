import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/widgets/warga/iuran/total_dana_card.dart';
import 'package:wargify/widgets/warga/iuran/iuran_item_card.dart';

class IuranScreen extends StatefulWidget {
  const IuranScreen({super.key});

  @override
  State<IuranScreen> createState() => _IuranScreenState();
}

class _IuranScreenState extends State<IuranScreen> {
  final ApiService _apiService = ApiService();
  String _totalDana = 'Rp 42.500.000';

  List<Map<String, dynamic>> _daftarIuran = [];
  List<Map<String, dynamic>> _filteredIuran = [];
  String _filterStatus = 'Semua';
  bool _semuaLunas = false;
  bool _isLoading = true;
  String? _errorMessage;

  static const _monthAbbr = [
    '', 'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
    'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES',
  ];

  @override
  void initState() {
    super.initState();
    _fetchIuran();
  }

  Future<void> _fetchIuran() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await _apiService.getList(ApiEndpoints.myIuran);
      
      final timeFormatter = DateFormat('dd');
      final items = rows.map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        final period = data['period'] is Map
            ? Map<String, dynamic>.from(data['period'] as Map)
            : <String, dynamic>{};
        final categoryMap = (data['category'] ?? period['category']) is Map
            ? Map<String, dynamic>.from((data['category'] ?? period['category']) as Map)
            : <String, dynamic>{};

        final monthVal = data['month'] ?? period['month'];
        final month = int.tryParse('$monthVal') ?? 1;
        
        final amountPaidDouble = double.tryParse('${data['amount_paid']}') ?? 0.0;
        final amountPaid = amountPaidDouble.toInt();
        
        final amountDouble = double.tryParse('${data['amount'] ?? data['amount_paid']}') ?? 0.0;
        final amount = amountDouble.toInt();
        
        final paidAt = DateTime.tryParse('${data['paid_at']}');

        // Formatted full date & time (e.g. 09 Juni 2026, 14:21 WIB)
        String formattedFullPaidAt = '-';
        if (paidAt != null) {
          formattedFullPaidAt = DateFormat("dd MMMM yyyy, HH:mm 'WIB'", 'id').format(paidAt);
        }

        final periodName = data['period_name']?.toString() ?? period['period_name']?.toString() ?? 'Iuran';
        final isLunas = data['status']?.toString() == 'lunas' || data['status']?.toString() == 'paid';

        return <String, dynamic>{
          'payment_id': data['payment'] is Map
              ? data['payment']['payment_id']?.toString() ?? '-'
              : data['payment_id']?.toString() ?? '-',
          'period_name': periodName,
          'category_name': categoryMap['name']?.toString() ?? 'Umum',
          'amount_paid': amountPaid,
          'amount': amount,
          'paid_at_formatted': formattedFullPaidAt,
          'bulan': _monthAbbr[month.clamp(1, 12)],
          'tanggal': paidAt != null ? timeFormatter.format(paidAt) : '-',
          'judul': periodName,
          'status': isLunas ? 'Lunas' : 'Belum Lunas',
          'jumlah': _formatCurrency(isLunas ? amountPaid : amount),
        };
      }).toList();

      int totalPaid = 0;
      for (final item in items) {
        if (item['status'] == 'Lunas') {
          totalPaid += item['amount_paid'] as int;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalDana = _formatCurrency(totalPaid);
        _daftarIuran = items;
        _filteredIuran = _applyFilter(items);
        _semuaLunas = items.every((item) => item['status'] == 'Lunas');
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat riwayat iuran.';
      });
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> items) {
    if (_filterStatus == 'Semua') return items;
    return items.where((item) {
      if (_filterStatus == 'Lunas') return item['status'] == 'Lunas';
      if (_filterStatus == 'Belum Lunas') return item['status'] == 'Belum Lunas';
      return true;
    }).toList();
  }

  String _formatCurrency(int value) {
    final number = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
    return 'Rp $number';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchIuran,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Detail Iuran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monthly neighborhood contribution and financial transparency.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (_semuaLunas && _daftarIuran.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4EDDA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SEMUA IURAN LUNAS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            TotalDanaCard(totalDana: _totalDana),
            const SizedBox(height: 28),
            Text(
              'Daftar Iuran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_daftarIuran.isNotEmpty)
              _buildFilterChips(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_daftarIuran.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredIuran.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _filteredIuran[index];
                  return IuranItemCard(
                    bulan: item['bulan'] ?? '',
                    tanggal: item['tanggal'] ?? '',
                    judul: item['judul'] ?? '',
                    status: item['status'] ?? '',
                    jumlah: item['jumlah'] ?? '',
                    onTap: () => _showIuranDetail(item),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showIuranDetail(Map<String, dynamic> item) {
    final paymentId = item['payment_id'] ?? '-';
    final isLunas = item['status'] == 'Lunas';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Handle indicator
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status & Verified Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isLunas
                          ? AppColors.success.withOpacity(0.12)
                          : AppColors.danger.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLunas ? Icons.verified_rounded : Icons.pending_actions_rounded,
                      size: 54,
                      color: isLunas ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLunas ? 'Pembayaran Berhasil' : 'Belum Dibayar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isLunas ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['jumlah'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Receipt Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReceiptRow('Kategori', item['category_name'] ?? '-'),
                        const Divider(height: 24),
                        _buildReceiptRow('Periode', item['period_name'] ?? '-'),
                        const Divider(height: 24),
                        _buildReceiptRow('Waktu Bayar', isLunas ? (item['paid_at_formatted'] ?? '-') : 'Belum melakukan pembayaran'),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No. Referensi',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      isLunas ? paymentId : '-',
                                      textAlign: TextAlign.end,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isLunas) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: paymentId));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Nomor referensi berhasil disalin'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.copy_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isLunas) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Silakan tunjukkan QR Code keluarga Anda ke Pengurus RT / Bendahara untuk melakukan konfirmasi pembayaran.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'Lunas', 'Belum Lunas'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((label) {
          final isSelected = _filterStatus == label;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _filterStatus = label;
                  _filteredIuran = _applyFilter(_daftarIuran);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFE0E6ED),
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _fetchIuran,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 54, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat iuran',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Riwayat pembayaran iuran akan muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

