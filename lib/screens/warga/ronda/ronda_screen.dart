import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/models/user_model.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/services/auth/auth_service.dart';
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
  final AuthService _authService = AuthService();

  // --- User Data ---
  UserModel? _currentUser;

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
    _loadCurrentUser();
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
        (c) => c['is_main_pos'] == true || c['is_main_pos'] == 1 || c['is_main_pos'] == '1',
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
  //  PERMISSION & HELPER METHODS
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  /// Check if current user is a member of the group in the schedule
  bool _isUserMemberOfGroup(Map<String, dynamic>? schedule) {
    if (schedule == null || _currentUser == null) return false;

    final group = schedule['group'];
    if (group is! Map) return false;

    final members = group['members'];
    if (members is! List) return false;

    final userId = _currentUser!.userId;
    return members.any(
      (member) => (member is Map) && member['user_id']?.toString() == userId,
    );
  }

  /// Check if current user is the coordinator of the schedule
  bool _isUserCoordinator(Map<String, dynamic>? schedule) {
    if (schedule == null || _currentUser == null) return false;

    final coordinator = schedule['coordinator'];
    if (coordinator is! Map) return false;

    return coordinator['user_id']?.toString() == _currentUser!.userId;
  }

  // ─────────────────────────────────────────────────────────────
  //  API CALLS
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchSchedules({bool background = false}) async {
    if (!background) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final raw = await _apiService.getList(ApiEndpoints.rondaSchedules);
      final schedules = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (_rondaBerjalan && _selectedSchedule != null) {
        final currentScheduleId = _selectedSchedule!['schedule_id']?.toString();
        final updatedSchedule = schedules.firstWhere(
          (s) => s['schedule_id']?.toString() == currentScheduleId,
          orElse: () => <String, dynamic>{},
        );
        final status = updatedSchedule['status']?.toString().toUpperCase();
        if (status != null && status != 'ONGOING') {
          _handleSelesaiRonda(force: true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ronda diselesaikan otomatis karena jadwal telah berakhir.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
      }

      final now = DateTime.now();
      final mendatang = <Map<String, dynamic>>[];
      final riwayat = <Map<String, dynamic>>[];

      for (final s in schedules) {
        final dateStr = s['schedule_date']?.toString();
        final scheduleDate = dateStr != null
            ? DateTime.tryParse(dateStr)
            : null;
        final status = s['status']?.toString() ?? '';

        if ((status == 'SCHEDULED' || status == 'ONGOING') &&
            scheduleDate != null &&
            !scheduleDate.isBefore(DateTime(now.year, now.month, now.day))) {
          mendatang.add(s);
        } else if (status == 'COMPLETED') {
          riwayat.add(s);
        }
      }

      mendatang.sort(
        (a, b) => (a['schedule_date'] ?? '').toString().compareTo(
          b['schedule_date'] ?? '',
        ),
      );
      riwayat.sort(
        (a, b) => (b['schedule_date'] ?? '').toString().compareTo(
          a['schedule_date'] ?? '',
        ),
      );

      if (!mounted) return;
      final selected = mendatang.isNotEmpty ? mendatang.first : null;
      setState(() {
        _allSchedules = schedules;
        _jadwalMendatang = mendatang;
        _riwayatRonda = riwayat;
        _selectedSchedule = selected;
        _sudahScan = _hasScannedMainPos(selected);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
          'path_data': _pathPoints
              .map(
                (p) => {
                  'lat': p.latitude,
                  'lng': p.longitude,
                  'time': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
          'duration': _detikBerjalan,
        },
      );
    } catch (_) {}
  }

  Future<void> _createCheckpointLog(Map<String, dynamic> checkpoint) async {
    final schedule = _selectedSchedule;
    if (schedule == null) return;

    final scheduleId = schedule['schedule_id']?.toString();
    final checkpointId = checkpoint['checkpoint_id']?.toString();
    if (scheduleId == null || checkpointId == null) return;

    await _apiService.post(
      '${ApiEndpoints.rondaSchedules}/$scheduleId/checkpoint-logs',
      {
        'checkpoint_id': checkpointId,
      },
    );
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
    _gpsSubscription =
        Geolocator.getPositionStream(
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
      _showSnackBar(
        'Tidak ada jadwal ronda hari ini.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    // Check if user is coordinator
    if (!_isUserCoordinator(_selectedSchedule)) {
      _showSnackBar(
        'Hanya koordinator ronda yang bisa scan QR checkpoint.',
        backgroundColor: AppColors.danger,
      );
      return;
    }

    final checkpoints = _checkpointsForSchedule(_selectedSchedule);
    if (checkpoints.isEmpty) {
      _showSnackBar(
        'Tidak ada checkpoint untuk jadwal ini.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _CheckpointQrScannerScreen()),
    );
    if (!mounted || scannedCode == null || scannedCode.trim().isEmpty) return;

    final checkpoint = _findCheckpointByQrCode(checkpoints, scannedCode);
    if (checkpoint == null) {
      _showSnackBar(
        'QR checkpoint tidak sesuai dengan jadwal ronda ini.',
        backgroundColor: AppColors.danger,
      );
      return;
    }

    final scannedIds = _scannedCheckpointIds(_selectedSchedule);
    final checkpointId = checkpoint['checkpoint_id']?.toString();
    if (checkpointId != null && scannedIds.contains(checkpointId)) {
      _showSnackBar(
        'Checkpoint ini sudah discan.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final mainPos = _mainPosCheckpoint(_selectedSchedule);
    final mainPosId = mainPos?['checkpoint_id']?.toString();
    final isMainPos = checkpointId != null && checkpointId == mainPosId;
    final hasScannedMainPos =
        mainPosId != null && scannedIds.contains(mainPosId);

    if (!hasScannedMainPos && !isMainPos) {
      _showSnackBar(
        'Scan Pos Utama terlebih dahulu sebelum checkpoint lain.',
        backgroundColor: AppColors.danger,
      );
      return;
    }

    try {
      await _createCheckpointLog(checkpoint);
      if (isMainPos && !_sudahScan) {
        await _markAttendance();
      }
      if (!mounted) return;
      _appendCheckpointLog(checkpoint);
      setState(() {
        _sudahScan = _hasScannedMainPos(_selectedSchedule);
      });
      _showSnackBar(
        isMainPos
            ? 'Pos Utama berhasil discan. Ronda bisa dimulai.'
            : 'Checkpoint berhasil discan.',
        backgroundColor: AppColors.primary,
      );
      _fetchSchedules();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Gagal mencatat checkpoint: ${e.toString()}',
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _handleMulaiRonda() async {
    // Check if user is a member of the group
    if (!_isUserMemberOfGroup(_selectedSchedule)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anda bukan anggota grup ronda ini.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Check if the schedule is currently ongoing
    final scheduleStatus = _selectedSchedule?['status']?.toString().toUpperCase();
    if (scheduleStatus != 'ONGOING') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ronda tidak dapat dimulai karena jadwal belum berlangsung.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    await _initGps();
    if (!_gpsReady) return;

    setState(() {
      _rondaBerjalan = true;
      _pathPoints = [];
    });

    if (_currentPosition != null) {
      _pathPoints.add(
        latlong2.LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
      );
    }

    _startGpsTracking();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _detikBerjalan++);
        if (_detikBerjalan % 10 == 0) {
          _fetchSchedules(background: true);
        }
      }
    });
  }

  Future<void> _handleSelesaiRonda({bool force = false}) async {
    if (!force && !_areAllCheckpointsScanned(_selectedSchedule)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ronda belum bisa diselesaikan. Harap scan semua checkpoint terlebih dahulu.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    _timer?.cancel();
    _stopGpsTracking();

    if (_selectedSchedule != null) {
      final scheduleId = _selectedSchedule!['schedule_id']?.toString();
      if (scheduleId != null) {
        try {
          await _apiService.patch(
            '${ApiEndpoints.rondaSchedules}/$scheduleId',
            {
              'status': 'COMPLETED',
            },
          );
        } on DioException catch (e) {
          final message = e.response?.data is Map
              ? (e.response?.data['message']?.toString() ?? 'Gagal memperbarui status di server.')
              : 'Gagal memperbarui status di server.';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: $message',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        } catch (_) {}
      }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
    final checkpointLogs =
        (_selectedSchedule?['checkpoint_logs'] as List?) ?? [];
    final scannedIds = checkpointLogs
        .map((l) => (l is Map) ? l['checkpoint_id']?.toString() : null)
        .whereType<String>()
        .toSet();

    final checkpointMarkers = checkpoints.map((cp) {
      final data = cp is Map
          ? Map<String, dynamic>.from(cp)
          : <String, dynamic>{};
      return {
        'id': data['checkpoint_id']?.toString(),
        'name': data['name']?.toString() ?? 'Checkpoint',
        'location': latlong2.LatLng(
          double.tryParse('${data['latitude']}') ?? 0,
          double.tryParse('${data['longitude']}') ?? 0,
        ),
        'isScanned': scannedIds.contains(data['checkpoint_id']?.toString()),
        'isMain': data['is_main_pos'] == true || data['is_main_pos'] == 1 || data['is_main_pos'] == '1',
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
                    color: _rondaBerjalan
                        ? AppColors.success
                        : AppColors.textSecondary,
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.wargify',
                  ),
                  if (_pathPoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _pathPoints,
                          color: AppColors.primary.withValues(alpha: 0.6),
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
                          color: Colors.orange.withValues(alpha: 0.4),
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
                                    : (isMain
                                          ? AppColors.primary
                                          : Colors.blue),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
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
    '',
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MEI',
    'JUN',
    'JUL',
    'AGT',
    'SEP',
    'OKT',
    'NOV',
    'DES',
  ];

  static const _hariIndo = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
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
      waktu =
          '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
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

    final group = s['group'] is Map
        ? Map<String, dynamic>.from(s['group'] as Map)
        : <String, dynamic>{};
    final members = group['members'];
    final jumlahAnggota = members is List ? members.length : 0;

    final checkpoints = s['checkpoints'];
    String namaTempat = group['name']?.toString() ?? 'Pos Ronda';
    if (checkpoints is List && checkpoints.isNotEmpty) {
      final mainPos = checkpoints.firstWhere(
        (c) => c['is_main_pos'] == true || c['is_main_pos'] == 1 || c['is_main_pos'] == '1',
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

    final rondaLog = s['ronda_log'] is Map
        ? Map<String, dynamic>.from(s['ronda_log'] as Map)
        : null;
    final duration = rondaLog?['duration'];
    String durasi = '-';
    if (duration is num) {
      final jam = duration ~/ 3600;
      final menit = (duration % 3600) ~/ 60;
      final detik = duration % 60;
      durasi =
          '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
    }

    final group = s['group'] is Map
        ? Map<String, dynamic>.from(s['group'] as Map)
        : <String, dynamic>{};
    final namaTempat = group['name']?.toString() ?? 'Pos Ronda';

    final shiftStart = s['shift_start']?.toString();
    final shiftEnd = s['shift_end']?.toString();
    final startTime = shiftStart != null ? DateTime.tryParse(shiftStart) : null;
    final endTime = shiftEnd != null ? DateTime.tryParse(shiftEnd) : null;
    String shift = '-';
    if (startTime != null && endTime != null) {
      shift =
          '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
    }

    return {
      'namaTempat': namaTempat,
      'shift': shift,
      'durasi': durasi,
      'tanggal': tanggal,
      'status': 'Selesai',
    };
  }

  List<Map<String, dynamic>> _checkpointsForSchedule(
    Map<String, dynamic>? schedule,
  ) {
    final checkpoints = schedule?['checkpoints'];
    if (checkpoints is! List) return [];
    return checkpoints
        .whereType<Map>()
        .map((checkpoint) => Map<String, dynamic>.from(checkpoint))
        .toList();
  }

  Map<String, dynamic>? _mainPosCheckpoint(Map<String, dynamic>? schedule) {
    final checkpoints = _checkpointsForSchedule(schedule);
    if (checkpoints.isEmpty) return null;
    return checkpoints.firstWhere(
      (checkpoint) => checkpoint['is_main_pos'] == true || checkpoint['is_main_pos'] == 1 || checkpoint['is_main_pos'] == '1',
      orElse: () => checkpoints.first,
    );
  }

  Set<String> _scannedCheckpointIds(Map<String, dynamic>? schedule) {
    final logs = schedule?['checkpoint_logs'];
    if (logs is! List) return {};
    return logs
        .map((log) => log is Map ? log['checkpoint_id']?.toString() : null)
        .whereType<String>()
        .toSet();
  }

  bool _hasScannedMainPos(Map<String, dynamic>? schedule) {
    final mainPosId = _mainPosCheckpoint(
      schedule,
    )?['checkpoint_id']?.toString();
    if (mainPosId == null) return false;
    return _scannedCheckpointIds(schedule).contains(mainPosId);
  }

  bool _areAllCheckpointsScanned(Map<String, dynamic>? schedule) {
    if (schedule == null) return false;
    final checkpoints = _checkpointsForSchedule(schedule);
    if (checkpoints.isEmpty) return false;
    final scannedIds = _scannedCheckpointIds(schedule);
    return checkpoints.every((cp) {
      final cpId = cp['checkpoint_id']?.toString();
      return cpId != null && scannedIds.contains(cpId);
    });
  }

  Map<String, dynamic>? _findCheckpointByQrCode(
    List<Map<String, dynamic>> checkpoints,
    String rawCode,
  ) {
    final code = rawCode.trim();
    for (final checkpoint in checkpoints) {
      if (checkpoint['qr_code_data']?.toString().trim() == code) {
        return checkpoint;
      }
    }
    return null;
  }

  void _appendCheckpointLog(Map<String, dynamic> checkpoint) {
    final schedule = _selectedSchedule;
    if (schedule == null) return;

    final logs = schedule['checkpoint_logs'] is List
        ? List<dynamic>.from(schedule['checkpoint_logs'] as List)
        : <dynamic>[];
    final checkpointId = checkpoint['checkpoint_id']?.toString();
    if (checkpointId == null ||
        logs.any(
          (log) =>
              log is Map && log['checkpoint_id']?.toString() == checkpointId,
        )) {
      return;
    }

    logs.add({
      'checkpoint_id': checkpointId,
      'scanned_at': DateTime.now().toIso8601String(),
    });
    schedule['checkpoint_logs'] = logs;

    final scheduleId = schedule['schedule_id']?.toString();
    if (scheduleId == null) return;
    void updateList(List<Map<String, dynamic>> rows) {
      final index = rows.indexWhere(
        (row) => row['schedule_id']?.toString() == scheduleId,
      );
      if (index >= 0) rows[index]['checkpoint_logs'] = logs;
    }

    updateList(_allSchedules);
    updateList(_jadwalMendatang);
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: backgroundColor ?? AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchSchedules,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Coba Lagi', style: GoogleFonts.plusJakartaSans()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                        Icon(
                          Icons.shield_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
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
                      isUserMember: _isUserMemberOfGroup(_selectedSchedule),
                      isUserCoordinator: _isUserCoordinator(_selectedSchedule),
                      isOngoing: _selectedSchedule?['status']?.toString().toUpperCase() == 'ONGOING',
                    ),

                  // --- Tombol Selesai Ronda ---
                  if (_rondaBerjalan) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isUserCoordinator(_selectedSchedule)
                            ? _handleScanQr
                            : null,
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 20,
                        ),
                        label: Text(
                          'SCAN CHECKPOINT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    ..._jadwalMendatang.map((s) {
                      final card = _jadwalToCard(s);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: JadwalRondaCard(
                          bulan: card['bulan'] ?? '',
                          tanggal: card['tanggal'] ?? '',
                          hariNama: card['hariNama'] ?? '',
                          namaTempat: card['namaTempat'] ?? '',
                          waktu: card['waktu'] ?? '',
                          status: card['status'] ?? '',
                          jumlahAnggota: card['jumlahAnggota'] ?? 0,
                          onTap: () {
                            setState(() {
                              _selectedSchedule = s;
                              _sudahScan = _hasScannedMainPos(s);
                            });
                            _openMap();
                          },
                        ),
                      );
                    }),
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
                    ..._riwayatRonda.map((s) {
                      final card = _riwayatToCard(s);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RiwayatRondaItem(
                          namaTempat: card['namaTempat'] ?? '',
                          shift: card['shift'] ?? '',
                          durasi: card['durasi'] ?? '',
                          tanggal: card['tanggal'] ?? '',
                          status: card['status'] ?? '',
                          onTap: () => _openMap(),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CheckpointQrScannerScreen extends StatefulWidget {
  const _CheckpointQrScannerScreen();

  @override
  State<_CheckpointQrScannerScreen> createState() =>
      _CheckpointQrScannerScreenState();
}

class _CheckpointQrScannerScreenState
    extends State<_CheckpointQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isFlashOn = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;

    _isProcessing = true;
    _controller.stop();
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Kamera tidak dapat diakses.\nPastikan izin kamera sudah diberikan.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Scan Checkpoint',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Stack(
                      children: [
                        _buildCorner(top: 0, left: 0, angle: 0),
                        _buildCorner(top: 0, right: 0, angle: 90),
                        _buildCorner(bottom: 0, left: 0, angle: -90),
                        _buildCorner(bottom: 0, right: 0, angle: 180),
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _isFlashOn = !_isFlashOn);
                                _controller.toggleTorch();
                              },
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: _isFlashOn
                                      ? AppColors.primary
                                      : Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _isFlashOn
                                      ? Icons.flashlight_off_rounded
                                      : Icons.flashlight_on_rounded,
                                  color: _isFlashOn
                                      ? Colors.white
                                      : const Color(0xFF0D1B2A),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Arahkan kamera ke QR checkpoint ronda.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double angle,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle * 3.14159 / 180,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 4),
              left: BorderSide(color: AppColors.primary, width: 4),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
          ),
        ),
      ),
    );
  }
}
