import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';

class KasActivityScreen extends StatefulWidget {
  const KasActivityScreen({super.key});

  @override
  State<KasActivityScreen> createState() => _KasActivityScreenState();
}

class _KasActivityScreenState extends State<KasActivityScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _logs = [];
  double _currentBalance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  String _selectedType = 'ALL';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCashActivity();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCashActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getMap(ApiEndpoints.treasurySummary),
        _apiService.getList(ApiEndpoints.treasuryLogs),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      final logs = (results[1] as List<dynamic>)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (!mounted) return;
      setState(() {
        _currentBalance = _toDouble(summary['current_balance']);
        _totalIncome = _toDouble(summary['total_income']);
        _totalExpense = _toDouble(summary['total_expense']);
        _logs = logs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengambil riwayat kas dari backend.';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    return _logs.where((log) {
      final type = log['type']?.toString() ?? '';
      final text = [
        _formatTitle(log['source']),
        log['description'],
        (log['recorder'] as Map?)?['full_name'],
      ].join(' ').toLowerCase();

      final matchesType = _selectedType == 'ALL' || type == _selectedType;
      final matchesSearch =
          _searchQuery.isEmpty || text.contains(_searchQuery.toLowerCase());

      return matchesType && matchesSearch;
    }).toList();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(dynamic value) {
    final amount = _toDouble(value).round();
    final number = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $number';
  }

  String _formatDate(String? value) {
    if (value == null) return '-';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '-';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month ${date.year}, $hour:$minute';
  }

  String _formatTitle(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return '-';

    return raw
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  void _showReceiptPreview(String receiptUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bukti Transaksi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D1B2A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.68,
                  ),
                  color: const Color(0xFFF4F7FA),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.network(
                      receiptUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          height: 260,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(
                          height: 260,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Bukti tidak dapat dimuat.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF0D1B2A),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Aktivitas Kas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0D1B2A),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCashActivity,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final logs = _filteredLogs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMiniStat(
                label: 'Pemasukan',
                value: _formatCurrency(_totalIncome),
                icon: Icons.arrow_downward_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStat(
                label: 'Pengeluaran',
                value: _formatCurrency(_totalExpense),
                icon: Icons.arrow_upward_rounded,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildFilters(),
        const SizedBox(height: 16),
        _buildSearchField(),
        const SizedBox(height: 20),
        Text(
          'Riwayat Aktivitas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0D1B2A),
          ),
        ),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          _buildEmptyState()
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EEF5)),
            ),
            child: Column(
              children: List.generate(logs.length, (index) {
                return Column(
                  children: [
                    _buildLogItem(logs[index]),
                    if (index < logs.length - 1)
                      const Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: Color(0xFFE5EEF5),
                      ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SALDO KAS SAAT INI',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.72),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(_currentBalance),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Dihitung dari seluruh pemasukan dan pengeluaran yang tercatat di database.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0D1B2A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        _buildFilterChip('ALL', 'Semua'),
        const SizedBox(width: 8),
        _buildFilterChip('INCOME', 'Pemasukan'),
        const SizedBox(width: 8),
        _buildFilterChip('EXPENSE', 'Pengeluaran'),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedType == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE5EEF5),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : const Color(0xFF0D1B2A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EEF5)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari sumber, deskripsi, atau pencatat',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final isExpense = log['type'] == 'EXPENSE';
    final source = _formatTitle(log['source']);
    final description = log['description']?.toString() ?? '-';
    final recorder = (log['recorder'] as Map?)?['full_name']?.toString();
    final createdAt = log['created_at']?.toString();
    final receiptUrl = log['receipt_url']?.toString() ?? '';
    final amount = _formatCurrency(log['amount']);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isExpense
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isExpense
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
              color: isExpense ? AppColors.danger : AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildMetaPill(_formatDate(createdAt)),
                    if (recorder != null && recorder.isNotEmpty)
                      _buildMetaPill('oleh $recorder'),
                    if (receiptUrl.isNotEmpty)
                      _buildMetaPill(
                        'lihat bukti',
                        icon: Icons.image_outlined,
                        onTap: () => _showReceiptPreview(receiptUrl),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}$amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isExpense ? AppColors.danger : AppColors.success,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpense
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpense ? 'Keluar' : 'Masuk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isExpense ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill(String label, {IconData? icon, VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: onTap == null
            ? const Color(0xFFF4F7FA)
            : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: onTap == null
            ? null
            : Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: onTap == null ? Colors.grey[600] : AppColors.primary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EEF5)),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 42, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Belum ada aktivitas kas',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Riwayat akan muncul setelah pemasukan atau pengeluaran dicatat.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5EEF5)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCashActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Coba Lagi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
