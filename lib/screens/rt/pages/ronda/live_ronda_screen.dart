import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/constants/colors.dart';

class LiveRondaScreen extends StatefulWidget {
  const LiveRondaScreen({super.key});

  @override
  State<LiveRondaScreen> createState() => _LiveRondaScreenState();
}

class _LiveRondaScreenState extends State<LiveRondaScreen> {
  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> _participants = [
    {
      'name': 'Bpk. Ahmad',
      'image': 'https://i.pravatar.cc/150?u=ahmad',
      'location': const LatLng(-6.200500, 106.816666)
    },
    {
      'name': 'Ibu Rini',
      'image': 'https://i.pravatar.cc/150?u=rini',
      'location': const LatLng(-6.200000, 106.817000)
    },
  ];

  final List<Map<String, dynamic>> _checkpoints = [
    {
      'name': 'Pos Utama',
      'location': const LatLng(-6.200000, 106.816000),
      'isScanned': true
    },
    {
      'name': 'Sektor Barat',
      'location': const LatLng(-6.200800, 106.816666),
      'isScanned': true
    },
    {
      'name': 'Area Belakang',
      'location': const LatLng(-6.199500, 106.817000),
      'isScanned': false
    },
    {
      'name': 'Gudang Timur',
      'location': const LatLng(-6.199000, 106.816000),
      'isScanned': false
    },
  ];

  final List<Map<String, String>> _reports = [
    {
      'time': '22:15',
      'user': 'Bpk. Ahmad Suhendar',
      'text': 'Mulai patroli dari Pos Utama'
    },
    {
      'time': '22:45',
      'user': 'Ibu Rini Astuti',
      'text': 'Menemukan lampu jalan mati dekat Sektor Barat'
    },
    {
      'time': '23:10',
      'user': 'Bpk. Ahmad Suhendar',
      'text': 'Kondisi area sektor barat aman terkendali'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Peta
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-6.200000, 106.816666),
              initialZoom: 16.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.wargify',
              ),
              PolylineLayer(
                polylines: [
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
                              )
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
                            border: Border.all(color: AppColors.primary, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              )
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
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          'LIVE: Shift Malam',
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
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                                      '22:00 - 02:00 WIB',
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
                                    'Berjalan',
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Laporan Terkini',
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
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final report = _reports[index];
                            return _buildReportItem(report);
                          },
                          childCount: _reports.length,
                        ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
