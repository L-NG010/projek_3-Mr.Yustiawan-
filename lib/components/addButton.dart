import 'package:flutter/material.dart';
import '../sections/addModal.dart';

class AddButton extends StatelessWidget {
  const AddButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(16),
              child: AddModal(
                existingSchedules: {
                  'Senin': [
                    {'jamMulai': '07:10', 'jamBerakhir': '08:50'},
                    {'jamMulai': '08:50', 'jamBerakhir': '10:20'},
                    {'jamMulai': '11:00', 'jamBerakhir': '13:20'},
                  ],
                  'Selasa': [
                    {'jamMulai': '06:30', 'jamBerakhir': '11:00'},
                    {'jamMulai': '11:00', 'jamBerakhir': '12:20'},
                    {'jamMulai': '13:00', 'jamBerakhir': '14:20'},
                  ],
                  'Rabu': [
                    {'jamMulai': '06:30', 'jamBerakhir': '11:00'},
                    {'jamMulai': '11:00', 'jamBerakhir': '14:20'},
                  ],
                  'Kamis': [
                    {'jamMulai': '06:10', 'jamBerakhir': '10:20'},
                    {'jamMulai': '10:20', 'jamBerakhir': '11:40'},
                    {'jamMulai': '11:40', 'jamBerakhir': '14:20'},
                  ],
                  'Jumat': [
                    {'jamMulai': '06:30', 'jamBerakhir': '11:00'},
                  ],
                  'Sabtu': [
                    {'jamMulai': '06:30', 'jamBerakhir': '08:30'},
                    {'jamMulai': '08:30', 'jamBerakhir': '11:00'},
                  ],
                },
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4A4877),
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
