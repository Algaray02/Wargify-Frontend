import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/models/user_model.dart';
import 'package:wargify/screens/auth/login_screen.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/services/app_notification_service.dart';
import 'package:wargify/services/auth/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  late final AppNotificationService _notificationService;

  Map<String, dynamic>? _profile;
  bool _pushNotifications = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _notificationService = AppNotificationService(apiService: _apiService);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getMap(ApiEndpoints.me),
        _notificationService.isPushEnabled(),
      ]);

      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>;
        _pushNotifications = results[1] as bool;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengambil profil dari backend.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _updatePushPreference(bool value) async {
    setState(() => _pushNotifications = value);
    await _notificationService.setPushEnabled(value);
  }

  Future<void> _submitProfileUpdate({
    required String fullName,
    required String phoneNumber,
    XFile? profilePhoto,
    required String password,
  }) async {
    setState(() => _isSaving = true);

    final formData = FormData.fromMap({
      'full_name': fullName.trim(),
      'phone_number': phoneNumber.trim(),
    });

    if (password.trim().isNotEmpty) {
      formData.fields.add(MapEntry('password', password.trim()));
    }

    if (profilePhoto != null) {
      formData.files.add(
        MapEntry(
          'profile_picture_file',
          await MultipartFile.fromFile(
            profilePhoto.path,
            filename: profilePhoto.name,
          ),
        ),
      );
    }

    try {
      final updated = await _apiService.patchMultipart(
        ApiEndpoints.me,
        formData,
      );
      try {
        await _authService.getProfile();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isSaving = false;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui profil. Periksa input kembali.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String get _fullName =>
      _profile?['full_name']?.toString() ?? widget.user.fullName;

  String get _role => _profile?['role']?.toString() ?? widget.user.role;

  String get _phoneNumber => _profile?['phone_number']?.toString() ?? '-';

  String get _username =>
      _profile?['username']?.toString() ?? widget.user.username;

  String get _profilePictureUrl =>
      _profile?['profile_picture_url']?.toString() ?? '';

  Map<String, dynamic>? get _family {
    final family = _profile?['family'];
    return family is Map<String, dynamic> ? family : null;
  }

  Map<String, dynamic>? get _household {
    final household = _family?['household'];
    return household is Map<String, dynamic> ? household : null;
  }

  bool get _isHeadOfFamily {
    return _family?['head_of_family_id']?.toString() ==
        _profile?['user_id']?.toString();
  }

  String get _roleLabel => _formatTitle(_role);

  String get _houseLabel {
    final block = _household?['block_number']?.toString();
    final house = _household?['house_number']?.toString();
    final parts = [
      if (block != null && block.isNotEmpty) 'Blok $block',
      if (house != null && house.isNotEmpty) 'No. $house',
    ];
    return parts.isEmpty ? 'Data rumah belum tersedia' : parts.join(' / ');
  }

  String _formatTitle(String value) {
    return value
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  ImageProvider _avatarProvider() {
    if (_profilePictureUrl.isNotEmpty) {
      return NetworkImage(_profilePictureUrl);
    }
    final encoded = Uri.encodeComponent(_fullName);
    return NetworkImage(
      'https://ui-avatars.com/api/?name=$encoded&background=0D1B2A&color=fff&size=128',
    );
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
          'Profil',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildSectionTitle('Data Akun'),
          _buildInfoSection([
            _infoRow(Icons.person_outline_rounded, 'Username', _username),
            _infoRow(Icons.phone_outlined, 'Nomor Telepon', _phoneNumber),
            _infoRow(Icons.home_outlined, 'Rumah', _houseLabel),
            _infoRow(
              Icons.qr_code_2_rounded,
              'QR Family',
              _family?['qr_code_data']?.toString() ?? '-',
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Preferensi'),
          _buildPreferenceSection(),
          const SizedBox(height: 24),
          _buildSectionTitle('Keamanan Akun'),
          _buildSecuritySection(),
          const SizedBox(height: 24),
          _buildLogoutCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 50, backgroundImage: _avatarProvider()),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _showEditProfileSheet,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _fullName,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _roleLabel.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _houseLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(
                Icons.verified,
                'DATA BACKEND',
                const Color(0xFFC1F3AF),
                const Color(0xFF2A6B2C),
              ),
              if (_isHeadOfFamily)
                _buildBadge(
                  Icons.home,
                  'KEPALA KELUARGA',
                  const Color(0xFFE3F2FD),
                  const Color(0xFF0D47A1),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showEditProfileSheet,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Notifikasi Push',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D1B2A),
              ),
            ),
          ),
          Switch.adaptive(
            value: _pushNotifications,
            onChanged: _updatePushPreference,
            activeColor: const Color(0xFF2A6B2C),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.password_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Kata sandi bisa diperbarui dari tombol Edit Profil.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D1B2A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6ED)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.logout_rounded, color: Colors.red[400], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Keluar dari Akun',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D1B2A),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _handleLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              elevation: 0,
              side: BorderSide(color: Colors.red[100]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('KELUAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditProfileSheet() {
    final nameController = TextEditingController(text: _fullName);
    final phoneController = TextEditingController(
      text: _phoneNumber == '-' ? '' : _phoneNumber,
    );
    final passwordController = TextEditingController();
    XFile? selectedPhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profil',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildPhotoPicker(
                      selectedPhotoName: selectedPhoto?.name,
                      onPick: () async {
                        final photo = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 82,
                          maxWidth: 1200,
                        );
                        if (photo != null) {
                          setModalState(() => selectedPhoto = photo);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(nameController, 'Nama Lengkap'),
                    const SizedBox(height: 12),
                    _buildTextField(phoneController, 'Nomor Telepon'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      passwordController,
                      'Password Baru',
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _submitProfileUpdate(
                                fullName: nameController.text,
                                phoneNumber: phoneController.text,
                                profilePhoto: selectedPhoto,
                                password: passwordController.text,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Profil',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPhotoPicker({
    required String? selectedPhotoName,
    required VoidCallback onPick,
  }) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E6ED)),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 24, backgroundImage: _avatarProvider()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedPhotoName ?? 'Upload Foto Profil',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Pilih gambar dari galeri',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.upload_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildBadge(
    IconData icon,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          ),
        ),
      ),
    );
  }
}
