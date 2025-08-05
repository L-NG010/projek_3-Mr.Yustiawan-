import 'package:flutter/material.dart';
import '../model/pelajaran.dart';
import '../sections/editModal.dart';

class HariCard extends StatefulWidget {
  final String title;
  final List<Pelajaran> pelajaran;

  const HariCard({
    Key? key,
    required this.title,
    required this.pelajaran,
  }) : super(key: key);

  @override
  _HariCardState createState() => _HariCardState();
}

class _HariCardState extends State<HariCard> with TickerProviderStateMixin {
  bool _expanded = false;

  void _showEditModal(Pelajaran pelajaran) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: EditModal(
          pelajaran: pelajaran,
          hari: widget.title,
        ),
      ),
    );
  }

  void _showOptionsMenu(Pelajaran pelajaran) {
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
              _showEditModal(pelajaran);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation();
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: const Text('Yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                            Text(p.jam,
                                style: TextStyle(color: Colors.grey[700])),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showOptionsMenu(p),
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