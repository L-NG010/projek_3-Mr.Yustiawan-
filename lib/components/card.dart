import 'package:flutter/material.dart';
import '../model/pelajaran.dart';
import '../sections/editModal.dart';
import '../connect.dart'; // Import database config

class HariCard extends StatefulWidget {
  final String title;
  final List<Pelajaran> pelajaran;
  final VoidCallback? onScheduleChanged; // Callback untuk refresh data
  final Map<String, List<Map<String, dynamic>>> existingSchedules;

  const HariCard({
    Key? key,
    required this.title,
    required this.pelajaran,
    this.onScheduleChanged,
    required this.existingSchedules,
  }) : super(key: key);

  @override
  _HariCardState createState() => _HariCardState();
}

class _HariCardState extends State<HariCard> with TickerProviderStateMixin {
  final supabase = DatabaseConfig.client;
  bool _expanded = false;
  bool _isDeleting = false;

  void _showEditModal(Pelajaran pelajaran, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: EditModal(
          pelajaran: pelajaran,
          hari: widget.title,
          onScheduleUpdated: widget.onScheduleChanged,
          existingSchedules: widget.existingSchedules,
        ),
      ),
    );
  }

  void _showOptionsMenu(Pelajaran pelajaran, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _showEditModal(pelajaran, index);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteSchedule(pelajaran); // Langsung hapus tanpa konfirmasi
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchedule(Pelajaran pelajaran) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      // Parse jam untuk mendapatkan jam_awal dan jam_akhir
      final jamParts = pelajaran.jam.split(' - ');
      final jamAwal = jamParts.isNotEmpty ? jamParts[0] : '';
      final jamAkhir = jamParts.length > 1 ? jamParts[1] : '';

      // Convert Color ke hex string
      String colorToHex(Color color) {
        return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      }

      // Hapus dari database berdasarkan kombinasi field yang unik
      await supabase
          .from('jadwal')
          .delete()
          .eq('hari', widget.title)
          .eq('nama', pelajaran.nama)
          .eq('jam_awal', jamAwal)
          .eq('jam_akhir', jamAkhir)
          .eq('code_warna', colorToHex(pelajaran.warna));

      // Refresh data
      if (mounted) {
        widget.onScheduleChanged?.call(); // Panggil callback untuk refresh data

        // Tampilkan snackbar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jadwal "${pelajaran.nama}" berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Tampilkan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus jadwal: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: widget.pelajaran.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final p = entry.value;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: p.warna.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$index.',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.book, color: p.warna),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p.nama)),
                            Text(
                              p.jam,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: _isDeleting
                                  ? null
                                  : () => _showOptionsMenu(p, index),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}