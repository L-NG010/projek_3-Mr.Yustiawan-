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
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: Colors.white, // Warna teks putih
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A4877),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Column(
        children: [
          // Tab navigation
          Container(
            color: const Color.fromARGB(255, 255, 255, 255),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton(0, 'Guru'),
                _buildTabButton(1, 'Mata Pelajaran'),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                GuruSettings(supabase: supabase),
                MapelSettings(supabase: supabase),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final bool isActive = _currentIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click, // Ini yang membuat cursor jadi pointer
      child: GestureDetector(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF6A679E) : Colors.transparent,
                width: 3.0,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? Colors.black
                  : const Color.fromARGB(179, 0, 0, 0),
            ),
          ),
        ),
      ),
    );
  }
}

// Guru Settings
class GuruSettings extends StatefulWidget {
  final SupabaseClient supabase;
  const GuruSettings({super.key, required this.supabase});

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
          .order('nama');
      setState(() => _guruList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat guru: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addGuru() async {
    if (!_formKey.currentState!.validate()) return;

    final nama = _namaController.text.trim();
    try {
      await widget.supabase.from('guru').insert({'nama': nama});
      _namaController.clear();
      _loadGuru();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guru berhasil ditambahkan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan guru: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteGuru(String id) async {
    try {
      await widget.supabase.from('guru').delete().eq('id', id);
      _loadGuru();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Guru berhasil dihapus')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus guru: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add Guru Form
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tambah Guru Baru',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4877),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Guru',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan nama guru';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addGuru,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A4877),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Simpan Guru',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Guru List
          const Text(
            'Daftar Guru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _guruList.isEmpty
                ? const Center(child: Text('Belum ada data guru'))
                : ListView.builder(
                    itemCount: _guruList.length,
                    itemBuilder: (context, index) {
                      final guru = _guruList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(guru['nama']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteGuru(guru['id']),
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
}

// Mapel Settings
class MapelSettings extends StatefulWidget {
  final SupabaseClient supabase;
  const MapelSettings({super.key, required this.supabase});

  @override
  State<MapelSettings> createState() => _MapelSettingsState();
}

class _MapelSettingsState extends State<MapelSettings> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  List<Map<String, dynamic>> _mapelList = [];
  bool _isLoading = true;

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
          .order('nama');
      setState(() => _mapelList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat mata pelajaran: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMapel() async {
    if (!_formKey.currentState!.validate()) return;

    final nama = _namaController.text.trim();

    try {
      await widget.supabase.from('mapel').insert({
        'nama': nama,
        'code_warna': '#4A4877', // Default color
      });
      _namaController.clear();
      _loadMapel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mata pelajaran berhasil ditambahkan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan mata pelajaran: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> _deleteMapel(String id) async {
    try {
      await widget.supabase.from('mapel').delete().eq('id', id);
      _loadMapel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mata pelajaran berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus mata pelajaran: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add Mapel Form
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tambah Mata Pelajaran Baru',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4877),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Mata Pelajaran',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan nama mata pelajaran';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addMapel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A4877),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Simpan Mata Pelajaran',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Mapel List
          const Text(
            'Daftar Mata Pelajaran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mapelList.isEmpty
                ? const Center(child: Text('Belum ada data mata pelajaran'))
                : ListView.builder(
                    itemCount: _mapelList.length,
                    itemBuilder: (context, index) {
                      final mapel = _mapelList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(mapel['nama']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteMapel(mapel['id']),
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
}
