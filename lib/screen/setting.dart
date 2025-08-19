// settings_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../connect.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final supabase = DatabaseConfig.client;
  User? get currentUser => supabase.auth.currentUser;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
      title: const Text(
        'Pengaturan',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF4A4877),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                Expanded(child: _buildTabButton(0, 'Guru', Icons.person)),
                Expanded(child: _buildTabButton(1, 'Mata Pelajaran', Icons.book)),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: [
                GuruSettings(supabase: supabase, userId: currentUser!.id),
                MapelSettings(supabase: supabase, userId: currentUser!.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [Color(0xFF4A4877), Color(0xFF6A679E)])
              : null,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Guru Settings
class GuruSettings extends StatefulWidget {
  final SupabaseClient supabase;
  final String userId;
  const GuruSettings({super.key, required this.supabase, required this.userId});

  @override
  State<GuruSettings> createState() => _GuruSettingsState();
}

class _GuruSettingsState extends State<GuruSettings> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  List<Map<String, dynamic>> _guruList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuru();
  }

  Future<void> _loadGuru() async {
    setState(() => _isLoading = true);
    try {
      final response = await widget.supabase
          .from('guru')
          .select()
          .eq('u_id', widget.userId)
          .order('nama');
      setState(() => _guruList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showSnackBar('Gagal memuat guru: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addGuru() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await widget.supabase.from('guru').insert({
        'nama': _namaController.text.trim(),
        'u_id': widget.userId,
      });
      _namaController.clear();
      _loadGuru();
      _showSnackBar('Guru berhasil ditambahkan');
    } catch (e) {
      _showSnackBar('Gagal menambahkan guru: ${e.toString()}', isError: true);
    }
  }

  Future<void> _deleteGuru(String id, String nama) async {
    final confirmed = await _showDeleteConfirmation(nama);
    if (!confirmed) return;

    try {
      await widget.supabase.from('guru').delete().eq('id', id);
      _loadGuru();
      _showSnackBar('Guru berhasil dihapus');
    } catch (e) {
      _showSnackBar('Gagal menghapus guru: ${e.toString()}', isError: true);
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
                    'Tambah Guru Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _namaController,
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addGuru,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A4877),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Simpan Guru',
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
                  'Daftar Guru',
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
                    '${_guruList.length} guru',
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
                : _guruList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('Belum ada data guru', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _guruList.length,
                        itemBuilder: (context, index) {
                          final guru = _guruList[index];
                          return Container(
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
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [Color(0xFF4A4877), Color(0xFF6A679E)]),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                guru['nama'],
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteGuru(guru['id'], guru['nama']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(String nama) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus guru "$nama"?'),
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

// Mapel Settings with Color Picker
class MapelSettings extends StatefulWidget {
  final SupabaseClient supabase;
  final String userId;
  const MapelSettings({
    super.key,
    required this.supabase,
    required this.userId,
  });

  @override
  State<MapelSettings> createState() => _MapelSettingsState();
}

class _MapelSettingsState extends State<MapelSettings> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  List<Map<String, dynamic>> _mapelList = [];
  bool _isLoading = true;
  Color _selectedColor = const Color(0xFF4A4877);

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
          .select()
          .eq('u_id', widget.userId)
          .order('nama');
      setState(() => _mapelList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showSnackBar('Gagal memuat mata pelajaran: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMapel() async {
    if (!_formKey.currentState!.validate()) return;

    final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2)}';

    try {
      await widget.supabase.from('mapel').insert({
        'nama': _namaController.text.trim(),
        'code_warna': colorHex,
        'u_id': widget.userId,
      });
      _namaController.clear();
      _selectedColor = const Color(0xFF4A4877);
      _loadMapel();
      _showSnackBar('Mata pelajaran berhasil ditambahkan');
    } catch (e) {
      _showSnackBar('Gagal menambahkan mata pelajaran: ${e.toString()}', isError: true);
    }
  }

  Future<void> _deleteMapel(String id, String nama) async {
    final confirmed = await _showDeleteConfirmation(nama);
    if (!confirmed) return;

    try {
      await widget.supabase.from('mapel').delete().eq('id', id);
      _loadMapel();
      _showSnackBar('Mata pelajaran berhasil dihapus');
    } catch (e) {
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
                    'Tambah Mata Pelajaran Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _namaController,
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
                      onPressed: _addMapel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A4877),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Simpan Mata Pelajaran',
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
                  'Daftar Mata Pelajaran',
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
                    : ListView.builder(
                        itemCount: _mapelList.length,
                        itemBuilder: (context, index) {
                          final mapel = _mapelList[index];
                          final color = Color(
                            int.parse('0xFF${mapel['code_warna'].substring(1)}'),
                          );

                          return Container(
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
                              subtitle: Container(
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteMapel(mapel['id'], mapel['nama']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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