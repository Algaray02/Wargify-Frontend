import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/screens/rt/gallery/add_gallery_screen.dart';
import 'package:wargify/services/api_service.dart';

class EditGalleryScreen extends StatefulWidget {
  final Map<String, dynamic> gallery;

  const EditGalleryScreen({super.key, required this.gallery});

  @override
  State<EditGalleryScreen> createState() => _EditGalleryScreenState();
}

class _EditGalleryScreenState extends State<EditGalleryScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _albumController = TextEditingController();

  bool _isLoadingActivities = true;
  bool _isSubmitting = false;
  bool _isDeleting = false;
  DateTime _eventDate = DateTime.now();
  String? _selectedActivityId;
  List<ActivityOption> _activities = [];
  List<Map<String, dynamic>> _currentImages = [];
  List<XFile> _newImages = [];

  String get _galleryId => widget.gallery['gallery_id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _albumController.text = widget.gallery['album_name']?.toString() ?? '';
    _eventDate =
        DateTime.tryParse(widget.gallery['event_date']?.toString() ?? '') ??
        DateTime.now();
    _selectedActivityId = widget.gallery['activity_id']?.toString();
    if (_selectedActivityId != null && _selectedActivityId!.isEmpty) {
      _selectedActivityId = null;
    }
    final images = widget.gallery['images'];
    if (images is List) {
      _currentImages = images
          .whereType<Map>()
          .map((image) => Map<String, dynamic>.from(image))
          .toList();
    }
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

    setState(() => _newImages = [..._newImages, ...images]);
  }

  Future<void> _submit() async {
    final albumName = _albumController.text.trim();
    if (albumName.isEmpty || _isSubmitting || _galleryId.isEmpty) {
      _showSnack('Nama galeri wajib diisi.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _apiService.patch('${ApiEndpoints.galleries}/$_galleryId', {
        'album_name': albumName,
        'event_date': DateFormat('yyyy-MM-dd').format(_eventDate),
        'activity_id': _selectedActivityId,
      });

      if (_newImages.isNotEmpty) {
        await _uploadImages();
      }

      if (!mounted) return;
      _showSnack('Galeri berhasil diperbarui.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showSnack(
        'Gagal menyimpan perubahan galeri: ${_errorMessage(error)}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _uploadImages() async {
    final formData = FormData();
    for (final image in _newImages) {
      formData.files.add(
        MapEntry(
          'images[]',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ),
      );
    }

    await _apiService.postMultipart(
      '${ApiEndpoints.galleries}/$_galleryId/images',
      formData,
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map) {
          final messages = errors.values
              .whereType<List>()
              .expand((items) => items)
              .map((item) => item.toString())
              .where((message) => message.isNotEmpty)
              .toList();
          if (messages.isNotEmpty) return messages.join('\n');
        }

        final message = data['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }

      return 'Server menolak foto yang dipilih.';
    }

    return error.toString();
  }

  Future<void> _deleteImage(Map<String, dynamic> image) async {
    final imageId = image['image_id']?.toString() ?? '';
    if (imageId.isEmpty) return;

    try {
      await _apiService.delete('/gallery-images/$imageId');
      if (!mounted) return;
      setState(() => _currentImages.remove(image));
      _showSnack('Foto berhasil dihapus.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal menghapus foto: $error', isError: true);
    }
  }

  Future<void> _deleteGallery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hapus galeri?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Album dan semua foto di dalamnya akan dihapus permanen.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || _galleryId.isEmpty) return;

    setState(() => _isDeleting = true);
    try {
      await _apiService.delete('${ApiEndpoints.galleries}/$_galleryId');
      if (!mounted) return;
      _showSnack('Galeri berhasil dihapus.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal menghapus galeri: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
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
          'Edit Galeri',
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
            'Ubah Galeri',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Perbarui metadata album, tambahkan foto baru, atau hapus foto yang tidak diperlukan.',
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
                hint: 'Nama galeri',
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
            children: [
              _buildLabel('Foto saat ini'),
              _buildCurrentImages(),
              const SizedBox(height: 18),
              _buildLabel('Tambah foto baru'),
              _buildNewImagePicker(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting || _isDeleting ? null : _submit,
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
                _isSubmitting ? 'Menyimpan...' : 'Update Galeri',
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isSubmitting || _isDeleting ? null : _deleteGallery,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: Text(
                _isDeleting ? 'Menghapus...' : 'Hapus Galeri',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
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

  Widget _buildCurrentImages() {
    if (_currentImages.isEmpty) {
      return _buildEmptyBox('Belum ada foto di album ini.');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _currentImages.length,
      itemBuilder: (context, index) {
        final image = _currentImages[index];
        final url = image['image_url']?.toString() ?? '';
        return _buildNetworkThumbnail(
          url: url,
          onDelete: () => _deleteImage(image),
        );
      },
    );
  }

  Widget _buildNewImagePicker() {
    return Column(
      children: [
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(16),
          child: _buildEmptyBox(
            'Pilih foto tambahan',
            icon: Icons.add_photo_alternate_outlined,
          ),
        ),
        if (_newImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _newImages.length,
            itemBuilder: (context, index) {
              final image = _newImages[index];
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
                    child: _deleteBubble(
                      () => setState(() => _newImages.removeAt(index)),
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

  Widget _buildNetworkThumbnail({
    required String url,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFE5EEF5),
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
        Positioned(top: 4, right: 4, child: _deleteBubble(onDelete)),
      ],
    );
  }

  Widget _deleteBubble(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: AppColors.danger,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyBox(
    String message, {
    IconData icon = Icons.image_outlined,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1EAF3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D1B2A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _inputBorder([Color color = const Color(0xFFE1EAF3)]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }
}
