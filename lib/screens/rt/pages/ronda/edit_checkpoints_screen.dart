import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CheckpointItem {
  final String id;
  final String name;
  final bool isMain;

  CheckpointItem({required this.id, required this.name, this.isMain = false});
}

class EditCheckpointsScreen extends StatefulWidget {
  const EditCheckpointsScreen({super.key});

  @override
  State<EditCheckpointsScreen> createState() => _EditCheckpointsScreenState();
}

class _EditCheckpointsScreenState extends State<EditCheckpointsScreen> {
  final List<CheckpointItem> _checkpoints = [
    CheckpointItem(id: '1', name: 'Area Belakang', isMain: true),
    CheckpointItem(id: '2', name: 'Pos Utama'),
    CheckpointItem(id: '3', name: 'Sektor Barat'),
    CheckpointItem(id: '4', name: 'Gudang Timur'),
  ];

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isPinSet = false;
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _showForm = false;
  int? _editingIndex;
  bool _isMainCheckpoint = false;

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addCheckpoint() {
    final name = _addressController.text.trim();
    if (name.isNotEmpty && _isPinSet) {
      setState(() {
        _checkpoints.add(CheckpointItem(
          id: DateTime.now().toString(),
          name: name,
          isMain: _isMainCheckpoint,
        ));
        _addressController.clear();
        _noteController.clear();
        _isPinSet = false;
        _selectedLocation = null;
        _isMainCheckpoint = false;
        _showForm = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkpoint "$name" berhasil ditambahkan!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama checkpoint dan pin harus diisi!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _updateCheckpoint() {
    final name = _addressController.text.trim();
    if (name.isNotEmpty && _isPinSet && _editingIndex != null) {
      setState(() {
        _checkpoints[_editingIndex!] = CheckpointItem(
          id: _checkpoints[_editingIndex!].id,
          name: name,
          isMain: _isMainCheckpoint,
        );
        _addressController.clear();
        _noteController.clear();
        _isPinSet = false;
        _selectedLocation = null;
        _isMainCheckpoint = false;
        _showForm = false;
        _editingIndex = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkpoint "$name" berhasil diperbarui!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama checkpoint dan pin harus diisi!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: Colors.red,
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

  Future<LatLng?> _openMapDialog() {
    return showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Lokasi Checkpoint',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: LatLng(-6.200000, 106.816666),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.wargify',
                        ),
                      ],
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 40.0), // Offset so pin points exactly to center
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 44,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _mapController.camera.center);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Simpan Lokasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCheckpointFormModal(BuildContext context, {int? index, CheckpointItem? item}) {
    if (item != null) {
      _addressController.text = item.name;
      _noteController.clear();
      _isPinSet = true;
      _selectedLocation = const LatLng(-6.200000, 106.816666); // Mock placeholder
      _editingIndex = index;
      _isMainCheckpoint = item.isMain;
    } else {
      _addressController.clear();
      _noteController.clear();
      _isPinSet = false;
      _selectedLocation = null;
      _editingIndex = null;
      _isMainCheckpoint = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingIndex != null ? 'EDIT CHECKPOINT' : 'ADD NEW CHECKPOINT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF005B94),
                            letterSpacing: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, color: Colors.grey, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Nama Checkpoint / Lokasi',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                        filled: true,
                        fillColor: Colors.grey[50],
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Keterangan/Patokan (contoh: Depan rumah Pak Abi)',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jadikan Checkpoint Utama',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D1B2A),
                          ),
                        ),
                        Switch(
                          value: _isMainCheckpoint,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setModalState(() {
                              _isMainCheckpoint = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final selected = await _openMapDialog();
                        if (selected != null) {
                          setModalState(() {
                            _selectedLocation = selected;
                            _isPinSet = true;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _isPinSet ? AppColors.success.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _isPinSet ? AppColors.success : Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isPinSet ? Icons.check_circle : Icons.location_pin,
                              color: _isPinSet ? AppColors.success : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isPinSet ? 'Pin Terpasang di Peta' : 'Pasang Pin di Peta',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: _isPinSet ? AppColors.success : Colors.grey[600],
                                fontWeight: _isPinSet ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isPinSet && _selectedLocation != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: _selectedLocation!,
                              initialZoom: 16.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.wargify',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_pin, color: Colors.red, size: 30),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_editingIndex != null) {
                            _updateCheckpoint();
                          } else {
                            _addCheckpoint();
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004B87),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          _editingIndex != null ? 'Simpan Perubahan' : 'Tambah Checkpoint',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showCheckpointFormModal(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Tambah Checkpoint',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Drag and drop list
            _checkpoints.isEmpty
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                if (item.isMain) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Checkpoint Utama',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
            onPressed: () {
              _showCheckpointFormModal(context, index: index, item: item);
            },
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
