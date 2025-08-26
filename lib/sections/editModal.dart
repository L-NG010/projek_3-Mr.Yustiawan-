import 'package:flutter/material.dart';
import '../model/pelajaran.dart';
import '../connect.dart';

class EditModal extends StatefulWidget {
  final Pelajaran pelajaran;
  final String hari;
  final VoidCallback? onScheduleUpdated;
  final Map<String, List<Map<String, dynamic>>> existingSchedules;

  const EditModal({
    Key? key,
    required this.pelajaran,
    required this.hari,
    this.onScheduleUpdated,
    required this.existingSchedules,
  }) : super(key: key);

  @override
  State<EditModal> createState() => _EditModalState();
}

class _EditModalState extends State<EditModal> {
  final supabase = DatabaseConfig.client;
  String? selectedMapelId;
  String? selectedJamMulai;
  String? selectedJamBerakhir;
  String? errorMessage;
  bool isLoading = false;
  bool isFetchingData = true;
  List<Map<String, dynamic>> mapelList = [];
  Map<String, dynamic>? selectedMapel;

  final List<String> mondayTimeSlots = [
    '07:30', '08:10', '08:50', '09:30', '10:10', '10:40', '11:20', '12:00', '12:40', '13:20'
  ];

  final List<String> otherDaysTimeSlots = [
    '06:30', '07:10', '07:50', '08:30', '09:10', '09:40',
    '10:20', '11:00', '11:40', '12:20', '13:00', '13:40', '14:20'
  ];

  List<String> get availableJamMulai => widget.hari == 'Senin' ? mondayTimeSlots : otherDaysTimeSlots;

  List<String> get availableJamBerakhir {
    if (selectedJamMulai == null) return [];
    final startIndex = availableJamMulai.indexOf(selectedJamMulai!);
    if (startIndex == -1) return [];
    return availableJamMulai.sublist(startIndex + 1);
  }

  @override
  void initState() {
    super.initState();
    final jamParts = widget.pelajaran.jam.split(' - ');
    selectedJamMulai = jamParts.isNotEmpty ? jamParts[0] : null;
    selectedJamBerakhir = jamParts.length > 1 ? jamParts[1] : null;
    _fetchMapelData();
  }

  Future<void> _fetchMapelData() async {
    setState(() => isFetchingData = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      // Fetch mapel dengan data guru yang terkait
      final mapelResponse = await supabase
          .from('mapel')
          .select('''
            id, 
            nama, 
            code_warna,
            guru:guru_id (id, nama)
          ''')
          .eq('u_id', user.id)
          .order('nama', ascending: true);

      setState(() {
        mapelList = List<Map<String, dynamic>>.from(mapelResponse);
        
        // Cari mapel yang sesuai dengan pelajaran saat ini
        final currentMapel = mapelList.firstWhere(
          (mapel) => mapel['nama'] == widget.pelajaran.nama,
          orElse: () => {},
        );
        
        if (currentMapel.isNotEmpty) {
          selectedMapel = currentMapel;
          selectedMapelId = currentMapel['id'] as String;
        }
        
        isFetchingData = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data mata pelajaran: $e';
        isFetchingData = false;
      });
    }
  }

  bool _checkScheduleConflict() {
    if (selectedJamMulai == null || selectedJamBerakhir == null) {
      return false;
    }

    final existingSchedules = widget.existingSchedules[widget.hari] ?? [];
    final originalJamParts = widget.pelajaran.jam.split(' - ');
    final originalStart = originalJamParts.isNotEmpty ? originalJamParts[0] : '00:00';
    final originalEnd = originalJamParts.length > 1 ? originalJamParts[1] : '00:00';

    for (final schedule in existingSchedules) {
      final existingStart = schedule['jamMulai'] as String;
      final existingEnd = schedule['jamBerakhir'] as String;

      // Skip jadwal yang sedang diedit
      if (existingStart == originalStart && existingEnd == originalEnd) {
        continue;
      }

      if (selectedJamMulai!.compareTo(existingEnd) < 0 &&
          selectedJamBerakhir!.compareTo(existingStart) > 0) {
        return true;
      }
    }
    return false;
  }

  Future<void> _updateToDatabase() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      if (selectedMapelId == null || selectedJamMulai == null || selectedJamBerakhir == null) {
        throw Exception('Data tidak lengkap');
      }

      // Dapatkan data mapel yang dipilih
      final selectedMapelData = mapelList.firstWhere(
        (mapel) => mapel['id'] == selectedMapelId,
        orElse: () => {},
      );

      if (selectedMapelData.isEmpty) {
        throw Exception('Mapel yang dipilih tidak valid');
      }

      final updatedData = {
        'mapel_id': selectedMapelId,
        'guru_id': selectedMapelData['guru']['id'],
        'jam_awal': '$selectedJamMulai:00',
        'jam_akhir': '$selectedJamBerakhir:00',
      };

      final response = await supabase
          .from('jadwal')
          .update(updatedData)
          .eq('id', widget.pelajaran.id)
          .select();

      if (response.isNotEmpty) {
        widget.onScheduleUpdated?.call();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jadwal berhasil diperbarui'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memperbarui jadwal: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleUpdate() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    if (selectedMapelId == null) {
      setState(() {
        errorMessage = 'Pilih mata pelajaran terlebih dahulu';
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
        errorMessage = 'Sudah ada jadwal di waktu yang sama';
        isLoading = false;
      });
      return;
    }

    await _updateToDatabase();
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

              isFetchingData
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMapelDropdown(),
              const SizedBox(height: 16),

              // Info Guru (otomatis menyesuaikan dengan mapel yang dipilih)
              _buildGuruInfo(),
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
          child: const Icon(
            Icons.edit,
            color: Color(0xFF4A4877),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Edit Jadwal Pelajaran',
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
              value: selectedMapelId,
              hint: const Text('Pilih mata pelajaran', style: TextStyle(color: Color(0xFF9CA3AF))),
              isExpanded: true,
              onChanged: isLoading
                  ? null
                  : (value) {
                      final selected = mapelList.firstWhere(
                        (mapel) => mapel['id'] == value,
                        orElse: () => {},
                      );
                      
                      setState(() {
                        selectedMapelId = value;
                        selectedMapel = selected.isNotEmpty ? selected : null;
                      });
                    },
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
                  : mapelList.map((mapel) {
                      return DropdownMenuItem<String>(
                        value: mapel['id'] as String,
                        child: Text(
                          mapel['nama'] as String,
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
              menuMaxHeight: 200,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuruInfo() {
    final guruNama = selectedMapel != null 
        ? selectedMapel!['guru']['nama'] as String? ?? 'Tidak diketahui'
        : widget.pelajaran.namaGuru;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guru',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF9FAFB),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Text(
                guruNama,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
            color: isLoading ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedJamMulai,
              hint: const Text('Pilih jam mulai', style: TextStyle(color: Color(0xFF9CA3AF))),
              isExpanded: true,
              onChanged: isLoading
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
              menuMaxHeight: 200,
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
              menuMaxHeight: 200,
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
              side: const BorderSide(color: const Color(0xFFE5E7EB)),
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
            onPressed: isLoading || isFetchingData ? null : _handleUpdate,
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