import 'package:flutter/material.dart';
import '/connect.dart'; // Import database config

class AddModal extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> existingSchedules;
  final VoidCallback? onScheduleAdded; // Callback untuk refresh data

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
  final TextEditingController namaController = TextEditingController();
  final TextEditingController jamMulaiController = TextEditingController();
  final TextEditingController jamBerakhirController = TextEditingController();
  Color selectedColor = const Color(0xFF6366F1);
  String? errorMessage;
  bool isLoading = false;

  final List<String> hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    "Jum'at",
    'Sabtu',
  ];

  final List<Color> colorOptions = [
    const Color(0xFF6366F1),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFFEF4444),
    const Color(0xFFF97316),
    const Color(0xFFEAB308),
    const Color(0xFF22C55E),
    const Color(0xFF10B981),
    const Color(0xFF06B6D4),
    const Color(0xFF3B82F6),
    const Color(0xFF8B5A2B),
    const Color(0xFF6B7280),
  ];

  bool _validateTimeFormat(String time) {
    final RegExp timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _checkScheduleConflict() {
    if (selectedHari == null) return false;

    final existingSchedules = widget.existingSchedules[selectedHari] ?? [];
    final newStart = _parseTime(jamMulaiController.text);
    final newEnd = _parseTime(jamBerakhirController.text);

    for (final schedule in existingSchedules) {
      final existingStart = _parseTime(schedule['jamMulai']);
      final existingEnd = _parseTime(schedule['jamBerakhir']);

      if ((newStart.hour * 60 + newStart.minute) <
              (existingEnd.hour * 60 + existingEnd.minute) &&
          (newEnd.hour * 60 + newEnd.minute) >
              (existingStart.hour * 60 + existingStart.minute)) {
        return true;
      }
    }
    return false;
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _saveToDatabase() async {
    try {
      final supabase = DatabaseConfig.client;
      
      final data = {
        'hari': selectedHari!,
        'nama': namaController.text.trim(),
        'jam_awal': jamMulaiController.text.trim(),
        'jam_akhir': jamBerakhirController.text.trim(),
        'code_warna': _colorToHex(selectedColor),
      };

      final response = await supabase
          .from('jadwal')
          .insert(data)
          .select();

      if (response.isNotEmpty) {
        // Berhasil disimpan
        if (widget.onScheduleAdded != null) {
          widget.onScheduleAdded!();
        }
        
        Navigator.pop(context, true); // Return true untuk menandakan berhasil
        
        // Tampilkan snackbar sukses
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Jadwal ${namaController.text} berhasil ditambahkan'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal menyimpan ke database: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    // Validasi hari
    if (selectedHari == null) {
      setState(() {
        errorMessage = 'Pilih hari terlebih dahulu';
        isLoading = false;
      });
      return;
    }

    // Validasi nama pelajaran
    if (namaController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Nama pelajaran tidak boleh kosong';
        isLoading = false;
      });
      return;
    }

    // Validasi jam mulai
    if (jamMulaiController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Jam mulai tidak boleh kosong';
        isLoading = false;
      });
      return;
    }

    if (!_validateTimeFormat(jamMulaiController.text)) {
      setState(() {
        errorMessage = 'Format jam mulai tidak valid (HH:mm)';
        isLoading = false;
      });
      return;
    }

    // Validasi jam berakhir
    if (jamBerakhirController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Jam berakhir tidak boleh kosong';
        isLoading = false;
      });
      return;
    }

    if (!_validateTimeFormat(jamBerakhirController.text)) {
      setState(() {
        errorMessage = 'Format jam berakhir tidak valid (HH:mm)';
        isLoading = false;
      });
      return;
    }

    final startTime = _parseTime(jamMulaiController.text);
    final endTime = _parseTime(jamBerakhirController.text);

    if (endTime.isBefore(startTime)) {
      setState(() {
        errorMessage = 'Jam berakhir harus setelah jam mulai';
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

    // Simpan ke database
    await _saveToDatabase();
  }

  @override
  void dispose() {
    namaController.dispose();
    jamMulaiController.dispose();
    jamBerakhirController.dispose();
    super.dispose();
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
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

              _buildTextFieldWithLabel(
                label: 'Nama Pelajaran *',
                controller: namaController,
                hint: 'Masukkan nama pelajaran',
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextFieldWithLabel(
                      label: 'Jam Mulai *',
                      controller: jamMulaiController,
                      hint: '08:00',
                      enabled: !isLoading,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFieldWithLabel(
                      label: 'Jam Berakhir *',
                      controller: jamBerakhirController,
                      hint: '09:30',
                      enabled: !isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildColorPickerSection(),
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
            color: selectedColor.withOpacity(0.1),
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
              hint: const Text(
                'Pilih hari',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              isExpanded: true,
              onChanged: isLoading ? null : (value) => setState(() => selectedHari = value),
              items: hariList.map((hari) {
                return DropdownMenuItem(
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

  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              color: enabled ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Warna',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: isLoading ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Warna Terpilih',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: colorOptions.length,
                itemBuilder: (context, index) {
                  final color = colorOptions[index];
                  final isSelected = selectedColor == color;

                  return MouseRegion(
                    cursor: isLoading ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: isLoading ? null : () => setState(() => selectedColor = color),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ],
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
            onPressed: isLoading ? null : _handleSave,
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