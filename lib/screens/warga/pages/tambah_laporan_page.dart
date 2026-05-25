import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';

class TambahLaporanPage extends StatefulWidget {
  const TambahLaporanPage({super.key});

  @override
  State<TambahLaporanPage> createState() => _TambahLaporanPageState();
}

class _TambahLaporanPageState extends State<TambahLaporanPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  String? _selectedKategori;
  bool _dropdownOpen = false;

  // Kategori sesuai ikon di halaman laporan
  final List<Map<String, dynamic>> _kategoriList = [
    {'value': 'electricity', 'label': 'Electricity (Listrik)', 'icon': Icons.lightbulb_outline},
    {'value': 'water', 'label': 'Water (Air)', 'icon': Icons.water_drop_outlined},
    {'value': 'road', 'label': 'Road (Jalan)', 'icon': Icons.construction_outlined},
    {'value': 'cleanliness', 'label': 'Cleanliness (Kebersihan)', 'icon': Icons.delete_outline},
    {'value': 'security', 'label': 'Security (Keamanan)', 'icon': Icons.shield_outlined},
  ];

  // Dummy location
  final String _lokasiBlok = 'Block B, House #42';
  final String _lokasiAlamat = 'Jl. Kenangan Raya, Kelurahan Indah, Jakarta Selatan';

  bool get _isFormValid =>
      _judulController.text.trim().isNotEmpty &&
      _selectedKategori != null &&
      _deskripsiController.text.trim().isNotEmpty;

  Map<String, dynamic>? get _selectedKategoriData {
    if (_selectedKategori == null) return null;
    return _kategoriList.firstWhere(
      (k) => k['value'] == _selectedKategori,
      orElse: () => _kategoriList.first,
    );
  }

  void _submit() {
    if (!_isFormValid) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Laporan berhasil dikirim!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // TODO: kirim ke backend, lalu pop
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_dropdownOpen) setState(() => _dropdownOpen = false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Lapor Fasilitas',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Issue Title ---
              _FieldLabel('ISSUE TITLE'),
              const SizedBox(height: 8),
              _InputField(
                controller: _judulController,
                hintText: 'e.g., Trafo njeblog',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // --- Category Dropdown ---
              _FieldLabel('CATEGORY'),
              const SizedBox(height: 8),
              _KategoriDropdown(
                isOpen: _dropdownOpen,
                selectedKategori: _selectedKategoriData,
                kategoriList: _kategoriList,
                onToggle: () => setState(() => _dropdownOpen = !_dropdownOpen),
                onSelect: (value) => setState(() {
                  _selectedKategori = value;
                  _dropdownOpen = false;
                }),
              ),
              const SizedBox(height: 20),

              // --- Detailed Description ---
              _FieldLabel('DETAILED DESCRIPTION'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.0)),
                ),
                child: TextField(
                  controller: _deskripsiController,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue in detail to help our team understand better...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Visual Evidence ---
              _FieldLabel('VISUAL EVIDENCE'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // TODO: image picker
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                      width: 1.5,
                      // Dashed border simulation via custom paint not needed; solid is fine
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add Photo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload JPG or PNG (Max 5MB)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Location Details ---
              _FieldLabel('LOCATION DETAILS'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lokasiBlok,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _lokasiAlamat,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: AppColors.success, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'By submitting, you agree that your report will be visible to\ncommunity moderators and local maintenance teams.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.plusJakartaSans(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Dropdown Kategori ────────────────────────────────────────────────────────

class _KategoriDropdown extends StatelessWidget {
  final bool isOpen;
  final Map<String, dynamic>? selectedKategori;
  final List<Map<String, dynamic>> kategoriList;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  const _KategoriDropdown({
    required this.isOpen,
    required this.selectedKategori,
    required this.kategoriList,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Trigger ---
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isOpen ? 0 : 12),
                bottomRight: Radius.circular(isOpen ? 0 : 12),
              ),
              border: Border.all(
                color: isOpen ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                if (selectedKategori != null) ...[
                  Icon(
                    selectedKategori!['icon'] as IconData,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedKategori!['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      'Drop-down',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                Icon(
                  isOpen ? Icons.chevron_left : Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),

        // --- Options ---
        if (isOpen)
          Container(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Column(
              children: kategoriList.map((k) {
                final isSelected = selectedKategori?['value'] == k['value'];
                return InkWell(
                  onTap: () => onSelect(k['value'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          k['icon'] as IconData,
                          size: 18,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          k['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (isSelected) ...[
                          const Spacer(),
                          const Icon(Icons.check, size: 16, color: AppColors.primary),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}