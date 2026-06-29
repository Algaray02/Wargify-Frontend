import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import '../../../core/utils/app_error.dart';

class AddContributionScreen extends StatefulWidget {
  const AddContributionScreen({super.key});

  @override
  State<AddContributionScreen> createState() => _AddContributionScreenState();
}

class _AddContributionScreenState extends State<AddContributionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSaving = false;
  
  // 🌟 PERBAIKAN 1: Pindahkan durasi ke dalam State sebagai tipe data int murni (Default 1 Bulan)
  int _durationMonths = 1;

  // State untuk melacak kategori iuran yang dipilih dan nominalnya
  final Map<String, Map<String, dynamic>> _categories = {
    'arisan': {'name': 'Uang Kas Arisan', 'checked': false, 'amount': 20000.0},
    'kebersihan': {'name': 'Kebersihan', 'checked': false, 'amount': 15000.0},
    'keamanan': {'name': 'Keamanan', 'checked': false, 'amount': 15000.0},
    'sosial': {'name': 'Sosial', 'checked': false, 'amount': 10000.0},
    'lainnya': {'name': 'Lainnya', 'checked': false, 'amount': 5000.0},
  };

  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  void _calculateTotal() {
    double total = 0.0;
    _categories.forEach((key, value) {
      if (value['checked'] == true) {
        total += value['amount'];
      }
    });
    setState(() {
      _totalAmount = total;
    });
  }

  String _formatRupiah(double value) {
    String raw = value.round().toString();
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

  Future<void> _saveContributionPeriod() async {
    // Memastikan ada minimal satu kategori iuran yang dicentang
    List<String> selectedCategories = [];
    _categories.forEach((key, value) {
      if (value['checked'] == true) selectedCategories.add(key);
    });

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Iuran tidak boleh kosong!')),
      );
      return;
    }

    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu jenis iuran!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final int currentMonth = DateTime.now().month;
      final int currentYear = DateTime.now().year;

      final Map<String, dynamic> requestBody = {
        'period_name': _nameController.text,
        'month': currentMonth,
        'year': currentYear,
        // 🌟 PERBAIKAN 2: Mengirimkan langsung nilai int murni dari SegmentedButton ke API
        'duration_months': _durationMonths, 
        'categories': selectedCategories,
      };

      final response = await _apiService.post(ApiEndpoints.iuranPeriods, requestBody);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Iuran baru berhasil dibuka!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan iuran: ${AppError.userFriendly(e)}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Tambah Iuran Baru',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E6ED)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail pembuatan iuran',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Pilih kategori iuran yang ingin diaktifkan bulan ini',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildLabel('Nama Iuran / Periode'),
            _buildTextField('contoh: Iuran Bulan Mei 2026', controller: _nameController),
            const SizedBox(height: 24),
            
            _buildLabel('Pilih Jenis Iuran'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E6ED)),
              ),
              child: Column(
                children: _categories.keys.map((String key) {
                  return CheckboxListTile(
                    activeColor: const Color(0xFF0D47A1),
                    title: Text(
                      _categories[key]!['name'],
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _formatRupiah(_categories[key]!['amount']),
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                    ),
                    value: _categories[key]!['checked'],
                    onChanged: (bool? value) {
                      setState(() {
                        _categories[key]!['checked'] = value;
                        _calculateTotal();
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel('Total Akumulasi Tarif'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Terinput:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0D47A1)),
                  ),
                  Text(
                    _formatRupiah(_totalAmount),
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0D47A1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildLabel('Durasi Tagihan'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: const Color(0xFF0D47A1),
                  selectedForegroundColor: Colors.white,
                  // unselectedForegroundColor: Colors.grey[700],
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE0E6ED)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                segments: const [
                  ButtonSegment(
                    value: 1, 
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('1 Bulan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    icon: Icon(Icons.calendar_today_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: 3, 
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('3 Bulan (Triwulan)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    icon: Icon(Icons.date_range_rounded, size: 16),
                  ),
                ],
                selected: {_durationMonths},
                onSelectionChanged: (value) {
                  setState(() => _durationMonths = value.first);
                },
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveContributionPeriod,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E92),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Simpan & Mulai Iuran',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0D1B2A)),
      ),
    );
  }

  Widget _buildTextField(String hint, {TextEditingController? controller}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6ED)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[300], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}