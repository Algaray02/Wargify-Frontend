import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/core/utils/wib_datetime.dart';
import 'package:wargify/services/api_service.dart';
import 'ronda_history_detail_screen.dart';

class RondaHistoryScreen extends StatefulWidget {
  const RondaHistoryScreen({super.key});

  @override
  State<RondaHistoryScreen> createState() => _RondaHistoryScreenState();
}

class _RondaHistoryScreenState extends State<RondaHistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final rows = await _apiService.getList(ApiEndpoints.rondaHistory);
      if (!mounted) return;
      setState(() {
        _items = rows
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> item) async {
    final logId = item['log_id']?.toString();
    if (logId == null || logId.isEmpty) return;

    try {
      final detail = await _apiService.getMap(
        '${ApiEndpoints.rondaHistory}/$logId',
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RondaHistoryDetailScreen(detail: detail),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat detail ronda.')),
      );
    }
  }

  String _formatDate(String? value) {
    final date = parseWibDateTime(value);
    if (date == null) return '-';
    return DateFormat('EEEE, dd MMM yyyy').format(date);
  }

  String _formatDuration(dynamic value) {
    final seconds = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}j ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Riwayat Ronda',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Icon(
                    Icons.history_rounded,
                    size: 56,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Belum ada riwayat ronda',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openDetail(item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['group_name']?.toString() ?? 'Regu Ronda',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D1B2A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(item['session_date']?.toString()),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Divider(height: 22),
                          Row(
                            children: [
                              _stat(
                                'Koordinator',
                                item['coordinator_name']?.toString() ?? '-',
                              ),
                              _stat(
                                'Checkpoint',
                                '${item['checkpoint_logs_count'] ?? 0}',
                              ),
                              _stat(
                                'Durasi',
                                _formatDuration(item['duration']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Lihat detail',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
