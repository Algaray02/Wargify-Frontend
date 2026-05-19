import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import '../../../../core/constants/colors.dart';

class CheckpointItem {
  final String id;
  final String name;

  CheckpointItem({required this.id, required this.name});
}

class EditCheckpointsScreen extends StatefulWidget {
  const EditCheckpointsScreen({super.key});

  @override
  State<EditCheckpointsScreen> createState() => _EditCheckpointsScreenState();
}

class _EditCheckpointsScreenState extends State<EditCheckpointsScreen> {
  final List<CheckpointItem> _checkpoints = [
    CheckpointItem(id: '1', name: 'Area Belakang'),
    CheckpointItem(id: '2', name: 'Pos Utama'),
    CheckpointItem(id: '3', name: 'Sektor Barat'),
    CheckpointItem(id: '4', name: 'Gudang Timur'),
  ];

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Active Map Pin Location state
  LatLng? _pinnedCoordinate = LatLng(-6.2088, 106.8456); // Default: Jakarta center
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addCheckpoint() {
    final name = _addressController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _checkpoints.add(CheckpointItem(
          id: DateTime.now().toString(),
          name: name,
        ));
        _addressController.clear();
        _noteController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkpoint "$name" berhasil ditambahkan!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _deleteCheckpoint(int index) {
    final name = _checkpoints[index].name;
    setState(() {
      _checkpoints.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checkpoint "$name" dihapus', style: GoogleFonts.plusJakartaSans()),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
        ),
        title: Text(
          'Edit Checkpoints',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Urutan Checkpoint berhasil disimpan!', style: GoogleFonts.plusJakartaSans()),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Text(
                'SAVE',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header Sequence
            Text(
              'Checkpoint Sequence',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF003B73),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Drag and drop items to reorder the patrol route sequence for this shift.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Drag and drop list
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              child: _checkpoints.isEmpty
                  ? _buildEmptyCheckpoints()
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _checkpoints.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = _checkpoints.removeAt(oldIndex);
                          _checkpoints.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = _checkpoints[index];
                        return _buildCheckpointCard(item, index);
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // ADD NEW CHECKPOINT (Dotted Border container representation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFCBDCE6),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADD NEW CHECKPOINT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF005B94),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Field with deep blue plus button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan Alamat atau Lokasi Maps',
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _addCheckpoint,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF004B87),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Patrol notes/instructions
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Keterangan/Patokan (contoh: Depan rumah Pak Abi)',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tambahkan Pin Di Peta (New Interactive Section)
            Text(
              'TAMBAHKAN PIN DI PETA',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF005B94),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ketuk di mana saja pada peta di bawah ini untuk menandai koordinat checkpoint baru.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),

            // Active Interactive Map using flutter_map
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(-6.2088, 106.8456), // Jakarta center
                    initialZoom: 15,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _pinnedCoordinate = point;
                        // Format the lat/long coordinate cleanly inside the address field!
                        _addressController.text =
                            'Lokasi (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pin diletakkan di ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wargify.app',
                    ),
                    if (_pinnedCoordinate != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pinnedCoordinate!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCheckpoints() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'Tidak ada checkpoint patroli. Silakan tambah baru!',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCheckpointCard(CheckpointItem item, int index) {
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              item.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D1B2A),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _deleteCheckpoint(index),
          ),
        ],
      ),
    );
  }
}
