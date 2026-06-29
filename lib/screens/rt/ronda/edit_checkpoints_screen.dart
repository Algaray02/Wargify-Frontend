import 'package:wargify/core/utils/app_error.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wargify/services/api_service.dart';

class CheckpointItem {
  final String id;
  final String name;
  final bool isMain;
  final double latitude;
  final double longitude;
  final String? qrCodeData;

  CheckpointItem({
    required this.id,
    required this.name,
    this.isMain = false,
    required this.latitude,
    required this.longitude,
    this.qrCodeData,
  });

  LatLng get location => LatLng(latitude, longitude);

  factory CheckpointItem.fromJson(Map<String, dynamic> json) {
    return CheckpointItem(
      id: json['checkpoint_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '-',
      isMain: json['is_main_pos'] == true || json['is_main_pos'] == 1,
      latitude: double.tryParse('${json['latitude']}') ?? -6.200000,
      longitude: double.tryParse('${json['longitude']}') ?? 106.816666,
      qrCodeData: json['qr_code_data']?.toString(),
    );
  }
}

class EditCheckpointsScreen extends StatefulWidget {
  const EditCheckpointsScreen({super.key});

  @override
  State<EditCheckpointsScreen> createState() => _EditCheckpointsScreenState();
}

class _EditCheckpointsScreenState extends State<EditCheckpointsScreen> {
  final ApiService _apiService = ApiService();
  final List<CheckpointItem> _checkpoints = [];

  final TextEditingController _addressController = TextEditingController();
  bool _isPinSet = false;
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  int? _editingIndex;
  bool _isMainCheckpoint = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCheckpoints();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCheckpoints() async {
    try {
      final rows = await _apiService.getList(ApiEndpoints.rondaCheckpoints);
      if (!mounted) return;
      setState(() {
        _checkpoints
          ..clear()
          ..addAll(
            rows
                .map(
                  (row) => CheckpointItem.fromJson(
                    Map<String, dynamic>.from(row as Map),
                  ),
                )
                .toList(),
          );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Gagal memuat checkpoint: ${AppError.userFriendly(error)}', Colors.red);
    }
  }

  Future<void> _addCheckpoint() async {
    final name = _addressController.text.trim();
    if (name.isNotEmpty && _isPinSet && _selectedLocation != null) {
      await _apiService.post(ApiEndpoints.rondaCheckpoints, {
        'name': name,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'is_main_pos': _isMainCheckpoint,
      });
      await _loadCheckpoints();
      _resetForm();
      _showSnack('Checkpoint "$name" berhasil ditambahkan!', AppColors.success);
    } else {
      _showSnack('Nama checkpoint dan pin harus diisi!', Colors.red);
    }
  }

  Future<void> _updateCheckpoint() async {
    final name = _addressController.text.trim();
    if (name.isNotEmpty && _isPinSet && _editingIndex != null) {
      final item = _checkpoints[_editingIndex!];
      final location = _selectedLocation ?? item.location;
      await _apiService.patch('${ApiEndpoints.rondaCheckpoints}/${item.id}', {
        'name': name,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'qr_code_data': item.qrCodeData,
        'is_main_pos': _isMainCheckpoint,
      });
      await _loadCheckpoints();
      _resetForm();
      _showSnack('Checkpoint "$name" berhasil diperbarui!', AppColors.success);
    } else {
      _showSnack('Nama checkpoint dan pin harus diisi!', Colors.red);
    }
  }

  Future<void> _deleteCheckpoint(int index) async {
    final name = _checkpoints[index].name;
    await _apiService.delete(
      '${ApiEndpoints.rondaCheckpoints}/${_checkpoints[index].id}',
    );
    await _loadCheckpoints();
    _showSnack('Checkpoint "$name" dihapus', Colors.grey[800]!);
  }

  void _resetForm() {
    setState(() {
      _addressController.clear();
      _isPinSet = false;
      _selectedLocation = null;
      _isMainCheckpoint = false;
      _editingIndex = null;
    });
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: color,
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
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
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
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.wargify',
                        ),
                      ],
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: 40.0,
                        ), // Offset so pin points exactly to center
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  void _showCheckpointFormModal(
    BuildContext context, {
    int? index,
    CheckpointItem? item,
  }) {
    if (item != null) {
      _addressController.text = item.name;
      _isPinSet = true;
      _selectedLocation = item.location;
      _editingIndex = index;
      _isMainCheckpoint = item.isMain;
    } else {
      _addressController.clear();
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
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
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
                          _editingIndex != null
                              ? 'EDIT CHECKPOINT'
                              : 'ADD NEW CHECKPOINT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF005B94),
                            letterSpacing: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Nama Checkpoint / Lokasi',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                          ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _isPinSet
                              ? AppColors.success.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isPinSet
                                ? AppColors.success
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isPinSet
                                  ? Icons.check_circle
                                  : Icons.location_pin,
                              color: _isPinSet
                                  ? AppColors.success
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isPinSet
                                  ? 'Pin Terpasang di Peta'
                                  : 'Pasang Pin di Peta',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: _isPinSet
                                    ? AppColors.success
                                    : Colors.grey[600],
                                fontWeight: _isPinSet
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.wargify',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 30,
                                    ),
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
                        onPressed: () async {
                          try {
                            if (_editingIndex != null) {
                              await _updateCheckpoint();
                            } else {
                              await _addCheckpoint();
                            }
                            if (context.mounted) Navigator.pop(context);
                          } catch (error) {
                            _showSnack(
                              'Gagal menyimpan checkpoint: ${AppError.userFriendly(error)}',
                              Colors.red,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004B87),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _editingIndex != null
                              ? 'Simpan Perubahan'
                              : 'Tambah Checkpoint',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () {
              _showCheckpointFormModal(context, index: index, item: item);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () async {
              try {
                await _deleteCheckpoint(index);
              } catch (error) {
                _showSnack(
                  'Checkpoint tidak bisa dihapus karena masih dipakai jadwal.',
                  Colors.red,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
