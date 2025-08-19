import 'package:flutter/material.dart';
import '../components/card.dart';
import '../model/pelajaran.dart';
import '../components/addButton.dart';
import '../sections/addModal.dart'; // Import AddModal
import '../connect.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final supabase = DatabaseConfig.client;
  Map<String, List<Pelajaran>> jadwal = {};
  bool isLoading = true;
  String? errorMessage;
  String? userId;
  bool hasAnySchedule = false;

  final List<String> dayOrder = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  @override
  void initState() {
    super.initState();
    _getUserId().then((_) => fetchJadwal());
  }

  Future<void> _getUserId() async {
    final user = supabase.auth.currentUser;
    setState(() {
      userId = user?.id;
    });
  }

  Future<void> fetchJadwal() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
        hasAnySchedule = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Updated query to match new database schema
      final response = await supabase
          .from('jadwal')
          .select('''
            id,
            hari,
            jam_awal,
            jam_akhir,
            mapel:mapel_id(nama, code_warna),
            guru:guru_id(nama)
          ''')
          .eq('u_id', userId!)
          .order('hari')
          .order('jam_awal');

      final Map<String, List<Pelajaran>> groupedJadwal = {};

      // Initialize all days with empty lists
      for (var day in dayOrder) {
        groupedJadwal[day] = [];
      }

      // Check if we have any schedule data
      bool hasSchedule = response.isNotEmpty;

      for (var item in response) {
        final hari = item['hari'] as String;
        final mapel = item['mapel'] as Map<String, dynamic>? ?? {};
        final guru = item['guru'] as Map<String, dynamic>? ?? {};
        
        final nama = mapel['nama'] as String? ?? 'Tanpa Nama';
        final codeWarna = mapel['code_warna'] as String? ?? '#000000';
        final namaGuru = guru['nama'] as String? ?? 'Mr. Lang';
        final jamAwal = (item['jam_awal'] as String? ?? '00:00').substring(0, 5);
        final jamAkhir = (item['jam_akhir'] as String? ?? '00:00').substring(0, 5);

        final pelajaran = Pelajaran(
          id: item['id'].toString(),
          nama: nama,
          jam: '$jamAwal - $jamAkhir',
          warna: Color(_hexToColor(codeWarna)),
          namaGuru: namaGuru,
        );

        groupedJadwal[hari]?.add(pelajaran);
      }

      // Sort each day's schedule
      groupedJadwal.forEach((hari, pelajaranList) {
        pelajaranList.sort((a, b) => a.jam.compareTo(b.jam));
      });

      if (mounted) {
        setState(() {
          jadwal = groupedJadwal;
          isLoading = false;
          hasAnySchedule = hasSchedule;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Terjadi kesalahan: $e';
          isLoading = false;
          hasAnySchedule = false;
        });
      }
    }
  }

  int _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      return int.parse('FF$hex', radix: 16);
    } else if (hex.length == 8) {
      return int.parse(hex, radix: 16);
    } else {
      return 0xFF000000; // Default black color
    }
  }

  Future<void> _refreshData() async {
    await fetchJadwal();
  }

  Map<String, List<Map<String, dynamic>>> _convertJadwalForModal() {
    Map<String, List<Map<String, dynamic>>> converted = {};

    jadwal.forEach((hari, pelajaranList) {
      converted[hari] = pelajaranList.map((pelajaran) {
        final jamParts = pelajaran.jam.split(' - ');
        return {
          'jamMulai': jamParts.isNotEmpty ? jamParts[0] : '00:00',
          'jamBerakhir': jamParts.length > 1 ? jamParts[1] : '00:00',
        };
      }).toList();
    });

    return converted;
  }

  void _showAddModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: AddModal(
          existingSchedules: _convertJadwalForModal(),
          onScheduleAdded: _refreshData,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: const Color(0xFFfaf3f4),
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            
            // Icon
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4877).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 60,
                  color: Color(0xFF4A4877),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            const Text(
              'Kamu Belum Punya Jadwal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4877),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Subtitle
            Text(
              'Mulai atur jadwal kuliah kamu dengan\nmenambahkan mata kuliah pertama',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Add Schedule Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _showAddModal,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Tambah Jadwal Pertama',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4877),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    final existingSchedules = _convertJadwalForModal();

    return Stack(
      children: [
        Container(
          color: const Color(0xFFfaf3f4),
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Show loading indicator at the top if still loading
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                
                // Show error message if there's an error
                if (errorMessage != null && !isLoading)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _refreshData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),

                // Show the day cards
                ...dayOrder.map((day) {
                  return HariCard(
                    title: day,
                    pelajaran: jadwal[day] ?? [],
                    onScheduleChanged: _refreshData,
                    existingSchedules: existingSchedules,
                  );
                }).toList(),

                // Add some bottom padding for the floating action button
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        
        // Show AddButton when there are schedules
        Positioned(
          bottom: 16,
          right: 16,
          child: AddButton(
            onScheduleAdded: _refreshData,
            existingSchedules: existingSchedules,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (isLoading) {
      return Container(
        color: const Color(0xFFfaf3f4),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (errorMessage != null) {
      return Container(
        color: const Color(0xFFfaf3f4),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Coba Lagi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state when no schedules
    if (!hasAnySchedule) {
      return _buildEmptyState();
    }

    // Show schedule list when has schedules
    return _buildScheduleList();
  }
}