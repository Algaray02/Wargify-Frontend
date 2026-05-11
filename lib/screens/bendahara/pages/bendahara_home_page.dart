import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BendaharaHomePage extends StatelessWidget {
  const BendaharaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Kas RT', style: TextStyle(fontSize: 16)),
          Text('Rp 12.450.000', style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
          const SizedBox(height: 24),
          const Text('Menu Cepat', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildMenuCard(Icons.add_chart, 'Input Kas'),
              _buildMenuCard(Icons.history, 'Riwayat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.teal),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
