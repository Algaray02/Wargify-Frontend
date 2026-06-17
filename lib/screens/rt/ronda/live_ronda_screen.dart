import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/services/api_service.dart';
import '../../../../../core/constants/colors.dart';

class LiveRondaScreen extends StatefulWidget {
  final Map<String, dynamic>? schedule;

  const LiveRondaScreen({super.key, this.schedule});

  @override
  State<LiveRondaScreen> createState() => _LiveRondaScreenState();
}

class _LiveRondaScreenState extends State<LiveRondaScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  Timer? _pollingTimer;
  Map<String, dynamic> _scheduleData = {};
  List<Map<String, dynamic>> _facilityReports = [];
  Map<String, dynamic> _rondaLog = {};

  @override
  void initState() {
    super.initState();
    _scheduleData = widget.schedule ?? {};
    _refreshLiveData();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshLiveData(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> get _schedule => _scheduleData;

  Future<void> _refreshLiveData() async {
    try {
      final scheduleId = _schedule['schedule_id']?.toString();

      final schedulesResult = await _apiService.getList(
        ApiEndpoints.rondaSchedules,
      );
      final reportsResult = await _apiService.getList(
        ApiEndpoints.facilityReports,
      );
      Map<String, dynamic> rondaLogData = {};

      if (scheduleId != null) {
        try {
          final logResult = await _apiService.getMap(
            '${ApiEndpoints.rondaSchedules}/$scheduleId/logs',
          );
          rondaLogData = Map<String, dynamic>.from(logResult as Map? ?? {});
        } catch (_) {
          // Ronda log endpoint might not exist yet
        }
      }

      final schedules =
          (schedulesResult as List?)
              ?.map((row) => Map<String, dynamic>.from(row as Map? ?? {}))
              .toList() ??
          [];
      final reports =
          (reportsResult as List?)
              ?.map((row) => Map<String, dynamic>.from(row as Map? ?? {}))
              .toList() ??
          [];

      final refreshedSchedule = scheduleId == null
          ? schedules.firstWhere(
              (item) => item['status'] == 'ONGOING',
              orElse: () => schedules.isNotEmpty ? schedules.first : _schedule,
            )
          : schedules.firstWhere(
              (item) => item['schedule_id']?.toString() == scheduleId,
              orElse: () => _schedule,
            );

      if (!mounted) return;
      setState(() {
        _scheduleData = refreshedSchedule;
        _facilityReports = reports;
        _rondaLog = rondaLogData;
      });
    } catch (_) {
      // Keep the last visible live data when polling fails.
    }
  }

  List<Map<String, dynamic>> get _participants {
    final group = _schedule['group'] is Map
        ? Map<String, dynamic>.from(_schedule['group'] as Map)
        : <String, dynamic>{};
    final members = group['members'];
    final checkpoints = _checkpoints;
    final fallback = checkpoints.isNotEmpty
        ? checkpoints.first['location'] as LatLng
        : const LatLng(-6.200000, 106.816666);
    if (members is! List) return [];
    return members.map((member) {
      final data = Map<String, dynamic>.from(member as Map);
      return {
        'name': data['full_name']?.toString() ?? 'Petugas',
        'image':
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data['full_name']?.toString() ?? 'Petugas')}&background=00468B&color=fff',
        'location': fallback,
      };
    }).toList();
  }

  List<Map<String, dynamic>> get _checkpoints {
    final checkpoints = _schedule['checkpoints'];
    final logs = _schedule['checkpoint_logs'] is List
        ? (_schedule['checkpoint_logs'] as List)
              .map((row) => Map<String, dynamic>.from(row as Map))
              .toList()
        : <Map<String, dynamic>>[];
    final scannedIds = logs
        .map((log) => log['checkpoint_id']?.toString())
        .whereType<String>()
        .toSet();
    if (checkpoints is! List) return [];
    return checkpoints.map((checkpoint) {
      final data = Map<String, dynamic>.from(checkpoint as Map);
      return {
        'id': data['checkpoint_id']?.toString(),
        'name': data['name']?.toString() ?? 'Checkpoint',
        'location': LatLng(
          double.tryParse('${data['latitude']}') ?? -6.200000,
          double.tryParse('${data['longitude']}') ?? 106.816666,
        ),
        'isScanned': scannedIds.contains(data['checkpoint_id']?.toString()),
      };
    }).toList();
  }

  List<Map<String, String>> get _reports {
    final shiftStart = DateTime.tryParse('${_schedule['shift_start']}');
    final shiftEnd = DateTime.tryParse('${_schedule['shift_end']}');
    final reports =
        _facilityReports.where((report) {
          final createdAt = DateTime.tryParse('${report['created_at']}');
          if (createdAt == null || shiftStart == null || shiftEnd == null) {
            return false;
          }
          final afterStart =
              createdAt.isAfter(shiftStart) ||
              createdAt.isAtSameMomentAs(shiftStart);
          final beforeEnd =
              createdAt.isBefore(shiftEnd) ||
              createdAt.isAtSameMomentAs(shiftEnd);
          return afterStart && beforeEnd;
        }).toList()..sort(
          (a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'),
        );

    return reports.map((report) {
      final reporter = report['reporter'] is Map
          ? Map<String, dynamic>.from(report['reporter'] as Map)
          : <String, dynamic>{};
      final createdAt = DateTime.tryParse('${report['created_at']}');
      return {
        'time': createdAt == null ? '-' : DateFormat('HH:mm').format(createdAt),
        'user': reporter['full_name']?.toString() ?? 'Warga',
        'text':
            '${report['title'] ?? 'Laporan fasilitas'} • ${report['category'] ?? '-'}',
        'status': report['status']?.toString() ?? 'SUBMITTED',
      };
    }).toList();
  }

  String get _shiftText {
    final start = DateTime.tryParse('${_schedule['shift_start']}');
    final end = DateTime.tryParse('${_schedule['shift_end']}');
    if (start == null || end == null) return '-';
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(start)} - ${formatter.format(end)} WIB';
  }

  String get _statusText {
    switch (_schedule['status']?.toString()) {
      case 'ONGOING':
        return 'Berjalan';
      case 'COMPLETED':
        return 'Selesai';
      case 'MISSED':
        return 'Terlewat';
      default:
        return 'Terjadwal';
    }
  }

  List<LatLng> get _trackingPath {
    final pathData = _rondaLog['path_data'];
    if (pathData is! List) return [];
    return pathData
        .whereType<Map>()
        .map((point) {
          final lat = double.tryParse('${point['latitude'] ?? point['lat']}');
          final lng = double.tryParse('${point['longitude'] ?? point['lng']}');
          return lat != null && lng != null ? LatLng(lat, lng) : null;
        })
        .whereType<LatLng>()
        .toList();
  }

  String get _trackingStats {
    final distance = _rondaLog['distance_covered'] ?? 0.0;
    final duration = _rondaLog['duration'] ?? 0;
    final hours = (duration / 3600).floor();
    final minutes = ((duration % 3600) / 60).floor();
    final durationText = hours > 0
        ? '$hours jam $minutes menit'
        : '$minutes menit';
    return 'Jarak: ${distance.toStringAsFixed(2)} km • Durasi: $durationText';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Peta
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _checkpoints.isNotEmpty
                  ? _checkpoints.first['location'] as LatLng
                  : const LatLng(-6.200000, 106.816666),
              initialZoom: 16.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.wargify',
              ),
              PolylineLayer(
                polylines: [
                  // Riwayat tracking path (jika ada)
                  if (_trackingPath.isNotEmpty)
                    Polyline(
                      points: _trackingPath,
                      color: Colors.orange.withOpacity(0.7),
                      strokeWidth: 3.0,
                    ),
                  // Route checkpoint (dashed line)
                  Polyline(
                    points: _checkpoints
                        .map((c) => c['location'] as LatLng)
                        .toList(),
                    color: AppColors.primary.withOpacity(0.5),
                    strokeWidth: 4.0,
                    pattern: StrokePattern.dashed(segments: [10.0, 10.0]),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Markers for checkpoints
                  ..._checkpoints.map((checkpoint) {
                    final bool isScanned = checkpoint['isScanned'];
                    return Marker(
                      point: checkpoint['location'],
                      width: 40,
                      height: 40,
                      child: Tooltip(
                        message: checkpoint['name'],
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isScanned ? AppColors.success : Colors.blue,
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
                  // Markers for participants
                  ..._participants.map((person) {
                    return Marker(
                      point: person['location'],
                      width: 50,
                      height: 50,
                      child: Tooltip(
                        message: person['name'],
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(person['image']),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. Tombol Kembali & Judul Float
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LIVE: ${_statusText.toUpperCase()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Panel Detail Ronda & Laporan (DraggableScrollableSheet)
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Drag indicator
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jadwal & Waktu',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _shiftText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusText,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 16),
                          if (_trackingPath.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Riwayat Tracking',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _trackingStats,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0D1B2A),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Text(
                                'Belum ada riwayat tracking',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Laporan Kejadian',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D1B2A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      sliver: _reports.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmptyReports())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final report = _reports[index];
                                return _buildReportItem(report);
                              }, childCount: _reports.length),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(Map<String, String> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              report['time']!,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['user']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report['text']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusLabel(report['status'] ?? 'SUBMITTED'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(report['status'] ?? 'SUBMITTED'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReports() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Belum ada laporan fasilitas selama shift ronda ini.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'Diproses';
      case 'RESOLVED':
        return 'Selesai';
      default:
        return 'Menunggu';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return const Color(0xFFB45309);
      case 'RESOLVED':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
