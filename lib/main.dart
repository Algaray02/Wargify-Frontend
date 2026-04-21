import 'package:flutter/material.dart';
import 'services/api_service.dart'; // pastikan kamu sudah buat file ini

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Laravel Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Vian x Laravel'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Tambahkan variable untuk menampung respon dari Laravel
  String _responseMessage = 'Belum ada data dari server';

  // Fungsi untuk memanggil API
  void _fetchData() async {
    // Memanggil class ApiService yang kita buat sebelumnya
    String message = await ApiService().cekKoneksi();
    
    setState(() {
      _responseMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pesan dari API Laravel:'),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _responseMessage, // Menampilkan respon di sini
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData, // Ganti fungsi increment jadi fetch data
        tooltip: 'Ambil Data',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}