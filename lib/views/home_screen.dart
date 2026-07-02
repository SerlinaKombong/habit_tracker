import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/habit_provider.dart';
import '../core/theme_provider.dart';
import '../core/notification_service.dart';
import '../widgets/habit_tile.dart';
import 'add_habit_screen.dart';
import 'stats_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadDataAndScheduleReminders();
  }

  Future<void> _loadDataAndScheduleReminders() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final habitProv = context.read<HabitProvider>();
        await habitProv.fetchHabitsForDate(habitProv.selectedDate);

        try {
          await NotificationService.cancelAllNotifications();
        } catch (e) {
          debugPrint("Gagal membersihkan notifikasi: $e");
        }

        for (int i = 0; i < habitProv.habits.length; i++) {
          final habit = habitProv.habits[i];
          try {
            await NotificationService.scheduleDailyNotification(
              id: habit.id.hashCode,
              title: habit.title,
              timeString: habit.reminderTime,
            );
          } catch (e) {
            debugPrint("Gagal mendaftarkan pengingat: $e");
          }
        }
      }
    });
  }

  Future<void> _handleLogout() async {
    try {
      final navigatorState = Navigator.of(context, rootNavigator: true);
      context.read<HabitProvider>().clearDataOnLogout();
      try {
        await NotificationService.cancelAllNotifications();
      } catch (e) {}
      await Supabase.instance.client.auth.signOut();
      navigatorState.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      debugPrint("Gagal logout: $e");
    }
  }

  // Helper dialog agar logika kode konfirmasi hapus tidak duplikat
  Future<bool?> _showDeleteDialog(BuildContext context, String habitTitle) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Habit?'),
        content: Text('Apakah kamu yakin ingin menghapus "$habitTitle" dari daftar rutinitas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Helper eksekusi hapus ke database
  Future<void> _executeDelete(HabitProvider provider, String habitId, String habitTitle) async {
    try {
      await provider.deleteHabit(habitId);
      _loadDataAndScheduleReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$habitTitle" berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus data dari database.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitProv = Provider.of<HabitProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("HabitLoop", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(themeProv.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProv.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keluar Aplikasi?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleLogout();
                      },
                      child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SingleChildScrollView(
                child: TableCalendar(
                  firstDay: DateTime.utc(2025, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: habitProv.selectedDate,
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  weekendDays: const [DateTime.sunday],
                  rowHeight: 45,
                  daysOfWeekHeight: 22,
                  availableCalendarFormats: const {CalendarFormat.month: '1 Bulan', CalendarFormat.week: '1 Minggu'},
                  onFormatChanged: (format) => setState(() => _calendarFormat = format),
                  selectedDayPredicate: (day) => isSameDay(habitProv.selectedDate, day),
                  onDaySelected: (selectedDay, focusedDay) async {
                    habitProv.changeSelectedDate(selectedDay);
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    selectedDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.2), shape: BoxShape.circle),
                    todayTextStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    formatButtonShowsNext: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.primary),
                    rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Rutinitas Harian", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${habitProv.selectedDate.day}/${habitProv.selectedDate.month}/${habitProv.selectedDate.year}",
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: habitProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : habitProv.habits.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text("Belum ada kebiasaan terjadwal hari ini.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadDataAndScheduleReminders,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: habitProv.habits.length,
                itemBuilder: (context, index) {
                  final habit = habitProv.habits[index];
                  final isDone = habitProv.selectedDateProgress[habit.id] ?? false;

                  // FITUR SWIPE KIRI UNTUK HAPUS PERMANEN (TETAP DI-MAINTAIN)
                  return Dismissible(
                    key: Key(habit.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await _showDeleteDialog(context, habit.title);
                    },
                    onDismissed: (direction) async {
                      await _executeDelete(habitProv, habit.id, habit.title);
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: HabitTile(
                      title: habit.title,
                      reminderTime: habit.reminderTime,
                      isCompleted: isDone,
                      onChanged: (val) {
                        if (val != null) habitProv.toggleHabit(habit.id, val);
                      },
                      // 🔴 BERHASIL DITAMBAHKAN: Menghubungkan titik 3 ke database cloud
                      onDelete: () async {
                        final confirm = await _showDeleteDialog(context, habit.title);
                        if (confirm == true) {
                          await _executeDelete(habitProv, habit.id, habit.title);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddHabitScreen()));
          _loadDataAndScheduleReminders();
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Kalender"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistik"),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, anim1, anim2) => const StatsScreen(),
                transitionDuration: Duration.zero,
              ),
            );
          }
        },
      ),
    );
  }
}