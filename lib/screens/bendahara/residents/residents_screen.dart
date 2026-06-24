import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/core/constants/api_endpoints.dart';

class ResidentsScreen extends StatefulWidget {
  const ResidentsScreen({super.key});

  @override
  State<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends State<ResidentsScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _allResidents = [];
  List<dynamic> _filteredResidents = [];
  
  bool _isLoading = true;
  String? _errorMsg;
  String _searchQuery = "";
  String _selectedStatusFilter = "Semua Status"; // Semua Status, Lunas, Belum Bayar

  @override
  void initState() {
    super.initState();
    _loadResidentsData();
  }

  // 1. Ambil data gabungan status iuran warga dari Laravel Backend
  Future<void> _loadResidentsData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });

      // Menggunakan ID default 'all' atau ID periode aktif untuk memicu data global periodPayments
      final url = '${ApiEndpoints.iuranPeriods}/active/payments';
      final response = await _apiService.getList(url);

      if (response != null && response is List) {
        if (!mounted) return;
        setState(() {
          _allResidents = response;
          _filteredResidents = response;
          _applyFilterAndSearch();
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMsg = "Format data respon dari server tidak sesuai.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = "Gagal memuat data warga: $e";
        _isLoading = false;
      });
    }
  }

  // 2. Fungsi Filter Teks Pencarian Nama & Kategori Status Pembayaran
  void _applyFilterAndSearch() {
    List<dynamic> tempResults = List.from(_allResidents);

    // Saring berdasarkan Teks Pencarian Nama Warga
    if (_searchQuery.isNotEmpty) {
      tempResults = tempResults.where((warga) {
        final String fullName = warga['full_name'] ?? '';
        return fullName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Saring berdasarkan Dropdown Filter Status
    if (_selectedStatusFilter == "Lunas") {
      tempResults = tempResults.where((warga) => warga['is_paid_global'] == true).toList();
    } else if (_selectedStatusFilter == "Belum Bayar") {
      tempResults = tempResults.where((warga) => warga['is_paid_global'] == false).toList();
    }

    setState(() {
      _filteredResidents = tempResults;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadResidentsData, // Tarik ke bawah untuk refresh data otomatis
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Daftar Warga',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola data dan status pembayaran iuran warga',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              () {
                double totalKasMasuk = 0;
                double totalTunggakan = 0;
                int kkLunasCount = 0;

                for (var warga in _allResidents) {
                  if (warga['is_paid_global'] == true) kkLunasCount++;
                  
                  final List<dynamic> listTagihan = warga['tagihan'] ?? [];
                  for (var t in listTagihan) {
                    double nominal = double.tryParse(t['amount'].toString()) ?? 0.0;
                    if (t['is_paid'] == true) {
                      totalKasMasuk += nominal;
                    } else {
                      totalTunggakan += nominal;
                    }
                  }
                }

                double persenKepatuhan = _allResidents.isEmpty 
                    ? 0 
                    : (kkLunasCount / _allResidents.length) * 100;

                return Row(
                  children: [
                    // 1. KOTAK KAS MASUK
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50]!.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kas Masuk', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Rp ${_formatRupiah(totalKasMasuk)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green[900])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. KOTAK TUNGGAKAN
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50]!.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tunggakan', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.red[800], fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Rp ${_formatRupiah(totalTunggakan)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red[900])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. KOTAK KEPATUHAN WARGA
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004E92).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF004E92).withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kepatuhan', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF004E92), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${persenKepatuhan.toStringAsFixed(0)}% KK', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0D1B2A))),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }(),
              const SizedBox(height: 24),
              
              // Search Bar dengan Aksi OnChanged
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5EEF5)),
                ),
                child: TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilterAndSearch();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama warga pengurus...',
                    hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Filters Row (Bisa Diklik Interaktif)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChipFilter('Bulan: ', 'Agustus', Icons.calendar_month_rounded, () {}),
                    const SizedBox(width: 12),
                    _buildChipFilter('Status: ', _selectedStatusFilter, Icons.payments_rounded, _showStatusFilterDialog),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // MAIN BODY: Menangani Loading, Eror, Kosong, & List Data
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (_errorMsg != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(_errorMsg!, style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.w600)),
                  ),
                )
              else if (_filteredResidents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text('Warga tidak ditemukan.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredResidents.length,
                  itemBuilder: (context, index) {
                    final warga = _filteredResidents[index];
                    return _buildResidentItem(
                      warga['full_name'] ?? 'Warga RT',
                      warga['block_info'] ?? 'Blok / No',
                      warga['is_paid_global'] == true,
                      warga['tagihan'] ?? [], // 🌟 OPER ARRAY TAGIHAN KE SINI
                    );
                  },
                ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Tarik ke bawah untuk menyegarkan data...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipFilter(String prefix, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EEF5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[700]),
                children: [
                  TextSpan(text: prefix),
                  TextSpan(
                    text: label,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // Dialog Kecil untuk Memilih Filter Status
  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pilih Status Iuran', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ["Semua Status", "Lunas", "Belum Bayar"].map((status) {
            return ListTile(
              title: Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedStatusFilter = status;
                  _applyFilterAndSearch();
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResidentItem(String name, String block, bool isLunas, List<dynamic> listTagihan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      // 🌟 KUNCI DROPDOWN: Menghilangkan garis border bawaan ExpansionTile agar UI tetap bersih
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          
          // 1. TAMPILAN KEPALA DROPDOWN (PROFIL WARGA)
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isLunas ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.split(' ').map((e) => e[0]).take(2).join() : 'W',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: isLunas ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ),
          title: Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          subtitle: Text(
            block,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500]),
          ),
          
          // Icon panah dropdown diatur agar serasi dengan tema primer Wargify
          trailing: const Icon(
            Icons.keyboard_arrow_down_rounded, 
            color: AppColors.primary, 
            size: 24
          ),

          // 2. ISI DROPDOWN (RINCIAN TAGIHAN KETIKA DIKLIK)
          children: [
            // Garis pembatas tipis penanda batas area dropdown
            const Divider(height: 1, color: Color(0xFFF0F4F8)),
            const SizedBox(height: 12),
            
            // Tampilkan status ringkasan global di dalam dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status Global KK:",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLunas ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLunas ? 'Lunas Seluruhnya' : 'Ada Tunggakan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isLunas ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (listTagihan.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "🎉 Tidak ada data tagihan aktif untuk keluarga ini.",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.green[600], fontStyle: FontStyle.italic),
                ),
              )
            else
              // Render list iuran bulanan warga
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listTagihan.length,
                itemBuilder: (context, idx) {
                  final tagihan = listTagihan[idx];
                  final bool statusBayar = tagihan['is_paid'] == true;
                  final double nominal = double.tryParse(tagihan['amount'].toString()) ?? 0.0;
                  final String categoryName = tagihan['category_name'] ?? 'Iuran';
                  
                  final int m = int.tryParse(tagihan['month'].toString()) ?? 0;
                  final int y = int.tryParse(tagihan['year'].toString()) ?? 0;
                  const List<String> months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"];
                  final String labelPeriode = (m >= 1 && m <= 12) ? "${months[m - 1]} $y" : "Iuran";

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      children: [
                        Icon(
                          statusBayar ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          size: 16,
                          color: statusBayar ? Colors.green[600] : Colors.red[400],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "$categoryName ($labelPeriode)",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: statusBayar ? Colors.grey[400] : Colors.black87,
                              decoration: statusBayar ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        Text(
                          "Rp ${nominal.toStringAsFixed(0)}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusBayar ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}