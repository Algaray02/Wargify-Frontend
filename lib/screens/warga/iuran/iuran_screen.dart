import 'package:flutter/material.dart';
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
  final String _totalDana = 'Rp 42.500.000';

  List<Map<String, String>> _daftarIuran = [];
  List<Map<String, String>> _filteredIuran = [];
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
        final period = Map<String, dynamic>.from(
          (data['period'] ?? {}) as Map,
        );

        final isPaid = data['status']?.toString() == 'paid';
        final month = int.tryParse('${period['month']}') ?? 1;
        final amount = int.tryParse('${data['amount_paid'] ?? 0}') ?? 0;
        final paidAt = DateTime.tryParse('${data['paid_at']}');

        return <String, String>{
          'bulan': _monthAbbr[month.clamp(1, 12)],
          'tanggal': paidAt != null ? timeFormatter.format(paidAt) : '-',
          'judul': period['period_name']?.toString() ?? 'Iuran',
          'status': isPaid ? 'Lunas' : 'Belum Lunas',
          'jumlah': _formatCurrency(amount),
        };
      }).toList();

      if (!mounted) return;
      setState(() {
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

  List<Map<String, String>> _applyFilter(List<Map<String, String>> items) {
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showIuranDetail(Map<String, String> item) {
    final isLunas = item['status'] == 'Lunas';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLunas ? const Color(0xFFD4EDDA) : const Color(0xFFFFE5E5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['status'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLunas ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item['judul'] ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    '${item['bulan'] ?? ''} ${item['tanggal'] ?? ''}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jumlah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    item['jumlah'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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

