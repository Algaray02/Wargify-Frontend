import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedStatus = 'Semua';
  
  // Date State
  int _day = DateTime.now().day;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _isDateFiltered = false;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  // Mock data untuk simulasi filter
  final List<Map<String, dynamic>> _allActivities = [
    {'title': 'Agus Setiawan', 'category': 'Iuran bulanan: Maret', 'date': '24 Oct, 09:42', 'amount': 'Rp 150.000', 'isLunas': true, 'isExpense': false},
    {'title': 'Perbaikan lampu', 'category': 'Maintenance', 'date': '23 Oct, 14:15', 'amount': '-Rp 2.4jt', 'isLunas': false, 'isExpense': true},
    {'title': 'Budi Pratama', 'category': 'Iuran bulanan: Maret', 'date': '23 Oct, 11:02', 'amount': 'Rp 75.000', 'isLunas': true, 'isExpense': false},
    {'title': 'Siti Aminah', 'category': 'Iuran bulanan: Maret', 'date': '22 Oct, 16:30', 'amount': 'Rp 500.000', 'isLunas': true, 'isExpense': false},
    {'title': 'Potong pohon', 'category': 'Operasional', 'date': '21 Oct, 10:20', 'amount': '-Rp 425k', 'isLunas': false, 'isExpense': true},
  ];

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Status',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 20),
              _buildStatusItem('Semua'),
              _buildStatusItem('Lunas'),
              _buildStatusItem('Belum Lunas'),
              _buildStatusItem('Keluar'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(String label) {
    bool isSelected = _selectedStatus == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedStatus = label);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF0D1B2A),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showDateFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Waktu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDatePresetItem('Minggu Ini', Icons.calendar_view_week_rounded),
                _buildDatePresetItem('Bulan Ini', Icons.calendar_view_month_rounded),
                _buildDatePresetItem('Tahun Ini', Icons.calendar_today_rounded),
                _buildDatePresetItem('Custom Tanggal', Icons.edit_calendar_rounded, isCustom: true),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePresetItem(String label, IconData icon, {bool isCustom = false}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (isCustom) {
          _showCustomDatePicker();
        } else {
          setState(() {
            _isDateFiltered = true;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCustomDatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Custom Tanggal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D1B2A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Selection Cards
                    Row(
                      children: [
                        // Day
                        Expanded(
                          flex: 2,
                          child: _buildPickerCard(
                            label: 'Tanggal',
                            value: _day.toString().padLeft(2, '0'),
                            onTap: () => _showWheelPicker(
                              context, 
                              title: 'Pilih Tanggal',
                              items: List.generate(31, (i) => (i + 1).toString().padLeft(2, '0')),
                              initialIndex: _day - 1,
                              onChanged: (val) => setModalState(() => _day = val + 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Month
                        Expanded(
                          flex: 3,
                          child: _buildPickerCard(
                            label: 'Bulan',
                            value: _months[_month - 1],
                            onTap: () => _showWheelPicker(
                              context,
                              title: 'Pilih Bulan',
                              items: _months,
                              initialIndex: _month - 1,
                              onChanged: (val) => setModalState(() => _month = val + 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Year
                        Expanded(
                          flex: 2,
                          child: _buildPickerCard(
                            label: 'Tahun',
                            value: _year.toString(),
                            onTap: () => _showWheelPicker(
                              context,
                              title: 'Pilih Tahun',
                              items: List.generate(11, (i) => (2020 + i).toString()),
                              initialIndex: _year - 2020,
                              onChanged: (val) => setModalState(() => _year = 2020 + val),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isDateFiltered = false;
                                _day = DateTime.now().day;
                                _month = DateTime.now().month;
                                _year = DateTime.now().year;
                              });
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: const BorderSide(color: Color(0xFFE5EEF5)),
                            ),
                            child: Text(
                              'Reset',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _isDateFiltered = true);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Terapkan Filter',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildPickerCard({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EEF5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D1B2A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWheelPicker(BuildContext context, {
    required String title,
    required List<String> items,
    required int initialIndex,
    required Function(int) onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: onChanged,
                  controller: FixedExtentScrollController(initialItem: initialIndex),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: items.length,
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          items[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D1B2A),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Pilih', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String dateDisplay = _isDateFiltered ? '$_day ${_months[_month-1].substring(0,3)} $_year' : 'Date';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5EEF5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Aktivitas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Catatan real-time seluruh arus keluar masuk keuangan warga.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildHeaderStat(
                        label: 'TOTAL BULANAN',
                        value: 'Rp 12.45jt',
                        color: AppColors.primary,
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildHeaderStat(
                        label: 'PERTUMBUHAN',
                        value: '+4.2%',
                        color: const Color(0xFFE5EEF5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Filters
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5EEF5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Filters',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterButton(
                        Icons.tune_rounded, 
                        _selectedStatus == 'Semua' ? 'Status' : _selectedStatus,
                        onTap: _showStatusFilter,
                        isActive: _selectedStatus != 'Semua',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterButton(
                        Icons.calendar_month_outlined, 
                        dateDisplay,
                        onTap: _showDateFilter,
                        isActive: _isDateFiltered,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5EEF5)),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search records...',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Ledger List
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5EEF5)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FBFE),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RESIDENT / CAT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'AMOUNT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                ...List.generate(_allActivities.length, (index) {
                  final item = _allActivities[index];
                  return Column(
                    children: [
                      _buildLedgerItem(
                        item['title'], 
                        item['category'], 
                        item['date'], 
                        item['amount'], 
                        item['isLunas'], 
                        isExpense: item['isExpense']
                      ),
                      if (index < _allActivities.length - 1) _buildDivider(),
                    ],
                  );
                }),
                
                // Pagination Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FBFE),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '5 of 128',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Row(
                        children: [
                          _buildPageNavButton(Icons.chevron_left_rounded),
                          const SizedBox(width: 8),
                          _buildPageNavButton(Icons.chevron_right_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({required String label, required String value, required Color color, bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.white.withOpacity(0.7) : Colors.grey[600],
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isPrimary ? Colors.white : const Color(0xFF0D1B2A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(IconData icon, String label, {VoidCallback? onTap, bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.primary : const Color(0xFFE5EEF5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? AppColors.primary : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, 
                fontWeight: FontWeight.w600, 
                color: isActive ? AppColors.primary : const Color(0xFF0D1B2A)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerItem(String title, String category, String date, String amount, bool isLunas, {bool isExpense = false}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isExpense ? const Color(0xFFE8F0F7) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                isExpense ? Icons.electric_bolt_rounded : Icons.person_rounded,
                color: isExpense ? Colors.blueGrey[400] : AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0D1B2A))),
                Text(category, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600])),
                Text(date, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[400])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isExpense ? const Color(0xFFD32F2F) : const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isLunas ? const Color(0xFFE8F5E9) : (isExpense ? const Color(0xFFFFEBEE) : const Color(0xFFFFEBEE)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLunas ? 'Lunas' : (isExpense ? 'Keluar' : 'Belum Bayar'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isLunas ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: const Color(0xFFE5EEF5).withOpacity(0.5), indent: 20, endIndent: 20);
  }

  Widget _buildPageNavButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5EEF5)),
      ),
      child: Icon(icon, size: 20, color: Colors.grey[600]),
    );
  }
}
