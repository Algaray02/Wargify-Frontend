import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';

class ActivityOption {
  final String id;
  final String title;
  final String type;
  final String location;

  const ActivityOption({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
  });

  String get label => title;

  String get subtitle {
    final typeLabel = type == 'RAPAT' ? 'Rapat' : 'Kegiatan Umum';
    return location.isEmpty ? typeLabel : '$typeLabel - $location';
  }

  factory ActivityOption.fromJson(Map<String, dynamic> json) {
    return ActivityOption(
      id: json['activity_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Kegiatan',
      type: json['type']?.toString() ?? 'KEGIATAN_UMUM',
      location: json['location_name']?.toString() ?? '',
    );
  }
}

class AddGalleryScreen extends StatefulWidget {
  const AddGalleryScreen({super.key});

  @override
  State<AddGalleryScreen> createState() => _AddGalleryScreenState();
}

class _AddGalleryScreenState extends State<AddGalleryScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _albumController = TextEditingController();

  bool _isLoadingActivities = true;
  bool _isSubmitting = false;
  DateTime _eventDate = DateTime.now();
  String? _selectedActivityId;
  List<ActivityOption> _activities = [];
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  @override
  void dispose() {
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivities() async {
    try {
      final rows = await _apiService.getList(ApiEndpoints.activities);
      final activities =
          rows
              .whereType<Map>()
              .map(
                (row) =>
                    ActivityOption.fromJson(Map<String, dynamic>.from(row)),
              )
              .where((activity) => activity.id.isNotEmpty)
              .toList()
            ..sort((a, b) => a.title.compareTo(b.title));

      if (!mounted) return;
      setState(() {
        _activities = activities;
        _isLoadingActivities = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingActivities = false);
      _showSnack('Gagal memuat daftar kegiatan: $error', isError: true);
    }
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 82);
    if (images.isEmpty || !mounted) return;

    setState(() => _selectedImages = [..._selectedImages, ...images]);
  }

  Future<void> _submit() async {
    final albumName = _albumController.text.trim();
    if (albumName.isEmpty || _isSubmitting) {
      _showSnack('Nama galeri wajib diisi.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final gallery = await _apiService.post(ApiEndpoints.galleries, {
        'album_name': albumName,
        'event_date': DateFormat('yyyy-MM-dd').format(_eventDate),
        'activity_id': _selectedActivityId,
      });

      final galleryId = gallery['gallery_id']?.toString() ?? '';
      if (galleryId.isNotEmpty && _selectedImages.isNotEmpty) {
        await _uploadImages(galleryId);
      }

      if (!mounted) return;
      _showSnack('Galeri berhasil dibuat.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal membuat galeri: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _uploadImages(String galleryId) async {
    final formData = FormData();
    for (final image in _selectedImages) {
      formData.files.add(
        MapEntry(
          'images[]',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ),
      );
    }

    await _apiService.postMultipart(
      '${ApiEndpoints.galleries}/$galleryId/images',
      formData,
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Galeri',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Buat Galeri Baru',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Album dapat dikaitkan ke kegiatan yang sudah dibuat atau disimpan sebagai album mandiri.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _buildCard(
            children: [
              _buildLabel('Nama galeri'),
              _buildTextField(
                controller: _albumController,
                hint: 'Contoh: Kerja Bakti Minggu Pagi',
              ),
              const SizedBox(height: 16),
              _buildLabel('Kegiatan terkait'),
              _buildActivityDropdown(),
              const SizedBox(height: 16),
              _buildLabel('Tanggal kegiatan'),
              _buildDatePicker(),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            children: [_buildLabel('Foto galeri'), _buildImagePicker()],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSubmitting ? 'Menyimpan...' : 'Simpan Galeri',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.grey[600],
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: Colors.grey[400],
        ),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: Colors.grey[500], size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FBFE),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(AppColors.primary),
      ),
    );
  }

  Widget _buildActivityDropdown() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1EAF3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedActivityId,
          isExpanded: true,
          hint: Text(
            'Album mandiri',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Album mandiri',
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
            ),
            ..._activities.map((activity) {
              return DropdownMenuItem<String?>(
                value: activity.id,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      activity.subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (value) => setState(() => _selectedActivityId = value),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _eventDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _eventDate = picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1EAF3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: Colors.grey[500],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd MMM yyyy').format(_eventDate),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 42,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  'Pilih foto galeri',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'JPG atau PNG, maksimal 8MB per foto',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final image = _selectedImages[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(image.path), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () =>
                          setState(() => _selectedImages.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _inputBorder([Color color = const Color(0xFFE1EAF3)]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }
}
