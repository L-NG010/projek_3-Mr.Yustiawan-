// body.dart (UI only)
import 'package:flutter/material.dart';
import '../components/card.dart';
import '../model/pelajaran.dart';
import '../components/addButton.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  final Map<String, List<Pelajaran>> jadwal = const {
    'Senin': [
      Pelajaran(nama: 'BKK', jam: '07:10 - 08:50', warna: Color(0xFF51C6EB)),
      Pelajaran(nama: 'BING', jam: '08:50 - 10:20', warna: Color(0xFFF29629)),
      Pelajaran(nama: 'KRPL', jam: '11:00 - 13:20', warna: Color(0xFFFA9C8F)),
    ],
    'Selasa': [
      Pelajaran(nama: 'KRPL 4', jam: '06:30 - 11:00', warna: Color(0xFFFF9A8B)),
      Pelajaran(nama: 'BJ', jam: '11:00 - 12:20', warna: Color(0xFF4CC9F0)),
      Pelajaran(nama: 'BING', jam: '13:00 - 14:20', warna: Color(0xFFF8961E)),
    ],
    'Rabu': [
      Pelajaran(nama: 'KRPL 4', jam: '06:30 - 11:00', warna: Color(0xFFFF9A8B)),
      Pelajaran(nama: 'MPG', jam: '11:00 - 14:20', warna: Color(0xFFFF9A8B)),
    ],
    'Kamis': [
      Pelajaran(nama: 'PKDK', jam: '06:30 - 10:20', warna: Color(0xFFDA70D6)),
      Pelajaran(nama: 'PP', jam: '10:20 - 11:40', warna: Color(0xFF7209B7)),
      Pelajaran(nama: 'PAI', jam: '11:40 - 14:20', warna: Color(0xFF0096FF)),
    ],
    'Jumat': [
      Pelajaran(nama: 'KRPL 4', jam: '06:30 - 11:00', warna: Color(0xFFFF9A8B)),
    ],
    'Sabtu': [
      Pelajaran(nama: 'MTK', jam: '06:30 - 08:30', warna: Color(0xFF90EE90)),
      Pelajaran(nama: 'BIN', jam: '08:30 - 11:00', warna: Color(0xFF006400)),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFFfaf3f4),
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
        const Positioned(
          bottom: 16,
          right: 16,
          child: AddButton(),
        ),
      ],
    );
  }
}