// body.dart (UI with database integration)
import 'package:flutter/material.dart';
import '../components/card.dart';
import '../model/pelajaran.dart';
import '../components/addButton.dart';
import '../connect.dart'; // Import database config

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final supabase = DatabaseConfig.client;
  Map<String, List<Pelajaran>> jadwal = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchJadwal();
  }

  Future<void> fetchJadwal() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await supabase
          .from('jadwal')
          .select('nama, jam_awal, jam_akhir, code_warna, hari')
          .order('hari')
          .order('jam_awal');

      final Map<String, List<Pelajaran>> groupedJadwal = {};
      
      for (var item in response) {
        final hari = item['hari'] as String;
        final nama = item['nama'] as String? ?? 'Tanpa Nama';
        final jamAwal = item['jam_awal'] as String? ?? '00:00';
        final jamAkhir = item['jam_akhir'] as String? ?? '00:00';
        final codeWarna = item['code_warna'] as String? ?? '#000000';
        
        final pelajaran = Pelajaran(
          nama: nama,
          jam: '$jamAwal - $jamAkhir',
          warna: Color(_hexToColor(codeWarna)),
        );

        if (groupedJadwal[hari] == null) {
          groupedJadwal[hari] = [];
        }
        groupedJadwal[hari]!.add(pelajaran);
      }

      setState(() {
        jadwal = groupedJadwal;
        isLoading = false;
      });
        } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  int _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      return int.parse('FF$hex', radix: 16);
    } else if (hex.length == 8) {
      return int.parse(hex, radix: 16);
    } else {
      return 0xFF000000; // Default black color
    }
  }

  Future<void> _refreshData() async {
    await fetchJadwal();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: const Color(0xFFfaf3f4),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        color: const Color(0xFFfaf3f4),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (jadwal.isEmpty) {
      return Container(
        color: const Color(0xFFfaf3f4),
        child: const Center(
          child: Text('Tidak ada data jadwal'),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          color: const Color(0xFFfaf3f4),
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: jadwal.entries.map((entry) {
                return HariCard(
                  title: entry.key,
                  pelajaran: entry.value,
                );
              }).toList(),
            ),
          ),
        ),
        const Positioned(
          bottom: 16,
          right: 16,
          child: AddButton(),
        ),
      ],
    );
  }
}