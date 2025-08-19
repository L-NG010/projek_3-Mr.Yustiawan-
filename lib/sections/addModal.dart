import 'package:flutter/material.dart';
import '../connect.dart'; // Import database config

class AddModal extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> existingSchedules;
  final VoidCallback? onScheduleAdded;

  const AddModal({
    super.key,
    required this.existingSchedules,
    this.onScheduleAdded,
  });

  @override
  State<AddModal> createState() => _AddModalState();
}

class _AddModalState extends State<AddModal> {
  String? selectedHari;
  String? selectedMapel;
  String? selectedGuru;
  String? selectedJamMulai;
  String? selectedJamBerakhir;
  String? errorMessage;
  bool isLoading = false;
  bool isFetchingData = true;

  List<Map<String, dynamic>> mapelList = [];
  List<Map<String, dynamic>> guruList = [];

  final List<String> hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  final List<String> mondayTimeSlots = [
    '07:30', '08:10', '08:50', '09:30', '10:10', '10:40', '11:20', '12:00', '12:40' , '13:20'
  ];

  final List<String> otherDaysTimeSlots = [
    '06:30', '07:10', '07:50', '08:30', '09:10', '09:40',
    '10:20', '11:00', '11:40', '12:20', '13:00', '13:40', '14:20'
  ];

  @override
  void initState() {
    super.initState();
    _fetchMapelAndGuru();
  }

  Future<void> _fetchMapelAndGuru() async {
    setState(() {
      isFetchingData = true;
      selectedMapel = null; // Reset to prevent invalid selections
      selectedGuru = null; // Reset to prevent invalid selections
    });

    try {
      final supabase = DatabaseConfig.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      // Fetch mapel filtered by u_id
      final mapelResponse = await supabase
          .from('mapel')
          .select('id, nama')
          .eq('u_id', user.id)
          .order('nama', ascending: true);

      // Fetch guru filtered by u_id
      final guruResponse = await supabase
          .from('guru')
          .select('id, nama')
          .eq('u_id', user.id)
          .order('nama', ascending: true);

      setState(() {
        mapelList = List<Map<String, dynamic>>.from(mapelResponse);
        guruList = List<Map<String, dynamic>>.from(guruResponse);
        isFetchingData = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data mata pelajaran atau guru: $e';
        isFetchingData = false;
      });
    }
  }

  List<String> get availableJamMulai {
    if (selectedHari == null) return [];
    return selectedHari == 'Senin' ? mondayTimeSlots : otherDaysTimeSlots;
  }

  List<String> get availableJamBerakhir {
    if (selectedJamMulai == null) return [];
    final startIndex = selectedHari == 'Senin'
        ? mondayTimeSlots.indexOf(selectedJamMulai!)
        : otherDaysTimeSlots.indexOf(selectedJamMulai!);
    if (startIndex == -1) return [];
    return selectedHari == 'Senin'
        ? mondayTimeSlots.sublist(startIndex + 1)
        : otherDaysTimeSlots.sublist(startIndex + 1);
  }

  bool _checkScheduleConflict() {
    if (selectedHari == null || selectedJamMulai == null || selectedJamBerakhir == null) {
      return false;
    }

    final existingSchedules = widget.existingSchedules[selectedHari] ?? [];
    for (final schedule in existingSchedules) {
      final existingStart = schedule['jamMulai'] as String;
      final existingEnd = schedule['jamBerakhir'] as String;
      if (selectedJamMulai!.compareTo(existingEnd) < 0 &&
          selectedJamBerakhir!.compareTo(existingStart) > 0) {
        return true;
      }
    }
    return false;
  }

  Future<String?> _getOrCreateMapel(String namaMapel) async {
    try {
      final supabase = DatabaseConfig.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      final existingMapel = await supabase
          .from('mapel')
          .select('id')
          .eq('nama', namaMapel.trim())
          .eq('u_id', user.id)
          .maybeSingle();

      if (existingMapel != null) {
        return existingMapel['id'] as String;
      }

      final newMapel = await supabase
          .from('mapel')
          .insert({
            'nama': namaMapel.trim(),
            'code_warna': '#6366F1', // Default color
            'u_id': user.id,
          })
          .select('id')
          .single();

      // Refresh mapelList after inserting new mapel
      await _fetchMapelAndGuru();

      return newMapel['id'] as String;
    } catch (e) {
      throw Exception('Gagal membuat/mencari mata pelajaran: $e');
    }
  }

  Future<String?> _getOrCreateGuru(String namaGuru) async {
    try {
      final supabase = DatabaseConfig.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      final existingGuru = await supabase
          .from('guru')
          .select('id')
          .eq('nama', namaGuru.trim())
          .eq('u_id', user.id)
          .maybeSingle();

      if (existingGuru != null) {
        return existingGuru['id'] as String;
      }

      final newGuru = await supabase
          .from('guru')
          .insert({
            'nama': namaGuru.trim(),
            'u_id': user.id,
          })
          .select('id')
          .single();

      // Refresh guruList after inserting new guru
      await _fetchMapelAndGuru();

      return newGuru['id'] as String;
    } catch (e) {
      throw Exception('Gagal membuat/mencari guru: $e');
    }
  }

