import 'package:flutter/material.dart';
import '../sections/addModal.dart';

class AddButton extends StatelessWidget {
  final VoidCallback? onScheduleAdded; // Tambahkan parameter callback
  final Map<String, List<Map<String, dynamic>>>? existingSchedules; // Optional data dari database

  const AddButton({
    super.key,
    this.onScheduleAdded,
    this.existingSchedules,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: AddModal(
                existingSchedules: existingSchedules ?? {}, // Gunakan data dari parameter atau kosong
                onScheduleAdded: onScheduleAdded, // Pass callback ke AddModal
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A4877),
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}