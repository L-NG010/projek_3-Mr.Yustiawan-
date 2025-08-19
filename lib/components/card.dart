import 'package:flutter/material.dart';
import '../model/pelajaran.dart';
import '../sections/editModal.dart';
import '../connect.dart';

class HariCard extends StatefulWidget {
  final String title;
  final List<Pelajaran> pelajaran;
  final VoidCallback? onScheduleChanged;
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
  final _listKey = GlobalKey<AnimatedListState>();
  List<Pelajaran> _visiblePelajaran = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _visiblePelajaran = widget.pelajaran;
  }

  @override
  void didUpdateWidget(covariant HariCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pelajaran != oldWidget.pelajaran && !_isRefreshing) {
      setState(() {
        _visiblePelajaran = widget.pelajaran;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (widget.onScheduleChanged != null) {
      setState(() => _isRefreshing = true);
      widget.onScheduleChanged!();
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() => _isRefreshing = false);
    }
  }

  void _showEditModal(Pelajaran pelajaran, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: EditModal(
          pelajaran: pelajaran,
          hari: widget.title,
          onScheduleUpdated: _handleRefresh,
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
              _confirmDelete(pelajaran);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Pelajaran pelajaran) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus jadwal "${pelajaran.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSchedule(pelajaran);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchedule(Pelajaran pelajaran) async {
    final index = _visiblePelajaran.indexOf(pelajaran);
    if (index == -1) return;

    // Optimistically remove item from UI with animation
    final removedItem = _visiblePelajaran.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildPelajaranItem(removedItem, index + 1, animation),
      duration: const Duration(milliseconds: 400),
    );

    try {
      await supabase.from('jadwal').delete().eq('id', pelajaran.id);

      // Notify parent only after successful deletion
      if (widget.onScheduleChanged != null) {
        widget.onScheduleChanged!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jadwal "${pelajaran.nama}" berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Revert UI if deletion fails
      if (mounted) {
        setState(() {
          _visiblePelajaran.insert(index, removedItem);
          _listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 400));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus jadwal: ${e.toString().contains('DatabaseError') ? 'Kesalahan database' : e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded ? _buildPelajaranList() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPelajaranList() {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      initialItemCount: _visiblePelajaran.length,
      itemBuilder: (context, index, animation) {
        final pelajaran = _visiblePelajaran[index];
        return _buildPelajaranItem(pelajaran, index + 1, animation);
      },
    );
  }

  Widget _buildPelajaranItem(Pelajaran p, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        key: ValueKey(p.nama + p.jam),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: p.warna.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text('$index.', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(Icons.book, color: p.warna),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(p.namaGuru, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),
            Text(p.jam, style: TextStyle(color: Colors.grey[700])),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptionsMenu(p, index),
            ),
          ],
        ),
      ),
    );
  }
}