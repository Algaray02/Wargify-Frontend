import 'package:wargify/core/utils/app_error.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';

class SosTriggerScreen extends StatefulWidget {
  const SosTriggerScreen({super.key});

  @override
  State<SosTriggerScreen> createState() => _SosTriggerScreenState();
}

class _SosTriggerScreenState extends State<SosTriggerScreen> {
  static const Duration _holdDuration = Duration(seconds: 3);

  final ApiService _apiService = ApiService();
  bool _isHolding = false;
  bool _isSending = false;
  bool _isLoadingLocation = true;
  double _holdProgress = 0;
  Position? _position;
  String? _locationError;
  Timer? _holdTimer;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _cancelHold();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS perangkat belum aktif.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi belum diberikan.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!mounted) return;
      setState(() {
        _position = position;
        _isLoadingLocation = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationError = AppError.userFriendly(error);
        _isLoadingLocation = false;
      });
    }
  }

  void _startHold(LongPressStartDetails details) {
    if (_isSending || _isLoadingLocation) return;

    _cancelHold();
    setState(() {
      _isHolding = true;
      _holdProgress = 0;
    });

    final startedAt = DateTime.now();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
      final progress = elapsed / _holdDuration.inMilliseconds;
      if (mounted) {
        setState(() => _holdProgress = progress.clamp(0, 1).toDouble());
      }
    });

    _holdTimer = Timer(_holdDuration, () {
      _cancelHold(keepProgress: true);
      _showSendMessageDialog();
    });
  }

  void _endHold(LongPressEndDetails details) {
    if (_holdProgress < 1) {
      _cancelHold();
    }
  }

  void _cancelHold({bool keepProgress = false}) {
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    _holdTimer = null;
    _progressTimer = null;

    if (mounted) {
      setState(() {
        _isHolding = false;
        if (!keepProgress) _holdProgress = 0;
      });
    }
  }

  Future<void> _sendSos(String message) async {
    final position = _position;
    if (_isSending || position == null) return;

    setState(() => _isSending = true);
    try {
      await _apiService.post(ApiEndpoints.emergencyAlerts, {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'message': message.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SOS berhasil dikirim ke pengurus RT.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengirim SOS: ${AppError.userFriendly(error)}',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSendMessageDialog() {
    if (_position == null) {
      _loadCurrentLocation();
      return;
    }

    final messageController = TextEditingController(
      text: 'Darurat! Butuh pertolongan segera di lokasi saya.',
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency_share_rounded,
                    color: AppColors.danger,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Kirim SOS Sekarang?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tulis pesan singkat agar Ketua RT tahu situasi yang harus ditangani.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF0D1B2A),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Kebakaran kecil di depan rumah...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF0F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 14),
                _buildCoordinatePill(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final message = messageController.text.trim();
                      if (message.isEmpty) return;
                      Navigator.pop(dialogContext);
                      _sendSos(message);
                    },
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      'KIRIM SOS',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'BATAL',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _buttonLabel {
    if (_isSending) return 'MENGIRIM SOS...';
    if (_isHolding) {
      return '${(_holdProgress * 3).ceil().clamp(1, 3)} / 3 DETIK';
    }
    if (_isLoadingLocation) return 'MENCARI GPS...';
    if (_locationError != null) return 'GPS BELUM SIAP';
    return 'TAHAN 3 DETIK';
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
          'SOS Darurat',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCurrentLocation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.circle,
                        color: AppColors.danger,
                        size: 10,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SISTEM EMERGENCY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tahan Tombol SOS\nSelama 3 Detik',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1B2A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Setelah tahan 3 detik, anda bisa menulis pesan singkat sebelum lokasi GPS dikirim ke Ketua RT.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 34),
                GestureDetector(
                  onLongPressStart: _startHold,
                  onLongPressEnd: _endHold,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 286,
                        height: 286,
                        child: CircularProgressIndicator(
                          value: _holdProgress,
                          strokeWidth: 10,
                          backgroundColor: AppColors.danger.withOpacity(0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.danger,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        width: _isHolding ? 226 : 238,
                        height: _isHolding ? 226 : 238,
                        decoration: BoxDecoration(
                          color: _locationError == null
                              ? AppColors.danger
                              : Colors.grey[500],
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withOpacity(
                                _isHolding ? 0.4 : 0.24,
                              ),
                              blurRadius: _isHolding ? 34 : 24,
                              spreadRadius: _isHolding ? 8 : 2,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_tethering_rounded,
                              color: Colors.white,
                              size: 62,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _buttonLabel,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Jangan dilepas sebelum penuh',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.84),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                _buildLocationCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lokasi GPS',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingLocation)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_locationError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locationError!,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loadCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Coba Ambil Lokasi Lagi'),
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildLocationField(
                    'LATITUDE',
                    _position!.latitude.toStringAsFixed(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLocationField(
                    'LONGITUDE',
                    _position!.longitude.toStringAsFixed(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Akurasi sekitar ${_position!.accuracy.toStringAsFixed(0)} meter. Tarik halaman ke bawah untuk refresh GPS.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final label = _isLoadingLocation
        ? 'MENCARI'
        : _locationError != null
        ? 'GAGAL'
        : 'LIVE';
    final color = _isLoadingLocation
        ? AppColors.primary
        : _locationError != null
        ? AppColors.danger
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCoordinatePill() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'GPS: ${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLocationField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2FD),
        borderRadius: BorderRadius.circular(12),
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
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
