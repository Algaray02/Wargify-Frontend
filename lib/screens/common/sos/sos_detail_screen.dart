import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/services/secure_session_storage.dart';

class SosDetailScreen extends StatefulWidget {
  final String alertId;

  const SosDetailScreen({super.key, required this.alertId});

  @override
  State<SosDetailScreen> createState() => _SosDetailScreenState();
}

class _SosDetailScreenState extends State<SosDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _alert;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isLocating = false;
  bool _isResolving = false;
  String? _role;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadCurrentPosition() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() => _currentPosition = position);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await SecureSessionStorage().getUserData();
      final rows = await _apiService.getList(ApiEndpoints.emergencyAlerts);
      Map<String, dynamic>? alert;
      for (final row in rows.whereType<Map>()) {
        final item = Map<String, dynamic>.from(row);
        if (item['alert_id']?.toString() == widget.alertId) {
          alert = item;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _role = user?['role']?.toString();
        _alert = alert;
        _isLoading = false;
        _error = alert == null ? 'Data SOS tidak ditemukan.' : null;
      });
      await _loadCurrentPosition();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat SOS.';
      });
    }
  }

  Future<void> _resolveSos() async {
    if (_alert == null || _isResolving) return;
    setState(() => _isResolving = true);

    try {
      await _apiService.post(
        '${ApiEndpoints.emergencyAlerts}/${widget.alertId}/resolve',
        {},
      );
      await _loadDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS berhasil ditandai aman.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menandai SOS aman.')));
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  String _senderName() {
    final sender = _alert?['sender'];
    if (sender is Map &&
        (sender['full_name']?.toString().isNotEmpty ?? false)) {
      return sender['full_name'].toString();
    }
    return _alert?['sender_name']?.toString() ?? 'Warga';
  }

  LatLng? _position() {
    final lat = double.tryParse(_alert?['latitude']?.toString() ?? '');
    final lng = double.tryParse(_alert?['longitude']?.toString() ?? '');
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  bool get _canResolve => _role == 'KETUA_RT' && _alert?['status'] == 'ACTIVE';

  String _distanceText(LatLng sosPosition) {
    final current = _currentPosition;
    if (current == null) {
      return _isLocating ? 'Mengambil lokasi...' : 'Lokasi kamu belum tersedia';
    }

    final meters = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      sosPosition.latitude,
      sosPosition.longitude,
    );
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final position = _position();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Detail SOS',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.danger,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _alert?['status'] == 'ACTIVE'
                                        ? 'SOS Aktif'
                                        : 'SOS Selesai',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                  Text(
                                    'Dikirim oleh ${_senderName()}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _alert?['message']?.toString() ??
                              'Butuh bantuan segera.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (position != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE5EEF5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.route_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jarak dari lokasimu',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _distanceText(position),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0D1B2A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _isLocating
                                ? null
                                : _loadCurrentPosition,
                            icon: _isLocating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    height: 360,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5EEF5)),
                    ),
                    child: position == null
                        ? const Center(
                            child: Text('Lokasi SOS tidak tersedia.'),
                          )
                        : FlutterMap(
                            options: MapOptions(
                              initialCenter: position,
                              initialZoom: 16,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.wargify.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  if (_currentPosition != null)
                                    Marker(
                                      point: LatLng(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      ),
                                      width: 56,
                                      height: 56,
                                      child: const Icon(
                                        Icons.person_pin_circle_rounded,
                                        color: AppColors.primary,
                                        size: 46,
                                      ),
                                    ),
                                  Marker(
                                    point: position,
                                    width: 72,
                                    height: 72,
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.danger,
                                      size: 52,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  if (_canResolve) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isResolving ? null : _resolveSos,
                      icon: const Icon(Icons.verified_user_rounded),
                      label: Text(
                        _isResolving ? 'Memproses...' : 'Tandai Sudah Aman',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
