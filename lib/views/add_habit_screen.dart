import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  bool _isSubmitting = false;

  // Map hari untuk UI lokal (Bahasa Indonesia) dan value DB (Bahasa Inggris)
  final List<Map<String, String>> _daysOfWeek = [
    {'id': 'Monday', 'name': 'Sen'},
    {'id': 'Tuesday', 'name': 'Sel'},
    {'id': 'Wednesday', 'name': 'Rab'},
    {'id': 'Thursday', 'name': 'Kam'},
    {'id': 'Friday', 'name': 'Jum'},
    {'id': 'Saturday', 'name': 'Sab'},
    {'id': 'Sunday', 'name': 'Min'},
  ];

  // Menyimpan hari apa saja yang dicentang user
  final List<String> _selectedDays = [];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _presentTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(data: Theme.of(context), child: child!),
    );
    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu hari untuk rutinitas ini!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final enteredTitle = _titleController.text.trim();
    final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    try {
      // Memanggil fungsi baru dengan menyertakan list hari
      await Provider.of<HabitProvider>(context, listen: false)
          .addHabitWithDays(enteredTitle, formattedTime, _selectedDays);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Gagal menyimpan habit: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan kebiasaan baru.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Habit Baru', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Nama Kebiasaan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.edit_calendar),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Mohon isi nama kebiasaan' : null,
                ),
                const SizedBox(height: 20),

                // WIDGET PILIH HARI (MULTIPLE SELECT) - SEKARANG BISA DIGESER
                Text('Ulangi Setiap Hari:', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _daysOfWeek.map((day) {
                      final isSelected = _selectedDays.contains(day['id']);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(day['name']!, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          checkmarkColor: Colors.white,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(day['id']!);
                              } else {
                                _selectedDays.remove(day['id']!);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 0,
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.alarm, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pengingat Waktu', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                Text(_selectedTime.format(context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _isSubmitting ? null : _presentTimePicker,
                          icon: const Icon(Icons.timer_outlined),
                          label: const Text('Ubah Jam'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2.5))
                      : const Text('Mulai Rutinitas Baru 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}