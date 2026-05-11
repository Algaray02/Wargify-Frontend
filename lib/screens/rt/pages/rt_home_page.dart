import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RTHomePage extends StatelessWidget {
  const RTHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistik Lingkungan', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Total Warga', '120', Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard('Belum Bayar', '15', Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Aktivitas Terbaru', style: TextStyle(fontWeight: FontWeight.bold)),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Pendaftaran Warga Baru'),
            subtitle: Text('Rumah B-12'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
