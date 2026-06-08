import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/services/api_service.dart';

class SosDashboardScreen extends StatefulWidget {
  const SosDashboardScreen({super.key});

  @override
  State<SosDashboardScreen> createState() => _SosDashboardScreenState();
}

class _SosDashboardScreenState extends State<SosDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  bool _isResolving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    try {
      final rows = await _apiService.getList(ApiEndpoints.emergencyAlerts);
      if (!mounted) return;
      setState(() {
        _alerts = rows
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal mengambil data SOS: $error';
        });
      }
    }
  }

  int get _activeAlerts =>
      _alerts.where((alert) => alert['status'] == 'ACTIVE').length;

  int get _resolvedAlerts =>
      _alerts.where((alert) => alert['status'] == 'RESOLVED').length;

  Future<void> _resolveAlert(Map<String, dynamic> alert) async {
    final alertId = alert['alert_id']?.toString();
    if (alertId == null || alertId.isEmpty || _isResolving) return;

    setState(() => _isResolving = true);
    try {
      await _apiService.post(
        '${ApiEndpoints.emergencyAlerts}/$alertId/resolve',
        {},
      );
      await _fetchAlerts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SOS berhasil ditandai aman.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal resolve SOS: $error',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  String _senderName(Map<String, dynamic> alert) {
    final sender = Map<String, dynamic>.from((alert['sender'] ?? {}) as Map);
    return sender['full_name']?.toString() ?? 'Warga';
  }

  String _senderPhone(Map<String, dynamic> alert) {
    final sender = Map<String, dynamic>.from((alert['sender'] ?? {}) as Map);
    return sender['phone_number']?.toString() ?? '-';
  }

  String _formatCreatedAt(Map<String, dynamic> alert) {
    final createdAt = DateTime.tryParse('${alert['created_at']}');
    if (createdAt == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm').format(createdAt);
  }

  LatLng? _alertPoint(Map<String, dynamic> alert) {
    final latitude = double.tryParse('${alert['latitude']}');
    final longitude = double.tryParse('${alert['longitude']}');
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  void _showLocationSheet(Map<String, dynamic> alert) {
    final point = _alertPoint(alert);
    if (point == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.76,
        minChildSize: 0.46,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lokasi SOS ${_senderName(alert)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0D1B2A),
                                  ),
                                ),
                                Text(
                                  '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildMap(point, interactive: true)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _resolveAlert(alert);
                      },
                      icon: const Icon(Icons.done_all_rounded),
                      label: Text(
                        'Tandai Aman',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dashbord SOS',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAlerts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emergency_rounded,
                    color: AppColors.danger,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SISTEM EMERGENCY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'SOS\nDashboard',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pantau sinyal darurat warga secara real-time. Respon segera terhadap tanda bahaya yang aktif.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.emergency_share_rounded,
                      value: _activeAlerts.toString().padLeft(2, '0'),
                      label: 'SOS AKTIF',
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_outline_rounded,
                      value: _resolvedAlerts.toString(),
                      label: 'SELESAI',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Recent Alerts Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat SOS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchAlerts,
                    child: Row(
                      children: [
                        Text(
                          'Perbarui',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.16),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_alerts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Belum ada sinyal SOS.',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    else
                      ..._alerts.map(_buildAlertCard),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isActive = alert['status'] == 'ACTIVE';
    final latitude = alert['latitude']?.toString() ?? '-';
    final longitude = alert['longitude']?.toString() ?? '-';
    final point = _alertPoint(alert);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.danger.withOpacity(0.06)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? AppColors.danger.withOpacity(0.16)
              : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.danger : AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive
                      ? Icons.emergency_share_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _senderName(alert),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D1B2A),
                      ),
                    ),
                    Text(
                      _formatCreatedAt(alert),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.danger.withOpacity(0.12)
                      : AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isActive ? 'AKTIF' : 'AMAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isActive ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            alert['message']?.toString() ?? '-',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF0D1B2A),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Telp: ${_senderPhone(alert)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Text(
                '$latitude, $longitude',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (point != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: _buildMap(point, interactive: false),
              ),
            ),
          ],
          if (isActive) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: point == null
                        ? null
                        : () => _showLocationSheet(alert),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: Text(
                      'Lihat Lokasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isResolving ? null : () => _resolveAlert(alert),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: Text(
                      _isResolving ? 'Memproses...' : 'Tandai Aman',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMap(LatLng point, {required bool interactive}) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: interactive ? 17 : 15,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.wargify.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 54,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emergency_share_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
