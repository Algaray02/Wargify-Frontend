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
  Timer? _liveLocationTimer;
  bool _isSendingLiveLocation = false;
  bool _hasLiveLocationFix = false;
  final ValueNotifier<Position?> _livePositionNotifier = ValueNotifier<Position?>(null);
  bool _isLiveLocationPreviewActive = false;

  // --- Map ---
  final MapController _mapController = MapController();
  bool _isAutoCenter = true;

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
    _liveLocationTimer?.cancel();
    _gpsSubscription?.cancel();
    _livePositionNotifier.dispose();
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

  bool _isValidCoordinate(double? value) {
    return value != null && value.isFinite;
  }

  latlong2.LatLng? _safeLatLng(double? latitude, double? longitude) {
    if (!_isValidCoordinate(latitude) || !_isValidCoordinate(longitude)) {
      return null;
    }
    return latlong2.LatLng(latitude!, longitude!);
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

  /// Check if current user has already marked attendance today for this schedule
  bool _hasMarkedAttendanceToday(Map<String, dynamic>? schedule) {
    if (schedule == null || _currentUser == null) return false;

    final attendances = schedule['attendances'];
    if (attendances is! List) return false;

    final userId = _currentUser!.userId;
    return attendances.any(
      (att) => (att is Map) && att['user_id']?.toString() == userId,
    );
  }

  List<latlong2.LatLng> _parsePathDataFromDatabase(Map<String, dynamic>? schedule) {
    final List<latlong2.LatLng> points = [];
    if (schedule == null) return points;

    final log = schedule['ronda_log'] ?? schedule['rondaLog'];
    if (log == null) return points;

    final pathData = log['path_data'];
    if (pathData is List) {
      for (final item in pathData) {
        if (item is Map) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lng = double.tryParse(item['lng']?.toString() ?? '');
          if (lat != null && lng != null) {
            final latLng = _safeLatLng(lat, lng);
            if (latLng != null) {
              points.add(latLng);
            }
          }
        }
      }
    }
    return points;
  }

  void _startLocalTimerOnly() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _detikBerjalan++);
        if (_detikBerjalan % 10 == 0) {
          _fetchSchedules(background: true);
        }
      }
    });
  }

  void _startRondaAutomatically() {
    if (_rondaBerjalan) return;
    if (!_isUserCoordinator(_selectedSchedule)) return;

    final schedule = _selectedSchedule;
    final log = schedule?['ronda_log'] ?? schedule?['rondaLog'];
    final currentDurationSeconds = log != null ? (int.tryParse(log['duration']?.toString() ?? '0') ?? 0) : 0;

    _initGps().then((_) {
      if (!_gpsReady) return;
      setState(() {
        _rondaBerjalan = true;
        _pathPoints = _parsePathDataFromDatabase(schedule);
        _detikBerjalan = currentDurationSeconds;
      });

      final initialLatLng = _currentPosition == null
          ? null
          : _safeLatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      if (initialLatLng != null && !_pathPoints.contains(initialLatLng)) {
        _pathPoints.add(initialLatLng);
      }

      _startLiveLocationTracking(allowRondaLogs: true);
      _startLocalTimerOnly();
    });
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
      final allParsed = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final schedules = allParsed
          .where((s) => _isUserCoordinator(s) || _isUserMemberOfGroup(s))
          .toList();

      if (_rondaBerjalan && _selectedSchedule != null) {
        final currentScheduleId = _selectedSchedule!['schedule_id']?.toString();
        final updatedSchedule = schedules.firstWhere(
          (s) => s['schedule_id']?.toString() == currentScheduleId,
          orElse: () => <String, dynamic>{},
        );
        final status = updatedSchedule['status']?.toString().toUpperCase();
        if (status != null && status != 'ONGOING') {
          await _handleSelesaiRonda(force: true);
          if (!mounted) return;
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

      if (selected != null &&
          selected['status']?.toString().toUpperCase() == 'ONGOING') {
        final hasMarkedAtt = _hasMarkedAttendanceToday(selected);

        if (hasMarkedAtt) {
          if (!_rondaBerjalan) {
            if (_isUserCoordinator(selected)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _startRondaAutomatically();
              });
            } else {
              final log = selected['ronda_log'] ?? selected['rondaLog'];
              final currentDurationSeconds = log != null ? (int.tryParse(log['duration']?.toString() ?? '0') ?? 0) : 0;
              setState(() {
                _rondaBerjalan = true;
                _detikBerjalan = currentDurationSeconds;
                _pathPoints = _parsePathDataFromDatabase(selected);
              });
              _startLocalTimerOnly();
            }
          } else {
            if (!_isUserCoordinator(selected)) {
              setState(() {
                _pathPoints = _parsePathDataFromDatabase(selected);
              });
            }
          }
        } else {
          if (_rondaBerjalan) {
            setState(() {
              _rondaBerjalan = false;
            });
            _timer?.cancel();
          }
        }
      }
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
      setState(() {
        _sudahScan = true;
        final userId = _currentUser?.userId;
        if (userId != null) {
          final attendances = schedule['attendances'];
          if (attendances is List) {
            final attendancesList = List<Map<String, dynamic>>.from(attendances);
            if (!attendancesList.any((att) => att['user_id']?.toString() == userId)) {
              attendancesList.add({
                'user_id': userId,
                'attended_at': DateTime.now().toIso8601String(),
              });
              schedule['attendances'] = attendancesList;
            }
          } else {
            schedule['attendances'] = [
              {
                'user_id': userId,
                'attended_at': DateTime.now().toIso8601String(),
              }
            ];
          }
        }
      });
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

  double _calculateDistanceCovered() {
    if (_pathPoints.length < 2) return 0.0;
    double totalDist = 0.0;
    for (int i = 0; i < _pathPoints.length - 1; i++) {
      totalDist += Geolocator.distanceBetween(
        _pathPoints[i].latitude,
        _pathPoints[i].longitude,
        _pathPoints[i + 1].latitude,
        _pathPoints[i + 1].longitude,
      );
    }
    return totalDist / 1000.0; // convert to km
  }

  Future<void> _uploadRondaLog() async {
    final schedule = _selectedSchedule;
    if (schedule == null) return;

    final scheduleId = schedule['schedule_id']?.toString();
    if (scheduleId == null) return;

    final scheduleDate = schedule['schedule_date']?.toString();

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
          'distance_covered': _calculateDistanceCovered(),
          'session_date': scheduleDate,
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
        _livePositionNotifier.value = pos;
        _gpsReady = true;
      });
    } catch (e) {
      _showGpsError('Gagal mengakses GPS.');
    }
  }

  Future<void> _sendLiveLocation() async {
    if (!_rondaBerjalan || _isSendingLiveLocation) return;

    final schedule = _selectedSchedule;
    if (schedule == null) return;

    final scheduleId = schedule['schedule_id']?.toString();
    if (scheduleId == null) return;

    final scheduleDate = schedule['schedule_date']?.toString();

    _isSendingLiveLocation = true;
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
          'distance_covered': _calculateDistanceCovered(),
          'session_date': scheduleDate,
        },
      );
      if (schedule['ronda_log'] != null) {
        schedule['ronda_log']['duration'] = _detikBerjalan;
      } else if (schedule['rondaLog'] != null) {
        schedule['rondaLog']['duration'] = _detikBerjalan;
      } else {
        schedule['ronda_log'] = {
          'duration': _detikBerjalan,
        };
      }
      debugPrint('Sending live ronda location');
    } catch (e) {
      debugPrint('Failed to send live ronda location: $e');
    } finally {
      _isSendingLiveLocation = false;
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

  void _startLiveLocationTracking({required bool allowRondaLogs}) {
    _isAutoCenter = true;
    _isLiveLocationPreviewActive = true;
    _gpsSubscription?.cancel();
    _gpsSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        ).listen((pos) {
          final latLng = _safeLatLng(pos.latitude, pos.longitude);
          if (latLng == null) return;
          if (!mounted) return;
          setState(() {
            _currentPosition = pos;
            _livePositionNotifier.value = pos;
            if (_rondaBerjalan) {
              _pathPoints.add(latLng);
            }
          });
          if (allowRondaLogs && !_hasLiveLocationFix) {
            _hasLiveLocationFix = true;
            _liveLocationTimer?.cancel();
            _liveLocationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
              _sendLiveLocation();
            });
          }
          if (_isAutoCenter && (_rondaBerjalan || _isLiveLocationPreviewActive)) {
            _mapController.move(
              latLng,
              _mapController.camera.zoom,
            );
          }
        });
  }

  void _stopGpsTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _isLiveLocationPreviewActive = false;
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

    // Check if user is coordinator or member
    final isCoordinator = _isUserCoordinator(_selectedSchedule);
    final isMember = _isUserMemberOfGroup(_selectedSchedule);
    if (!isCoordinator && !isMember) {
      _showSnackBar(
        'Anda bukan anggota kelompok ronda untuk jadwal ini.',
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

    if (!isMainPos && !isCoordinator) {
      _showSnackBar(
        'Hanya koordinator yang bisa scan checkpoint ini.',
        backgroundColor: AppColors.danger,
      );
      return;
    }

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
      if (isCoordinator) {
        await _createCheckpointLog(checkpoint);
        if (!mounted) return;
        _appendCheckpointLog(checkpoint);
      }

      if (isMainPos) {
        if (!_hasMarkedAttendanceToday(_selectedSchedule)) {
          await _markAttendance();
        }
      }

      if (!mounted) return;
      setState(() {
        _sudahScan = _hasScannedMainPos(_selectedSchedule);
      });

      _showSnackBar(
        isMainPos
            ? (isCoordinator 
                ? 'Pos Utama berhasil discan. Ronda otomatis dimulai.'
                : 'Presensi Pos Utama berhasil!')
            : 'Checkpoint berhasil discan.',
        backgroundColor: AppColors.primary,
      );

      if (isMainPos && isCoordinator) {
        _startRondaAutomatically();
      } else if (isMainPos && !isCoordinator) {
        final log = _selectedSchedule?['ronda_log'] ?? _selectedSchedule?['rondaLog'];
        final currentDurationSeconds = log != null ? (int.tryParse(log['duration']?.toString() ?? '0') ?? 0) : 0;
        setState(() {
          _rondaBerjalan = true;
          _detikBerjalan = currentDurationSeconds;
        });
        _startLocalTimerOnly();
      }

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

    if (!_hasMarkedAttendanceToday(_selectedSchedule)) {
      await _markAttendance();
    }

    setState(() {
      _rondaBerjalan = true;
      _pathPoints = [];
    });

    final initialLatLng = _currentPosition == null
        ? null
        : _safeLatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    if (initialLatLng != null) {
      _pathPoints.add(initialLatLng);
    }

    _startLiveLocationTracking(allowRondaLogs: true);

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
    if (!force && !_isUserCoordinator(_selectedSchedule)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hanya koordinator yang dapat menyelesaikan ronda.',
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
    _liveLocationTimer?.cancel();
    _liveLocationTimer = null;
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
      _hasLiveLocationFix = false;
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

  Future<void> _openMap() async {
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

    if (!_gpsReady) {
      await _initGps();
      if (!mounted) return;
      if (!_gpsReady) return;
    }

    _startLiveLocationTracking(allowRondaLogs: _rondaBerjalan);

    await showModalBottomSheet(
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

    if (!_rondaBerjalan) {
      _liveLocationTimer?.cancel();
      _liveLocationTimer = null;
      _stopGpsTracking();
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  MAP SHEET
  // ─────────────────────────────────────────────────────────────

  Widget _buildMapSheet(ScrollController scrollController) {
    final checkpoints = (_selectedSchedule?['checkpoints'] as List?) ?? [];
    final scannedIds = _scannedCheckpointIds(_selectedSchedule);

    final checkpointMarkers = checkpoints.map((cp) {
      final data = cp is Map
          ? Map<String, dynamic>.from(cp)
          : <String, dynamic>{};
      final location = _safeLatLng(
        double.tryParse('${data['latitude']}'),
        double.tryParse('${data['longitude']}'),
      );
      if (location == null) return null;
      return {
        'id': data['checkpoint_id']?.toString(),
        'name': data['name']?.toString() ?? 'Checkpoint',
        'location': location,
        'isScanned': scannedIds.contains(data['checkpoint_id']?.toString()),
        'isMain': data['is_main_pos'] == true || data['is_main_pos'] == 1 || data['is_main_pos'] == '1',
      };
    }).whereType<Map<String, dynamic>>().toList();

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
                  'PETA RONDAA',
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ValueListenableBuilder<Position?>(
                      valueListenable: _livePositionNotifier,
                      builder: (context, position, _) {
                        final text = position == null
                            ? 'Lokasi live belum tersedia'
                            : 'Lat: ${position.latitude.toStringAsFixed(6)}  |  Long: ${position.longitude.toStringAsFixed(6)}';
                        return Text(
                          text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _centerMapToCurrentLocation,
                  icon: const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(
                    'Tengahkan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
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
              child: ValueListenableBuilder<Position?>(
                valueListenable: _livePositionNotifier,
                builder: (context, livePos, _) {
                  final livePoint = livePos != null
                      ? _safeLatLng(livePos.latitude, livePos.longitude)
                      : null;
                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: latlong2.LatLng(centerLat, centerLng),
                      initialZoom: 16.0,
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture && _isAutoCenter) {
                          setState(() {
                            _isAutoCenter = false;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.wargify',
                      ),
                       PolylineLayer(
                         polylines: [
                           if (_pathPoints.isNotEmpty)
                             Polyline(
                               points: _pathPoints,
                               color: AppColors.success,
                               strokeWidth: 4.0,
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
                          if (livePoint != null)
                            Marker(
                              point: livePoint,
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
                  );
                },
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

  void _centerMapToCurrentLocation() {
    final position = _livePositionNotifier.value;
    final latLng = position == null
        ? null
        : _safeLatLng(position.latitude, position.longitude);
    if (latLng == null) {
      _showSnackBar('Lokasi live belum tersedia.', backgroundColor: Colors.orange);
      return;
    }

    setState(() {
      _isAutoCenter = true;
    });
    _mapController.move(latLng, 16.0);
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
    final now = DateTime.now();
    return logs
        .whereType<Map>()
        .where((log) {
          final timestampStr = log['scanned_at'] ?? log['created_at'];
          if (timestampStr == null) return true;
          final date = DateTime.tryParse(timestampStr.toString());
          if (date == null) return true;
          final localDate = date.toLocal();
          return localDate.year == now.year &&
              localDate.month == now.month &&
              localDate.day == now.day;
        })
        .map((log) => log['checkpoint_id']?.toString())
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
              physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
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
              physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
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
                  ),
                  const SizedBox(height: 16),

                  // --- Persiapan Card (hanya kalau belum mulai) ---
                  if (!_rondaBerjalan)
                    RondaPersiapanCard(
                      sudahScan: _isUserCoordinator(_selectedSchedule)
                          ? _sudahScan
                          : _hasMarkedAttendanceToday(_selectedSchedule),
                      onScanTap: _handleScanQr,
                      isUserMember: _isUserMemberOfGroup(_selectedSchedule),
                      isUserCoordinator: _isUserCoordinator(_selectedSchedule),
                      isOngoing: _selectedSchedule?['status']?.toString().toUpperCase() == 'ONGOING',
                    ),

                  // --- Tombol Selesai Ronda ---
                  if (_rondaBerjalan) ...[
                    if (_isUserCoordinator(_selectedSchedule)) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _handleScanQr,
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
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Hanya koordinator regu ronda yang dapat memindai checkpoint dan mengakhiri ronda.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // --- Live Location & Checkpoints List ---
                  if (_selectedSchedule != null) ...[
                    const SizedBox(height: 20),
                    // Row/Header with "Live Location" Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CHECKPOINT RONDA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                        // Live Location Button (pindah dari pojok kanan atas)
                        OutlinedButton.icon(
                          onPressed: _openMap,
                          icon: const Icon(Icons.map_outlined, size: 16),
                          label: Text(
                            'Live Location',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // List of Checkpoints
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (_checkpointsForSchedule(_selectedSchedule).isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Belum ada data checkpoint.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ..._checkpointsForSchedule(_selectedSchedule).map((checkpoint) {
                                final cpId = checkpoint['checkpoint_id']?.toString();
                                final name = checkpoint['name']?.toString() ?? 'Checkpoint';
                                final isMain = checkpoint['is_main_pos'] == true ||
                                    checkpoint['is_main_pos'] == 1 ||
                                    checkpoint['is_main_pos'] == '1';
                                final isScanned = cpId != null &&
                                    _scannedCheckpointIds(_selectedSchedule).contains(cpId);

                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: checkpoint == _checkpointsForSchedule(_selectedSchedule).last
                                        ? null
                                        : Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                  ),
                                  child: Row(
                                    children: [
                                      // Status indicator (checked/unchecked)
                                      Icon(
                                        isScanned ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                        color: isScanned ? AppColors.success : Colors.grey.shade400,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (isMain)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  'Pos Utama',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Scanned status label
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isScanned ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isScanned ? 'TERSCAN' : 'BELUM SCAN',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isScanned ? AppColors.success : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
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
                    const SizedBox(height: 100),
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
