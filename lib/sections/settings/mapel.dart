import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapelGuruSettings extends StatefulWidget {
  final SupabaseClient supabase;
  final String userId;
  const MapelGuruSettings({super.key, required this.supabase, required this.userId});

  @override
  State<MapelGuruSettings> createState() => _MapelGuruSettingsState();
}

class _MapelGuruSettingsState extends State<MapelGuruSettings> {
  final _formKey = GlobalKey<FormState>();
  final _mapelController = TextEditingController();
  final _guruController = TextEditingController();
  List<Map<String, dynamic>> _mapelList = [];
  bool _isLoading = true;
  Color _selectedColor = const Color(0xFF4A4877);
  final _listKey = GlobalKey<AnimatedListState>();

  final List<Color> _colorOptions = [
    const Color(0xFF4A4877),
    const Color(0xFF6A679E),
    const Color(0xFF9370DB),
    const Color(0xFF8A2BE2),
    const Color(0xFF9932CC),
    const Color(0xFF20B2AA),
    const Color(0xFF32CD32),
    const Color(0xFFFF6347),
    const Color(0xFF4169E1),
    const Color(0xFFFF1493),
  ];

  @override
  void initState() {
    super.initState();
    _loadMapel();
  }

  Future<void> _loadMapel() async {
    setState(() => _isLoading = true);
    try {
      final response = await widget.supabase
          .from('mapel')
          .select('id, nama, code_warna, guru_id, guru:nama_guru(nama)')
          .eq('u_id', widget.userId)
          .order('nama');
      setState(() => _mapelList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showSnackBar('Gagal memuat data: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMapelAndGuru() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final guruResponse = await widget.supabase.from('guru').insert({
        'nama': _guruController.text.trim(),
        'u_id': widget.userId,
      }).select('id').single();

      final guruId = guruResponse['id'];
      final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2)}';
      await widget.supabase.from('mapel').insert({
        'nama': _mapelController.text.trim(),
        'code_warna': colorHex,
        'u_id': widget.userId,
        'guru_id': guruId,
      });

      final newMapel = {
        'id': guruResponse['id'],
        'nama': _mapelController.text.trim(),
        'code_warna': colorHex,
        'guru': {'nama': _guruController.text.trim()},
      };
      setState(() {
        final index = _mapelList.length;
        _mapelList.add(newMapel);
        _listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 400));
      });

      _mapelController.clear();
      _guruController.clear();
      _selectedColor = const Color(0xFF4A4877);
      _showSnackBar('Mata pelajaran dan guru berhasil ditambahkan');
    } catch (e) {
      _showSnackBar('Gagal menambahkan data: ${e.toString()}', isError: true);
    }
  }

  Future<void> _deleteMapel(String id, String nama, int index) async {
    final confirmed = await _showDeleteConfirmation(nama);
    if (!confirmed) return;

    setState(() {
      final removedMapel = _mapelList.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildMapelItem(removedMapel, index, animation),
        duration: const Duration(milliseconds: 400),
      );
    });

    try {
      await widget.supabase.from('mapel').delete().eq('id', id);
      _showSnackBar('Mata pelajaran berhasil dihapus');
    } catch (e) {
      setState(() {
        _mapelList.insert(index, _mapelList[index]);
        _listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 400));
      });
      _showSnackBar('Gagal menghapus mata pelajaran: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah Mata Pelajaran & Guru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mapelController,
                    decoration: InputDecoration(
                      labelText: 'Nama Mata Pelajaran',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6A679E), width: 2),
                      ),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Masukkan nama mata pelajaran' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _guruController,
                    decoration: InputDecoration(
                      labelText: 'Nama Guru',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6A679E), width: 2),
                      ),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Masukkan nama guru' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Warna',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorOptions.length,
                      itemBuilder: (context, index) {
                        final color = _colorOptions[index];
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 24)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addMapelAndGuru,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A4877),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Simpan Mata Pelajaran & Guru',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              children: [
                const Text(
                  'Daftar Mata Pelajaran & Guru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4A4877), Color(0xFF6A679E)]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${_mapelList.length} mapel',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A679E)))
                : _mapelList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('Belum ada mata pelajaran', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : AnimatedList(
                        key: _listKey,
                        initialItemCount: _mapelList.length,
                        itemBuilder: (context, index, animation) {
                          final mapel = _mapelList[index];
                          return _buildMapelItem(mapel, index, animation);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapelItem(Map<String, dynamic> mapel, int index, Animation<double> animation) {
    final color = Color(int.parse('0xFF${mapel['code_warna'].substring(1)}'));
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2), 
                ),
              ],
            ),
            child: const Icon(Icons.book, color: Colors.white),
          ),
          title: Text(
            mapel['nama'],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Warna: ${mapel['code_warna']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                'Guru: ${mapel['guru']?['nama'] ?? 'Tidak ada guru'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteMapel(mapel['id'], mapel['nama'], index),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(String nama) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus mata pelajaran "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}