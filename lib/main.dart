import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduSchedule',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Jadwal Pembelajaran'),
    );
  }
}

// Model class for better structure
class Subject {
  final String name;
  final String time;
  final Color color;

  const Subject({
    required this.name,
    required this.time,
    required this.color,
  });
}

class DaySchedule {
  final String day;
  final String date;
  final List<Subject> subjects;

  const DaySchedule({
    required this.day,
    required this.date,
    required this.subjects,
  });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Using model classes for better type safety
  static const List<DaySchedule> _schedule = [
    DaySchedule(
      day: 'Senin',
      date: 'Juli 1',
      subjects: [
        Subject(name: 'BKK', time: '07:30 - 08:50', color: Color(0xFF4169E1)),
        Subject(name: 'BING', time: '08:50 - 10:10', color: Color(0xFFF8961E)),
        Subject(name: 'KRPL 4', time: '10:40 - 13:20', color: Color(0xFFFF9A8B)),
      ],
    ),
    DaySchedule(
      day: 'Selasa',
      date: 'Juli 2',
      subjects: [
        Subject(name: 'KRPL 4', time: '06:30 - 11:00', color: Color(0xFFFF9A8B)),
        Subject(name: 'BJ', time: '11:00 - 12:20', color: Color(0xFF4CC9F0)),
        Subject(name: 'BING', time: '13:00 - 14:20', color: Color(0xFFF8961E)),
      ],
    ),
    DaySchedule(
      day: 'Rabu',
      date: 'Juli 3',
      subjects: [
        Subject(name: 'KRPL 4', time: '06:30 - 11:00', color: Color(0xFFFF9A8B)),
        Subject(name: 'MPG', time: '11:00 - 14:20', color: Color(0xFFFF9A8B)),
      ],
    ),
    DaySchedule(
      day: 'Kamis',
      date: 'Juli 4',
      subjects: [
        Subject(name: 'PKDK', time: '06:30 - 10:20', color: Color(0xFFDA70D6)),
        Subject(name: 'PP', time: '10:20 - 11:40', color: Color(0xFF7209B7)),
        Subject(name: 'PAI', time: '11:40 - 14:20', color: Color(0xFF0096FF)),
      ],
    ),
    DaySchedule(
      day: "Jum'at",
      date: 'Juli 5',
      subjects: [
        Subject(name: 'KRPL 4', time: '06:30 - 11:00', color: Color(0xFFFF9A8B)),
      ],
    ),
    DaySchedule(
      day: "Sabtu",
      date: 'Juli 6',
      subjects: [
        Subject(name: 'MTK', time: '06:30 - 08:30', color: Color(0xFF90EE90)),
        Subject(name: 'BIN', time: '08:30 - 11:00', color: Color(0xFF006400)),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(theme),
      body: _buildBody(),
      floatingActionButton: _buildFAB(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        widget.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: theme.colorScheme.primary,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: _schedule.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _ScheduleCard(
          daySchedule: _schedule[index],
          isExpanded: index == 0,
          dayNumber: index + 1,
        ),
      ),
    );
  }

  Widget _buildFAB(ThemeData theme) {
    return FloatingActionButton(
      onPressed: _onAddSchedule,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.add),
    );
  }

  void _onAddSchedule() {
    showDialog(
      context: context,
      builder: (BuildContext context) => const _AddScheduleDialog(),
    );
  }
}

// Separate widget for better organization and performance
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.daySchedule,
    required this.isExpanded,
    required this.dayNumber,
  });

  final DaySchedule daySchedule;
  final bool isExpanded;
  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: _buildTitle(theme),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: daySchedule.subjects
                  .map((subject) => _SubjectCard(subject: subject))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                daySchedule.day,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                daySchedule.date,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Separate widget for subject cards
class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: subject.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: subject.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          subject.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subject.time),
        trailing: Icon(
          Icons.more_vert,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

// Add Schedule Dialog
class _AddScheduleDialog extends StatefulWidget {
  const _AddScheduleDialog();

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _timeStartController = TextEditingController();
  final _timeEndController = TextEditingController();
  final _colorController = TextEditingController(text: '#6C63FF');

  String _selectedDay = 'Senin';
  Color _selectedColor = const Color(0xFF6C63FF);

  final List<String> _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu', 'Minggu'
  ];

  final List<Color> _presetColors = [
    const Color(0xFF6C63FF), // Purple
    const Color(0xFF4169E1), // Royal Blue
    const Color(0xFFF8961E), // Orange
    const Color(0xFFFF9A8B), // Coral
    const Color(0xFF4CC9F0), // Sky Blue
    const Color(0xFFDA70D6), // Orchid
    const Color(0xFF7209B7), // Dark Violet
    const Color(0xFF0096FF), // Blue
    const Color(0xFF90EE90), // Light Green
    const Color(0xFF006400), // Dark Green
    const Color(0xFFFF6B6B), // Red
    const Color(0xFFFFE66D), // Yellow
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _timeStartController.dispose();
    _timeEndController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 24),
                  _buildDayDropdown(theme),
                  const SizedBox(height: 16),
                  _buildSubjectField(theme),
                  const SizedBox(height: 16),
                  _buildTimeFields(theme),
                  const SizedBox(height: 16),
                  _buildColorSection(theme),
                  const SizedBox(height: 24),
                  _buildButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.add_circle_outline,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Jadwal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Buat jadwal pembelajaran baru',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildDayDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hari',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDay,
              icon: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.primary),
              items: _days.map((String day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDay = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nama Pelajaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _subjectController,
          decoration: InputDecoration(
            hintText: 'Contoh: Matematika',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama pelajaran tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTimeFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waktu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _timeStartController,
                decoration: InputDecoration(
                  hintText: '07:30',
                  labelText: 'Mulai',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: const Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Waktu mulai harus diisi';
                  }
                  return null;
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: _timeEndController,
                decoration: InputDecoration(
                  hintText: '08:50',
                  labelText: 'Selesai',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: const Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Waktu selesai harus diisi';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Warna',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Color Preview
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        hintText: '#6C63FF',
                        labelText: 'Kode Hex',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        if (value.startsWith('#') && value.length == 7) {
                          try {
                            final color = Color(
                              int.parse(value.substring(1), radix: 16) + 0xFF000000,
                            );
                            setState(() {
                              _selectedColor = color;
                            });
                          } catch (e) {
                            // Invalid hex color, ignore
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Preset Colors
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Atau pilih warna preset:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors.map((color) {
                  final isSelected = _selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                        _colorController.text = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey.shade300,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Here you would normally save the schedule
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Jadwal ${_subjectController.text} pada hari $_selectedDay berhasil ditambahkan!',
                    ),
                    backgroundColor: _selectedColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Simpan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}