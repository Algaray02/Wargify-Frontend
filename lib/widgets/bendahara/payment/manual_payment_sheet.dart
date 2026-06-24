import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:dio/dio.dart';

class ManualPaymentSheet extends StatefulWidget {
  final String periodId; // Dioper dari ShowContributionQrScreen

  const ManualPaymentSheet({super.key, required this.periodId});

  @override
  State<ManualPaymentSheet> createState() => _ManualPaymentSheetState();
}

class _ManualPaymentSheetState extends State<ManualPaymentSheet> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _allPayments = [];
  List<Map<String, dynamic>> _allResidentsFlattened = [];
  List<Map<String, dynamic>> _filteredResidents = [];
  
  bool _isLoading = true;
  String? _errorMsg;
  String _searchQuery = "";
  String _activeTab = "Belum Bayar"; // Filter Tab Aktif

  // Melacak ID keluarga yang sukses ditandai lunas pada sesi ini
  final List<String> _tempMarkedPaidFamilyIds = [];

  @override
  void initState() {
    super.initState();
    _fetchPeriodPayments();
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

  // 1. Ambil Data Transaksi Real-time dari Laravel
  Future<void> _fetchPeriodPayments() async {
    if (!mounted) return;

    if (widget.periodId.isEmpty) {
      setState(() {
        _errorMsg = "Eror: ID Periode tidak ditemukan.";
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });

      final url = '${ApiEndpoints.iuranPeriods}/${widget.periodId}/payments';
      final response = await _apiService.getList(url);

      if (response != null && response is List) {
        List<Map<String, dynamic>> tempResidents = [];
        
        for (var item in response) {
          tempResidents.add({
            'family_id': item['family_id'],
            'full_name': item['full_name'],
            'head_of_family_name': item['head_of_family_name'],
            'block_info': item['block_info'],
            'is_paid': item['is_paid_global'] == true, // Status tab global
            'tagihan': item['tagihan'] ?? [],
          });
        }

        if (!mounted) return;

        setState(() {
          _allPayments = response; 
          _allResidentsFlattened = tempResidents;
          _applyFilterAndSearch();
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMsg = "Format data dari server salah atau kosong.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = "Eror Aplikasi: ${e.toString()}"; 
      }); 
    }
  }

  // 2. Logika Pemfilteran Tab dan Fitur Cari Sesuai Nama Masing-masing Warga
  void _applyFilterAndSearch() {
    List<Map<String, dynamic>> results = List.from(_allResidentsFlattened);

    // Filter berdasarkan Pencarian Teks Nama Individu Warga
    if (_searchQuery.isNotEmpty) {
      results = results.where((warga) {
        final String residentName = warga['full_name'] ?? '';
        return residentName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter berdasarkan Kategori Tab Aktif
    if (_activeTab == "Belum Bayar") {
      results = results.where((warga) => warga['is_paid'] == false).toList();
    } else if (_activeTab == "Sudah Bayar") {
      results = results.where((warga) => warga['is_paid'] == true).toList();
    }

    setState(() {
      _filteredResidents = results;
    });
  }

  // 3. Eksekusi Tembak API saat Centang Manual Diaktifkan per Komponen Iuran
  Future<void> _toggleManualPayment(String familyId, String targetPeriodId, double targetAmount, bool isChecked) async {
    if (!isChecked) return; 
    
    // ✨ KUNCI SINKRONISASI UTAMA: Update data master di memori induk secara senyap tanpa merusak layout
    for (var warga in _allResidentsFlattened) {
      if (warga['family_id'] == familyId) {
        final List<dynamic> listTagihan = warga['tagihan'] ?? [];
        for (var tagihan in listTagihan) {
          if (tagihan['period_id'] == targetPeriodId) {
            tagihan['is_paid'] = true;
          }
        }
        // Cek apakah setelah dicentang, semua komponen iuran warga ini sudah lunas semua
        final bool hasUnpaid = listTagihan.any((t) => t['is_paid'] == false);
        warga['is_paid'] = !hasUnpaid; // Update status global KK secara dinamis
      }
    }

    try {
      final Map<String, dynamic> requestBody = {
        'period_id': targetPeriodId,
        'family_id': familyId,
        'paid_by_user_id': null, 
        'amount_paid': targetAmount, 
      };

      final response = await _apiService.post(ApiEndpoints.iuranPayments, requestBody);

      if (!mounted) return;

      if (response != null && (response['success'] == true || response['payment_id'] != null)) {
        // Simpan ke temp IDs untuk keperluan tracker jika dibutuhkan
        _tempMarkedPaidFamilyIds.add(familyId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status iuran berhasil dicatat sementara'), 
            duration: Duration(seconds: 1)
          ),
        );
      } else {
        _rollbackStatus(familyId, targetPeriodId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['message'] ?? 'Gagal memperbarui status di server')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _rollbackStatus(familyId, targetPeriodId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    }
  }

  // Fungsi Pembantu untuk mengembalikan centangan jika transaksi API gagal
  void _rollbackStatus(String familyId, String targetPeriodId) {
    if (!mounted) return;
    
    setState(() {
      for (var warga in _allResidentsFlattened) {
        if (warga['family_id'] == familyId) {
          final List<dynamic> listTagihan = warga['tagihan'] ?? [];
          for (var tagihan in listTagihan) {
            if (tagihan['period_id'] == targetPeriodId) {
              tagihan['is_paid'] = false; // Kembalikan ke false jika gagal
            }
          }
          final bool hasUnpaid = listTagihan.any((t) => t['is_paid'] == false);
          warga['is_paid'] = !hasUnpaid;
        }
      }
      _applyFilterAndSearch(); // Saring ulang dan segarkan tampilan UI global
    });
  }

  // Hitung jumlah warga lunas secara dinamis dari state lokal
  int _getPaidCount() => _allResidentsFlattened.where((r) => r['is_paid'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Centang Pembayaran Manual',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _isLoading 
                                ? 'Menghitung warga...' 
                                : '${_getPaidCount()} / ${_allResidentsFlattened.length} KK sudah bayar',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilterAndSearch();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama warga / anggota keluarga...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Tabs Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab('Belum Bayar'),
                  _buildTab('Semua'),
                  _buildTab('Sudah Bayar'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Main Body Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMsg != null
                    ? Center(child: Text('$_errorMsg', style: const TextStyle(color: Colors.red)))
                    : _filteredResidents.isEmpty
                        ? Center(child: Text('Tidak ada data warga ditemukan', style: GoogleFonts.plusJakartaSans(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _filteredResidents.length,
                            itemBuilder: (context, index) {
                              final warga = _filteredResidents[index];
                              final bool isPaid = warga['is_paid'] == true;
                              
                              return isPaid
                                  ? _buildPaidResidentItem(warga)
                                  : _buildResidentItem(warga);
                            },
                          ),
          ),
          
          // Bottom Actions Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Ketika tombol selesai ditekan, panggil refresh total database dari server
                    _fetchPeriodPayments();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data berhasil disinkronkan ke server! 🎉'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004E92),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Selesai',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    final bool isSelected = _activeTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = label;
            _applyFilterAndSearch();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TAMPILAN WARGA YANG BELUM BAYAR IURAN (DROPDOWN EXPANSION TILE)
  Widget _buildResidentItem(Map<String, dynamic> warga) {
    final String name = warga['full_name'] ?? '-';
    final String block = warga['block_info'] ?? '-';
    final String headName = warga['head_of_family_name'] ?? '-';
    final String familyId = warga['family_id'] ?? '';
    final List<dynamic> listTagihan = warga['tagihan'] ?? [];
    
    // 🌟 1. Fungsi Helper merubah angka bulan (1-12) dari database menjadi Teks Bahasa Indonesia
    String getNamaBulanIndo(int monthNumber) {
      const List<String> months = [
        "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember"
      ];
      if (monthNumber >= 1 && monthNumber <= 12) {
        return months[monthNumber - 1];
      }
      return "Periode Lain";
    }

    // 🌟 2. GROUPING DATA: Kelompokkan secara dinamis berdasar data 'month' & 'year' yang dikirim Laravel
    final Map<String, List<dynamic>> groupedByMonth = {};
    
    for (var tagihan in listTagihan) {
      // Menangkap angka month dan year dari response JSON Laravel
      final int monthVal = int.tryParse(tagihan['month'].toString()) ?? 0;
      final int yearVal = int.tryParse(tagihan['year'].toString()) ?? 0;
      
      String headerKey = "";

      if (monthVal >= 1 && monthVal <= 12 && yearVal > 0) {
        // Gabungkan otomatis menjadi: "JUNI 2026", "JULI 2026", "AGUSTUS 2026", dst.
        headerKey = "${getNamaBulanIndo(monthVal)} $yearVal".toUpperCase();
      } else {
        // Fallback cadangan aman jika terjadi anomali data kosong
        final String rawPeriodName = tagihan['period_name'] ?? 'Periode Lain';
        headerKey = rawPeriodName.toUpperCase();
      }

      if (!groupedByMonth.containsKey(headerKey)) {
        groupedByMonth[headerKey] = [];
      }
      groupedByMonth[headerKey]!.add(tagihan);
    }
    
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setCardState) {
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
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              
              // 1. KEPALA DROPDOWN
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.split(' ').map((e) => e[0]).take(2).join() : 'W',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold, 
                      color: Colors.red[700],
                      fontSize: 14,
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
                "Kepala KK: $headName • $block",
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500]),
              ),
              trailing: const Icon(
                Icons.keyboard_arrow_down_rounded, 
                color: AppColors.primary, 
                size: 24
              ),

              // 2. ISI DROPDOWN (RINCIAN TAGIHAN & CHECKBOX MANUAL)
              children: [
                const Divider(height: 1, color: Color(0xFFF0F4F8)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Pilih iuran yang dibayar tunai:",
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedByMonth.entries.map((entry) {
                    final String namaBulanHeader = entry.key; // Hasil konversi: "JUNI 2026", "JULI 2026", dll
                    final List<dynamic> tagihanList = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sub-Header Nama Bulan Utama
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                          child: Text(
                            namaBulanHeader,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: const Color(0xFF004E92),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        // Looping murni data iuran kategori dengan Checkbox
                        ...tagihanList.map((tagihan) {
                          final bool sudahBayar = tagihan['is_paid'] == true;
                          final String periodId = tagihan['period_id'] ?? '';
                          final double nominal = double.tryParse(tagihan['amount'].toString()) ?? 0.0;
                          final String categoryName = tagihan['category_name'] ?? 'Iuran';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            key: ValueKey(periodId),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    activeColor: const Color(0xFF004E92),
                                    value: sudahBayar,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: sudahBayar 
                                        ? null 
                                        : (bool? checked) {
                                            if (checked == true) {
                                              setCardState(() {
                                                tagihan['is_paid'] = true;
                                              });
                                              _toggleManualPayment(familyId, periodId, nominal, checked!);
                                            }
                                          },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    categoryName, // Isinya murni string kategori dari DB, misal: "Iuran Kebersihan"
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13, 
                                      color: sudahBayar ? Colors.grey[400] : Colors.black87,
                                      decoration: sudahBayar ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatRupiah(nominal.round()),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, 
                                    fontWeight: FontWeight.bold, 
                                    color: sudahBayar ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAMPILAN WARGA YANG SUDAH LUNAS IURAN
  Widget _buildPaidResidentItem(Map<String, dynamic> warga) {
    final String name = warga['full_name'] ?? '-';
    final String headName = warga['head_of_family_name'] ?? '-';
    final String rawDate = warga['paid_at'] ?? '';
    final String formattedTime = rawDate.length > 16 ? rawDate.substring(0, 16).replaceAll('T', ' ') : 'Lunas';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6ED)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=$name&background=random'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "Kepala KK: $headName",
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500]),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 10, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Lunas',
                            style: GoogleFonts.plusJakartaSans(fontSize: 8, color: Colors.grey[700], fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedTime,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}