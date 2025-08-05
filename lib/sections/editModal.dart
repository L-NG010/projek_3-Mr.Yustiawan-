import 'package:flutter/material.dart';
import '../model/pelajaran.dart';

class EditModal extends StatefulWidget {
  final Pelajaran pelajaran;
  final String hari;

  const EditModal({
    Key? key,
    required this.pelajaran,
    required this.hari,
  }) : super(key: key);

  @override
  State<EditModal> createState() => _EditModalState();
}

class _EditModalState extends State<EditModal> {
  late TextEditingController namaController;
  late TextEditingController jamMulaiController;
  late TextEditingController jamBerakhirController;
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    // Parse the existing jam into start and end times
    final jamParts = widget.pelajaran.jam.split(' - ');
    namaController = TextEditingController(text: widget.pelajaran.nama);
    jamMulaiController = TextEditingController(text: jamParts[0]);
    jamBerakhirController = TextEditingController(text: jamParts[1]);
    selectedColor = widget.pelajaran.warna;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Edit Jadwal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: namaController,
            decoration: const InputDecoration(
              labelText: 'Nama Pelajaran',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: jamMulaiController,
                  decoration: const InputDecoration(
                    labelText: 'Jam Mulai',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: jamBerakhirController,
                  decoration: const InputDecoration(
                    labelText: 'Jam Berakhir',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}