import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../core/utils/app_error.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:wargify/core/constants/colors.dart';

class ReportPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> summary;
  final List<dynamic> expenses;
  final Map<String, dynamic> iuranStats;

  const ReportPreviewScreen({
    super.key,
    required this.summary,
    required this.expenses,
    required this.iuranStats,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final _previewKey = GlobalKey();

  String _formatRupiah(Object? value) {
    final amount = value is num
        ? value
        : num.tryParse(value?.toString() ?? '') ?? 0;
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

  String _cleanExpenseName(Object? value) {
    final text = (value?.toString().trim().isNotEmpty ?? false)
        ? value.toString().trim()
        : 'Pengeluaran Kas';
    return text
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Map<String, List<dynamic>> get _expensesByMonth {
    final grouped = <String, List<dynamic>>{};
    for (final expense in widget.expenses) {
      final rawDate = expense is Map ? expense['created_at'] : null;
      final date =
          DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();
      final label = DateFormat('MMMM yyyy', 'id_ID').format(date);
      grouped.putIfAbsent(label, () => []).add(expense);
    }
    return grouped;
  }

  num _expenseTotal(List<dynamic> expenses) {
    return expenses.fold<num>(0, (total, expense) {
      final amount = expense is Map ? expense['amount'] : 0;
      return total +
          (amount is num
              ? amount
              : num.tryParse(amount?.toString() ?? '') ?? 0);
    });
  }

  Future<void> _downloadReport(
    BuildContext context, {
    required double width,
    required double height,
  }) async {
    try {
      final boundary =
          _previewKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null) return;

      final pdf = pw.Document();
      final pageFormat = PdfPageFormat(width, height);
      final reportImage = pw.MemoryImage(pngBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(reportImage, fit: pw.BoxFit.fill),
        ),
      );

      final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'laporan-keuangan-rt-$timestamp.pdf',
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh laporan: ${AppError.userFriendly(error)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 KUNCI PERBAIKAN: Amankan konversi tipe data dinamis (int/double) via toString()
    double totalMasuk =
        double.tryParse(widget.summary['total_income']?.toString() ?? '0') ??
        0.0;
    double totalKeluar =
        double.tryParse(widget.summary['total_expense']?.toString() ?? '0') ??
        0.0;
    double saldoAkhir = totalMasuk - totalKeluar;

    int totalKk =
        int.tryParse(widget.iuranStats['total_kk']?.toString() ?? '0') ?? 0;
    int sudahBayar =
        int.tryParse(widget.iuranStats['sudah_bayar_kk']?.toString() ?? '0') ??
        0;
    double progressPercent = totalKk > 0 ? (sudahBayar / totalKk) * 100 : 0.0;
    double totalIuranTerkumpul =
        double.tryParse(
          widget.iuranStats['total_collected']?.toString() ?? '0',
        ) ??
        0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Color(0xFF0D1B2A),
          ),
          label: Text(
            'BACK',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D1B2A),
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                final box =
                    _previewKey.currentContext?.findRenderObject()
                        as RenderBox?;
                if (box == null) return;
                _downloadReport(
                  context,
                  width: box.size.width,
                  height: box.size.height,
                );
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Unduh Laporan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E92),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: RepaintBoundary(
              key: _previewKey,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wargify – Laporan Keuangan RT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF004E92),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ringkasan Laporan Bulanan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'PERIODE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              widget.summary['current_period_label'] ??
                                  'Oktober 2026',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D1B2A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.summary['generated_at'] ?? '25 Okt 2026',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Summary Row - Dinamis
                    Row(
                      children: [
                        _buildSummaryBox(
                          'Total Masuk',
                          _formatRupiah(totalMasuk),
                          Colors.blue[800]!,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryBox(
                          'Total Keluar',
                          _formatRupiah(totalKeluar),
                          Colors.red[800]!,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryBox(
                          'Saldo Akhir',
                          _formatRupiah(saldoAkhir),
                          const Color(0xFF004E92),
                          isHighlighted: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Iuran Summary Section - Dinamis
                    _buildSectionLabel('Iuran Summary'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5EEF5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'IURAN BULANAN KELUARGA',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF004E92),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _buildMiniInfo('TOTAL KK', '$totalKk'),
                                        const SizedBox(width: 16),
                                        _buildMiniInfo(
                                          'NOMINAL',
                                          '${(double.tryParse(widget.iuranStats['tariff_per_kk']?.toString() ?? '150000') ?? 150000 / 1000).toStringAsFixed(0)}k',
                                        ),
                                        const SizedBox(width: 16),
                                        _buildMiniInfo(
                                          'LUNAS',
                                          '$sudahBayar',
                                          color: Colors.green[700],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF004E92),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${progressPercent.toStringAsFixed(0)}%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TERKUMPUL',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatRupiah(totalIuranTerkumpul),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF004E92),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Expense Table - Dinamis
                    _buildSectionLabel('Rincian Pengeluaran'),
                    const SizedBox(height: 12),
                    _buildExpenseTable(totalKeluar),
                    const SizedBox(height: 32),

                    // Signature Footer
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'VERIFY',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 4,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'REPORT',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 4,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Generated by Wargify System',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 7,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Bendahara RT,',
                              style: GoogleFonts.plusJakartaSans(fontSize: 9),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: 80,
                              height: 0.5,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'BENDAHARA RT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(
    String label,
    String value,
    Color color, {
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlighted ? color : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isHighlighted ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(width: 2, height: 12, color: const Color(0xFF004E92)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 6,
            color: Colors.grey[500],
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF0D1B2A),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseTable(double totalExpense) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5EEF5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: const Color(0xFFF0F4F8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Pengeluaran',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Nominal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Ket',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_expensesByMonth.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Text(
                'Belum ada pengeluaran pada periode ini',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  color: Colors.grey[600],
                ),
              ),
            )
          else
            ..._expensesByMonth.entries.expand(
              (entry) => [
                _buildExpenseMonthHeader(
                  entry.key,
                  _formatRupiah(_expenseTotal(entry.value)),
                ),
                ...entry.value.map((expense) => _buildExpenseRow(expense)),
              ],
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: const Color(0xFFFFEBEE).withValues(alpha: 0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatRupiah(totalExpense),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseMonthHeader(String month, String total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      color: const Color(0xFFEAF2F8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            month,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF004E92),
            ),
          ),
          Text(
            total,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.red[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(dynamic expense) {
    final title = expense is Map ? expense['title'] : null;
    final amount = expense is Map ? expense['amount'] : null;
    final notes = expense is Map ? expense['notes'] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5EEF5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _cleanExpenseName(title),
              style: GoogleFonts.plusJakartaSans(fontSize: 8),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatRupiah(amount),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              notes?.toString() ?? '-',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 7,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
