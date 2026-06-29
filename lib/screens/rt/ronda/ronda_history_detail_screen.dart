import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/core/utils/wib_datetime.dart';

class RondaHistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> detail;

  const RondaHistoryDetailScreen({super.key, required this.detail});

  String _formatDate(String? value) {
    final date = parseWibDateTime(value);
    if (date == null) return '-';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);
  }

  String _formatTime(String? value) {
    final date = parseWibDateTime(value);
    if (date == null) return '-';
    return DateFormat('HH:mm').format(date);
  }

  String _formatDuration(dynamic value) {
    final seconds = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainSeconds = seconds % 60;
    if (hours > 0) return '${hours}j ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '${remainSeconds}d';
  }

  List<LatLng> get _pathPoints {
    final path = detail['path_data'];
    if (path is! List) return [];
    return path
        .whereType<Map>()
        .map((point) {
          final lat = double.tryParse('${point['latitude'] ?? point['lat']}');
          final lng = double.tryParse('${point['longitude'] ?? point['lng']}');
          return lat != null && lng != null ? LatLng(lat, lng) : null;
        })
        .whereType<LatLng>()
        .toList();
  }

  List<Map<String, dynamic>> get _checkpointPoints {
    final logs = detail['checkpoint_logs'] is List
        ? (detail['checkpoint_logs'] as List)
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList()
        : <Map<String, dynamic>>[];
    final scannedIds = logs
        .map((log) => log['checkpoint_id']?.toString())
        .whereType<String>()
        .toSet();
    final checkpoints = detail['checkpoints'] is List
        ? detail['checkpoints'] as List
        : const [];

    return checkpoints.whereType<Map>().map((checkpoint) {
      final data = Map<String, dynamic>.from(checkpoint);
      return {
        'id': data['checkpoint_id']?.toString(),
        'name': data['name']?.toString() ?? 'Checkpoint',
        'location': LatLng(
          double.tryParse('${data['latitude']}') ?? -6.2,
          double.tryParse('${data['longitude']}') ?? 106.816666,
        ),
        'scanned': scannedIds.contains(data['checkpoint_id']?.toString()),
      };
    }).toList();
  }

  List<Map<String, dynamic>> get _attendanceDetails {
    final group = detail['group'] is Map
        ? Map<String, dynamic>.from(detail['group'] as Map)
        : <String, dynamic>{};
    final members = group['members'] is List
        ? group['members'] as List
        : const [];
    final attendances = detail['attendances'] is List
        ? detail['attendances'] as List
        : const [];
    final attendanceByUserId = {
      for (final row in attendances.whereType<Map>())
        if (row['user_id'] != null) row['user_id'].toString(): row,
    };

    if (members.isEmpty) {
      return attendances.whereType<Map>().map((row) {
        final data = Map<String, dynamic>.from(row);
        final user = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : <String, dynamic>{};
        return {
          'name': user['full_name']?.toString() ?? '-',
          'present': true,
          'time': data['scanned_at'],
        };
      }).toList();
    }

    return members.whereType<Map>().map((member) {
      final data = Map<String, dynamic>.from(member);
      final userId = data['user_id']?.toString();
      final attendance = userId == null ? null : attendanceByUserId[userId];
      return {
        'name': data['full_name']?.toString() ?? 'Anggota',
        'present': attendance != null,
        'time': attendance?['scanned_at'],
      };
    }).toList();
  }

  Widget _checkpointMarker(Map<String, dynamic> checkpoint, bool scanned) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scanned ? AppColors.success : AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(
            scanned ? Icons.check : Icons.place_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Text(
            checkpoint['name']?.toString() ?? 'Checkpoint',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D1B2A),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = detail['coordinator'] is Map
        ? Map<String, dynamic>.from(detail['coordinator'] as Map)
        : <String, dynamic>{};
    final attendances = detail['attendances'] is List
        ? detail['attendances'] as List
        : const [];
    final checkpointLogs = detail['checkpoint_logs'] is List
        ? detail['checkpoint_logs'] as List
        : const [];
    final distance = num.tryParse('${detail['distance_covered'] ?? 0}') ?? 0;
    final center = _checkpointPoints.isNotEmpty
        ? _checkpointPoints.first['location'] as LatLng
        : _pathPoints.isNotEmpty
        ? _pathPoints.first
        : const LatLng(-6.2, 106.816666);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Riwayat Ronda',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail['group_name']?.toString() ??
                      detail['group']?['name']?.toString() ??
                      'Regu Ronda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(detail['session_date']?.toString()),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        'Koordinator',
                        coordinator['full_name']?.toString() ?? '-',
                      ),
                    ),
                    Expanded(
                      child: _stat('Kehadiran', '${attendances.length}'),
                    ),
                    Expanded(
                      child: _stat(
                        'Checkpoint',
                        '${checkpointLogs.length}/${_checkpointPoints.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        'Jarak',
                        '${distance.toStringAsFixed(2)} km',
                      ),
                    ),
                    Expanded(
                      child: _stat(
                        'Durasi',
                        _formatDuration(detail['duration']),
                      ),
                    ),
                    Expanded(child: _stat('Status', 'Selesai')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 280,
              child: FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 16),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.wargify',
                  ),
                  PolylineLayer(
                    polylines: [
                      if (_pathPoints.length > 1)
                        Polyline(
                          points: _pathPoints,
                          color: AppColors.primary,
                          strokeWidth: 4,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: _checkpointPoints.map((checkpoint) {
                      final scanned = checkpoint['scanned'] == true;
                      return Marker(
                        point: checkpoint['location'] as LatLng,
                        width: 120,
                        height: 76,
                        child: _checkpointMarker(checkpoint, scanned),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section(
            'Presensi',
            _attendanceDetails.isEmpty
                ? [const ListTile(title: Text('Belum ada data anggota'))]
                : _attendanceDetails.map((data) {
                    final present = data['present'] == true;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        present ? Icons.check_circle : Icons.cancel_rounded,
                        color: present ? AppColors.success : AppColors.danger,
                      ),
                      title: Text(data['name']?.toString() ?? '-'),
                      subtitle: Text(
                        present
                            ? _formatTime(data['time']?.toString())
                            : 'Absen',
                      ),
                      trailing: Text(
                        present ? 'Hadir' : 'Absen',
                        style: GoogleFonts.plusJakartaSans(
                          color: present ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }).toList(),
          ),
          const SizedBox(height: 16),
          _section(
            'Scan Checkpoint',
            checkpointLogs.isEmpty
                ? [const ListTile(title: Text('Belum ada scan checkpoint'))]
                : checkpointLogs.whereType<Map>().map((row) {
                    final data = Map<String, dynamic>.from(row);
                    final checkpoint = data['checkpoint'] is Map
                        ? Map<String, dynamic>.from(data['checkpoint'] as Map)
                        : <String, dynamic>{};
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(checkpoint['name']?.toString() ?? '-'),
                      subtitle: Text(
                        _formatTime(data['scanned_at']?.toString()),
                      ),
                    );
                  }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
