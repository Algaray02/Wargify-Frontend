import 'package:wargify/core/utils/app_error.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'pengumuman_screen.dart';

class EditPengumumanScreen extends StatefulWidget {
  final Announcement announcement;
  const EditPengumumanScreen({super.key, required this.announcement});

  @override
  State<EditPengumumanScreen> createState() => _EditPengumumanScreenState();
}

class _EditPengumumanScreenState extends State<EditPengumumanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _selectedType;
  late String _selectedStatus;
  XFile? _selectedBanner;
  bool _removeExistingBanner = false;
  bool _isSubmitting = false;

  final List<String> _types = [
    'Penting',
    'Kegiatan',
    'Himbauan',
    'Keuangan',
    'Lainnya',
  ];
  final List<String> _statuses = ['Draft', 'Aktif'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _contentController = TextEditingController(
      text: widget.announcement.content,
    );
    _selectedType = widget.announcement.type;
    _selectedStatus = widget.announcement.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _categoryCode(String label) {
    switch (label) {
      case 'Penting':
        return 'PENTING';
      case 'Kegiatan':
        return 'KEGIATAN';
      case 'Keuangan':
        return 'KEUANGAN';
      case 'Lainnya':
        return 'LAINNYA';
      case 'Himbauan':
      default:
        return 'HIMBAUAN';
    }
  }

  Future<void> _pickBanner() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image == null) return;
    setState(() {
      _selectedBanner = image;
      _removeExistingBanner = false;
    });
  }

  void _removeBanner() {
    setState(() {
      _selectedBanner = null;
      _removeExistingBanner = true;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final formData = FormData.fromMap({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _categoryCode(_selectedType),
        if (_removeExistingBanner) 'banner_url': '',
        if (_selectedBanner != null)
          'banner_file': await MultipartFile.fromFile(
            _selectedBanner!.path,
            filename: _selectedBanner!.name,
          ),
      });

      await _apiService.patchMultipart(
        '${ApiEndpoints.announcements}/${widget.announcement.id}',
        formData,
      );

      if (_selectedStatus == 'Aktif') {
        await _apiService.post(
          '${ApiEndpoints.announcements}/${widget.announcement.id}/publish',
          {},
        );
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        widget.announcement.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          type: _selectedType,
          status: _selectedStatus,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui draf: ${AppError.userFriendly(error)}',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Draf Pengumuman',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perbarui Draf',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Draf masih bisa diedit, diganti banner, atau langsung diterbitkan.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('JUDUL PENGUMUMAN'),
              TextFormField(
                controller: _titleController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Judul pengumuman tidak boleh kosong'
                    : null,
                decoration: _buildInputDecoration(
                  hint: 'Masukkan judul pengumuman...',
                  icon: Icons.title_rounded,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'KATEGORI',
                      value: _selectedType,
                      items: _types,
                      onChanged: (value) => setState(() {
                        _selectedType = value;
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'STATUS',
                      value: _selectedStatus,
                      items: _statuses,
                      onChanged: (value) => setState(() {
                        _selectedStatus = value;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('BANNER PENGUMUMAN'),
              _buildBannerPicker(),
              const SizedBox(height: 20),
              _buildLabel('ISI PENGUMUMAN'),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Isi pengumuman tidak boleh kosong'
                    : null,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Tuliskan isi pengumuman di sini...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.15),
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(18),
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(_isSubmitting ? 'Menyimpan...' : 'Simpan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              decoration: const InputDecoration(border: InputBorder.none),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerPicker() {
    final currentBanner = widget.announcement.bannerUrl;
    final hasExistingBanner =
        currentBanner != null &&
        currentBanner.isNotEmpty &&
        !_removeExistingBanner;

    return InkWell(
      onTap: _isSubmitting ? null : _pickBanner,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: _selectedBanner == null && !hasExistingBanner
            ? _buildEmptyBanner()
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _selectedBanner != null
                        ? Image.file(
                            File(_selectedBanner!.path),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            currentBanner!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Row(
                      children: [
                        _buildBannerAction(
                          icon: Icons.edit_rounded,
                          onTap: _pickBanner,
                        ),
                        const SizedBox(width: 8),
                        _buildBannerAction(
                          icon: Icons.close_rounded,
                          onTap: _removeBanner,
                          danger: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyBanner() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.image_outlined, color: AppColors.primary, size: 32),
        const SizedBox(height: 10),
        Text(
          'Pilih gambar dari galeri',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBannerAction({
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Material(
      color: danger ? AppColors.danger : AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
