import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/widgets/common/ronda/ronda_timer_card.dart';
import 'package:wargify/widgets/common/ronda/ronda_persiapan_card.dart';
import 'package:wargify/widgets/common/ronda/jadwal_ronda_card.dart';
import 'package:wargify/widgets/common/ronda/riwayat_ronda_item.dart';

class RondaScreen extends StatefulWidget {
  const RondaScreen({super.key});

  @override
  State<RondaScreen> createState() => _RondaScreenState();
}

class _RondaScreenState extends State<RondaScreen> {
  final ApiService _apiService = ApiService();

  // --- State Ronda ---
  bool _sudahScan = false;
  bool _rondaBerjalan = false;
  int _detikBerjalan = 0;
  Timer? _timer;

  // --- GPS Tracking ---
  bool _gpsReady = false;
  Position? _currentPosition;
  List<latlong2.LatLng> _pathPoints = [];
  StreamSubscription<Position>? _gpsSubscription;

  // --- Map ---
  final MapController _mapController = MapController();

  // --- Data dari API ---
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allSchedules = [];
  List<Map<String, dynamic>> _jadwalMendatang = [];
  List<Map<String, dynamic>> _riwayatRonda = [];
  Map<String, dynamic>? _selectedSchedule;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsSubscription?.cancel();
    super.dispose();
  }

  String get _timerDisplay {
    final jam = _detikBerjalan ~/ 3600;
    final menit = (_detikBerjalan % 3600) ~/ 60;
    final detik = _detikBerjalan % 60;
    return '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
  }

  String get _lokasiDisplay {
    final schedule = _selectedSchedule;
    if (schedule == null) return 'Belum ada jadwal';

    final checkpoints = schedule['checkpoints'];
    if (checkpoints is List && checkpoints.isNotEmpty) {
      final mainPos = checkpoints.firstWhere(
        (c) => c['is_main_pos'] == true,
        orElse: () => checkpoints.first,
      );
      return mainPos['name']?.toString() ?? 'Pos Utama';
    }

    final group = schedule['group'];
    if (group is Map) {
      return group['name']?.toString() ?? 'Kelompok Ronda';
    }

    return 'Pos Ronda';
  }

  // ─────────────────────────────────────────────────────────────
  //  API CALLS
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = await _apiService.getList(ApiEndpoints.rondaSchedules);
      final schedules = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final now = DateTime.now();
      final mendatang = <Map<String, dynamic>>[];
      final riwayat = <Map<String, dynamic>>[];

      for (final s in schedules) {
        final dateStr = s['schedule_date']?.toString();
        final scheduleDate = dateStr != null ? DateTime.tryParse(dateStr) : null;
        final status = s['status']?.toString() ?? '';

        if (status == 'SCHEDULED' &&
            scheduleDate != null &&
            !scheduleDate.isBefore(DateTime(now.year, now.month, now.day))) {
          mendatang.add(s);
        } else if (status == 'COMPLETED') {
          riwayat.add(s);
        }
      }

      mendatang.sort((a, b) => (a['schedule_date'] ?? '').toString().compareTo(b['schedule_date'] ?? ''));
      riwayat.sort((a, b) => (b['schedule_date'] ?? '').toString().compareTo(a['schedule_date'] ?? ''));

      if (!mounted) return;
      setState(() {
        _allSchedules = schedules;
        _jadwalMendatang = mendatang;
        _riwayatRonda = riwayat;
        _selectedSchedule = mendatang.isNotEmpty ? mendatang.first : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat jadwal ronda.\n${e.toString()}';
      });
    }
  }

  Future<void> _markAttendance() async {
    final schedule = _selectedSchedule;
    if (schedule == null) return;

    final scheduleId = schedule['schedule_id']?.toString();
    if (scheduleId == null) return;

    try {
      await _apiService.post(ApiEndpoints.rondaAttendance, {
        'schedule_id': scheduleId,
      });
      if (!mounted) return;
      setState(() => _sudahScan = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Presensi ronda berhasil!',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal presensi: ${e.toString()}',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _uploadRondaLog() async {
    final schedule = _selectedSchedule;
    if (schedule == null) return;

    final scheduleId = schedule['schedule_id']?.toString();
    if (scheduleId == null) return;

    try {
      await _apiService.post(
        '${ApiEndpoints.rondaSchedules}/$scheduleId/logs',
        {
          'path_data': _pathPoints.map((p) => {
            'lat': p.latitude,
            'lng': p.longitude,
            'time': DateTime.now().toIso8601String(),
          }).toList(),
          'duration': _detikBerjalan,
        },
      );
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────
  //  GPS
  // ─────────────────────────────────────────────────────────────

  Future<void> _initGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showGpsError('GPS perangkat belum aktif.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showGpsError('Izin lokasi belum diberikan.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _gpsReady = true;
      });
    } catch (e) {
      _showGpsError('Gagal mengakses GPS.');
    }
  }

  void _showGpsError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _startGpsTracking() {
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _pathPoints.add(latlong2.LatLng(pos.latitude, pos.longitude));
      });
    });
  }

  void _stopGpsTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
  }

  // ─────────────────────────────────────────────────────────────
  //  ACTIONS
  // ─────────────────────────────────────────────────────────────

  Future<void> _handleScanQr() async {
    if (_selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada jadwal ronda hari ini.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    await _markAttendance();
  }

  Future<void> _handleMulaiRonda() async {
    await _initGps();
    if (!_gpsReady) return;

    setState(() {
      _rondaBerjalan = true;
      _pathPoints = [];
    });

    if (_currentPosition != null) {
      _pathPoints.add(latlong2.LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ));
    }

    _startGpsTracking();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _detikBerjalan++);
    });
  }

  Future<void> _handleSelesaiRonda() async {
    _timer?.cancel();
    _stopGpsTracking();

    if (_selectedSchedule != null) {
      await _uploadRondaLog();
    }

    if (!mounted) return;
    setState(() {
      _rondaBerjalan = false;
      _sudahScan = false;
      _detikBerjalan = 0;
      _pathPoints = [];
      _gpsReady = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ronda selesai! Terima kasih.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    _fetchSchedules();
  }

  void _openMap() {
    if (_selectedSchedule == null) return;

    final checkpoints = _selectedSchedule!['checkpoints'];
    if (checkpoints is! List || checkpoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada checkpoint untuk jadwal ini.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => _buildMapSheet(scrollController),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  MAP SHEET
  // ─────────────────────────────────────────────────────────────

  Widget _buildMapSheet(ScrollController scrollController) {
    final checkpoints = (_selectedSchedule?['checkpoints'] as List?) ?? [];
    final checkpointLogs = (_selectedSchedule?['checkpoint_logs'] as List?) ?? [];
    final scannedIds = checkpointLogs
        .map((l) => (l is Map) ? l['checkpoint_id']?.toString() : null)
        .whereType<String>()
        .toSet();

    final checkpointMarkers = checkpoints.map((cp) {
      final data = cp is Map ? Map<String, dynamic>.from(cp) : <String, dynamic>{};
      return {
        'id': data['checkpoint_id']?.toString(),
        'name': data['name']?.toString() ?? 'Checkpoint',
        'location': latlong2.LatLng(
          double.tryParse('${data['latitude']}') ?? 0,
          double.tryParse('${data['longitude']}') ?? 0,
        ),
        'isScanned': scannedIds.contains(data['checkpoint_id']?.toString()),
        'isMain': data['is_main_pos'] == true,
      };
    }).toList();

    final centerLat = checkpointMarkers.isNotEmpty
        ? (checkpointMarkers.first['location'] as latlong2.LatLng).latitude
        : -6.200000;
    final centerLng = checkpointMarkers.isNotEmpty
        ? (checkpointMarkers.first['location'] as latlong2.LatLng).longitude
        : 106.816666;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PETA RONDA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _mapStatusBadge(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _rondaBerjalan ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: latlong2.LatLng(centerLat, centerLng),
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.wargify',
                  ),
                  if (_pathPoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _pathPoints,
                          color: AppColors.primary.withOpacity(0.6),
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                  if (checkpointMarkers.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: checkpointMarkers
                              .map((m) => m['location'] as latlong2.LatLng)
                              .toList(),
                          color: Colors.orange.withOpacity(0.4),
                          strokeWidth: 2.0,
                          pattern: StrokePattern.dashed(segments: [8.0, 6.0]),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      ...checkpointMarkers.map((m) {
                        final isScanned = m['isScanned'] as bool;
                        final isMain = m['isMain'] as bool;
                        return Marker(
                          point: m['location'] as latlong2.LatLng,
                          width: 40,
                          height: 40,
                          child: Tooltip(
                            message: m['name'] as String,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isScanned
                                    ? AppColors.success
                                    : (isMain ? AppColors.primary : Colors.blue),
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  isScanned ? Icons.check : Icons.place,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_currentPosition != null)
                        Marker(
                          point: latlong2.LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mapStatusBadge() {
    if (_rondaBerjalan) return '● LIVE';
    if (_selectedSchedule != null) return 'TERJADWAL';
    return 'TIDAK ADA';
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────

  static const _bulanIndo = [
    '', 'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
    'JUL', 'AGT', 'SEP', 'OKT', 'NOV', 'DES',
  ];

  static const _hariIndo = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  Map<String, dynamic> _jadwalToCard(Map<String, dynamic> s) {
    final dateStr = s['schedule_date']?.toString();
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    final shiftStart = s['shift_start']?.toString();
    final shiftEnd = s['shift_end']?.toString();
    final startTime = shiftStart != null ? DateTime.tryParse(shiftStart) : null;
    final endTime = shiftEnd != null ? DateTime.tryParse(shiftEnd) : null;

    String waktu = '-';
    if (startTime != null && endTime != null) {
      waktu = '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
    } else if (startTime != null) {
      waktu = DateFormat('HH:mm').format(startTime);
    }

    String bulan = '';
    String tanggal = '';
    String hariNama = '';
    if (date != null) {
      bulan = _bulanIndo[date.month];
      tanggal = DateFormat('dd').format(date);
      hariNama = _hariIndo[date.weekday - 1];
    }

    final group = s['group'] is Map ? Map<String, dynamic>.from(s['group'] as Map) : <String, dynamic>{};
    final members = group['members'];
    final jumlahAnggota = members is List ? members.length : 0;

    final checkpoints = s['checkpoints'];
    String namaTempat = group['name']?.toString() ?? 'Pos Ronda';
    if (checkpoints is List && checkpoints.isNotEmpty) {
      final mainPos = checkpoints.firstWhere(
        (c) => c['is_main_pos'] == true,
        orElse: () => checkpoints.first,
      );
      namaTempat = mainPos['name']?.toString() ?? namaTempat;
    }

    return {
      'bulan': bulan,
      'tanggal': tanggal,
      'hariNama': hariNama,
      'namaTempat': namaTempat,
      'waktu': waktu,
      'status': 'Mendatang',
      'jumlahAnggota': jumlahAnggota,
    };
  }

  Map<String, String> _riwayatToCard(Map<String, dynamic> s) {
    final dateStr = s['schedule_date']?.toString();
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    String tanggal = '-';
    if (date != null) {
      tanggal = '${DateFormat('dd').format(date)} ${_bulanIndo[date.month]}';
    }

    final rondaLog = s['ronda_log'] is Map ? Map<String, dynamic>.from(s['ronda_log'] as Map) : null;
    final duration = rondaLog?['duration'];
    String durasi = '-';
    if (duration is num) {
      final jam = duration ~/ 3600;
      final menit = (duration % 3600) ~/ 60;
      final detik = duration % 60;
      durasi = '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
    }

    final group = s['group'] is Map ? Map<String, dynamic>.from(s['group'] as Map) : <String, dynamic>{};
    final namaTempat = group['name']?.toString() ?? 'Pos Ronda';

    final shiftStart = s['shift_start']?.toString();
    final shiftEnd = s['shift_end']?.toString();
    final startTime = shiftStart != null ? DateTime.tryParse(shiftStart) : null;
    final endTime = shiftEnd != null ? DateTime.tryParse(shiftEnd) : null;
    String shift = '-';
    if (startTime != null && endTime != null) {
      shift = '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
    }

    return {
      'namaTempat': namaTempat,
      'shift': shift,
      'durasi': durasi,
      'tanggal': tanggal,
      'status': 'Selesai',
    };
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchSchedules,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Coba Lagi', style: GoogleFonts.plusJakartaSans()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isEmpty = _allSchedules.isEmpty;

    return RefreshIndicator(
      onRefresh: _fetchSchedules,
      color: AppColors.primary,
      child: isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada jadwal ronda',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jadwal ronda akan muncul di sini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // --- Timer Card ---
                  RondaTimerCard(
                    timer: _timerDisplay,
                    lokasi: _lokasiDisplay,
                    isMulai: _rondaBerjalan,
                    onLokasiTap: _openMap,
                  ),
                  const SizedBox(height: 16),

                  // --- Persiapan Card (hanya kalau belum mulai) ---
                  if (!_rondaBerjalan)
                    RondaPersiapanCard(
                      sudahScan: _sudahScan,
                      onScanTap: _handleScanQr,
                      onMulaiTap: _handleMulaiRonda,
                    ),

                  // --- Tombol Selesai Ronda ---
                  if (_rondaBerjalan) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _handleSelesaiRonda,
                        icon: const Icon(Icons.stop_circle_outlined, size: 20),
                        label: Text(
                          'SELESAI RONDA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // --- Jadwal Mendatang ---
                  if (_jadwalMendatang.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'JADWAL MENDATANG',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._jadwalMendatang.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: JadwalRondaCard(
                          bulan: _jadwalToCard(s)['bulan'] ?? '',
                          tanggal: _jadwalToCard(s)['tanggal'] ?? '',
                          hariNama: _jadwalToCard(s)['hariNama'] ?? '',
                          namaTempat: _jadwalToCard(s)['namaTempat'] ?? '',
                          waktu: _jadwalToCard(s)['waktu'] ?? '',
                          status: _jadwalToCard(s)['status'] ?? '',
                          jumlahAnggota: _jadwalToCard(s)['jumlahAnggota'] ?? 0,
                          onTap: () {
                            setState(() => _selectedSchedule = s);
                            _openMap();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- Riwayat Ronda ---
                  if (_riwayatRonda.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RIWAYAT RONDA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._riwayatRonda.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RiwayatRondaItem(
                          namaTempat: _riwayatToCard(s)['namaTempat'] ?? '',
                          shift: _riwayatToCard(s)['shift'] ?? '',
                          durasi: _riwayatToCard(s)['durasi'] ?? '',
                          tanggal: _riwayatToCard(s)['tanggal'] ?? '',
                          status: _riwayatToCard(s)['status'] ?? '',
                          onTap: () => _openMap(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }
}
