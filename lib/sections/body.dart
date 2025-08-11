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

  // Define the correct order of days
  final List<String> dayOrder = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    "Jum'at",
    'Sabtu',
  ];

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
        final hari = _toTitleCase(item['hari'] as String);
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

      groupedJadwal.forEach((hari, pelajaranList) {
        pelajaranList.sort((a, b) => a.jam.compareTo(b.jam));
      });

      final sortedJadwal = <String, List<Pelajaran>>{};
      for (var day in dayOrder) {
        if (groupedJadwal.containsKey(day)) {
          sortedJadwal[day] = groupedJadwal[day]!;
        }
      }

      if (mounted) {
        setState(() {
          jadwal = sortedJadwal;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Terjadi kesalahan: $e';
          isLoading = false;
        });
      }
    }
  }

  String _toTitleCase(String str) {
    return str
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : word)
        .join(' ');
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

  // Callback untuk refresh data
  Future<void> _refreshData() async {
    await fetchJadwal();
  }

  // Convert jadwal data ke format yang dibutuhkan AddModal dan EditModal
  Map<String, List<Map<String, dynamic>>> _convertJadwalForModal() {
    Map<String, List<Map<String, dynamic>>> converted = {};

    jadwal.forEach((hari, pelajaranList) {
      converted[hari] = pelajaranList.map((pelajaran) {
        final jamParts = pelajaran.jam.split(' - ');
        return {
          'jamMulai': jamParts.isNotEmpty ? jamParts[0] : '00:00',
          'jamBerakhir': jamParts.length > 1 ? jamParts[1] : '00:00',
        };
      }).toList();
    });

    return converted;
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

    final existingSchedules = _convertJadwalForModal();

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
                  onScheduleChanged: _refreshData, // Teruskan callback
                  existingSchedules: existingSchedules,
                );
              }).toList(),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: AddButton(
            onScheduleAdded: _refreshData, // Gunakan callback yang sama
            existingSchedules: existingSchedules,
          ),
        ),
      ],
    );
  }
}