  Future<void> _saveToDatabase() async {
    try {
      final supabase = DatabaseConfig.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      if (selectedMapel == null || selectedGuru == null ||
          selectedJamMulai == null || selectedJamBerakhir == null ||
          selectedHari == null) {
        throw Exception('Data tidak lengkap');
      }

      final mapelId = await _getOrCreateMapel(selectedMapel!);
      final guruId = await _getOrCreateGuru(selectedGuru!);

      if (mapelId == null || guruId == null) {
        throw Exception('Gagal mendapatkan ID mapel atau guru');
      }

      final jadwalData = {
        'u_id': user.id,
        'mapel_id': mapelId,
        'guru_id': guruId,
        'hari': selectedHari!,
        'jam_awal': '$selectedJamMulai:00',
        'jam_akhir': '$selectedJamBerakhir:00',
      };

      final response = await supabase
          .from('jadwal')
          .insert(jadwalData)
          .select();

      if (response.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jadwal berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        widget.onScheduleAdded?.call();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal menyimpan: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    if (selectedHari == null) {
      setState(() {
        errorMessage = 'Pilih hari terlebih dahulu';
        isLoading = false;
      });
      return;
    }

    if (selectedMapel == null) {
      setState(() {
        errorMessage = 'Pilih mata pelajaran terlebih dahulu';
        isLoading = false;
      });
      return;
    }

    if (selectedGuru == null) {
      setState(() {
        errorMessage = 'Pilih guru terlebih dahulu';
        isLoading = false;
      });
      return;
    }

    if (selectedJamMulai == null) {
      setState(() {
        errorMessage = 'Pilih jam mulai terlebih dahulu';
        isLoading = false;
      });
      return;
    }

    if (selectedJamBerakhir == null) {
      setState(() {
        errorMessage = 'Pilih jam berakhir terlebih dahulu';
        isLoading = false;
      });
      return;
    }

    if (_checkScheduleConflict()) {
      setState(() {
        errorMessage = 'Sudah ada jadwal di hari dan waktu yang sama';
        isLoading = false;
      });
      return;
    }

    await _saveToDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildHeader(),
              const SizedBox(height: 20),

              _buildHariDropdown(),
              const SizedBox(height: 16),

              isFetchingData
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMapelDropdown(),
              const SizedBox(height: 16),

              isFetchingData
                  ? const SizedBox()
                  : _buildGuruDropdown(),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildJamMulaiDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildJamBerakhirDropdown()),
                ],
              ),
              const SizedBox(height: 28),

              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.add_circle_outline,
            color: const Color(0xFF4A4877),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Tambah Jadwal Pelajaran',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHariDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hari *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: isLoading ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedHari,
              hint: const Text('Pilih hari', style: TextStyle(color: Color(0xFF9CA3AF))),
              isExpanded: true,
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        selectedHari = value;
                        selectedJamMulai = null;
                        selectedJamBerakhir = null;
                      });
                    },
              items: hariList.map((hari) {
                return DropdownMenuItem<String>(
                  value: hari,
                  child: Text(
                    hari,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mata Pelajaran *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: isLoading ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedMapel,
              hint: const Text('Pilih mata pelajaran', style: TextStyle(color: Color(0xFF9CA3AF))),
              isExpanded: true,
              onChanged: isLoading
                  ? null
                  : (value) => setState(() => selectedMapel = value),
              items: mapelList.isEmpty
                  ? [
                      const DropdownMenuItem<String>(
                        value: null,
                        enabled: false,
                        child: Text(
                          'Tidak ada mata pelajaran',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                      )
                    ]
                  : mapelList.where((mapel) => mapel['nama'] is String).map((mapel) {
                      return DropdownMenuItem<String>(
                        value: mapel['nama'] as String,
                        child: Text(
                          mapel['nama'] as String,
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuruDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guru *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: isLoading ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedGuru,
              hint: const Text('Pilih guru', style: TextStyle(color: Color(0xFF9CA3AF))),
              isExpanded: true,
              onChanged: isLoading
                  ? null
                  : (value) => setState(() => selectedGuru = value),
              items: guruList.isEmpty
                  ? [
                      const DropdownMenuItem<String>(
                        value: null,
                        enabled: false,
                        child: Text(
                          'Tidak ada guru',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                      )
                    ]
                  : guruList.where((guru) => guru['nama'] is String).map((guru) {
                      return DropdownMenuItem<String>(
                        value: guru['nama'] as String,
                        child: Text(
                          guru['nama'] as String,
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJamMulaiDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jam Mulai *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: isLoading || selectedHari == null
                ? const Color(0xFFF3F4F6)
                : const Color(0xFFF9FAFB),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedJamMulai,
              hint: const Text('Pilih jam mulai', style: TextStyle(color: Color(0xFF9CA3AF))),
              isExpanded: true,
              onChanged: isLoading || selectedHari == null
                  ? null
                  : (value) {
                      setState(() {
                        selectedJamMulai = value;
                        selectedJamBerakhir = null;
                      });
                    },
              items: availableJamMulai.map((jam) {
                return DropdownMenuItem<String>(
                  value: jam,
                  child: Text(
                    jam,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJamBerakhirDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jam Berakhir *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: isLoading || selectedJamMulai == null
                ? const Color(0xFFF3F4F6)
                : const Color(0xFFF9FAFB),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedJamBerakhir,
              hint: const Text('Pilih jam berakhir', style: TextStyle(color: Color(0xFF9CA3AF))),
              isExpanded: true,
              onChanged: isLoading || selectedJamMulai == null
                  ? null
                  : (value) => setState(() => selectedJamBerakhir = value),
              items: availableJamBerakhir.map((jam) {
                return DropdownMenuItem<String>(
                  value: jam,
                  child: Text(
                    jam,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading || isFetchingData ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A4877),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}