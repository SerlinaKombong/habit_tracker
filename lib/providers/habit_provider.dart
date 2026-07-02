import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit_model.dart';
import 'package:intl/intl.dart'; // Pastikan intl ada di pubspec.yaml kamu

class HabitProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Habit> _habits = [];
  Map<String, bool> _selectedDateProgress = {};
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  int _currentStreak = 0;
  int _longestStreak = 0;
  List<double> _weeklyCompletionCounts = [0, 0, 0, 0, 0, 0, 0];

  List<Habit> get habits => _habits;
  Map<String, bool> get selectedDateProgress => _selectedDateProgress;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  List<double> get weeklyCompletionCounts => _weeklyCompletionCounts;

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void changeSelectedDate(DateTime date) {
    _selectedDate = date;
    fetchHabitsForDate(date);
  }

  // 2. Ambil data habit berdasarkan HARI pada tanggal terpilih
  Future<void> fetchHabitsForDate(DateTime date) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Dapatkan nama hari dari tanggal terpilih (e.g., 'Monday', 'Tuesday')
      final String dayName = DateFormat('EEEE').format(date);

      // Tarik habit yang daftar 'repeat_days'-nya mengandung hari tersebut
      final habitResponse = await _supabase
          .from('habits')
          .select()
          .eq('user_id', user.id)
          .contains('repeat_days', [dayName])
          .order('created_at', ascending: true);

      _habits = (habitResponse as List).map((h) => Habit.fromJson(h)).toList();

      final dateStr = _formatDate(date);
      final progressResponse = await _supabase
          .from('daily_progress')
          .select()
          .eq('date', dateStr);

      _selectedDateProgress = {};
      for (var habit in _habits) {
        _selectedDateProgress[habit.id] = false;
      }
      for (var p in progressResponse) {
        _selectedDateProgress[p['habit_id']] = p['is_completed'] as bool;
      }

      await calculateStreaks();
    } catch (e) {
      debugPrint("Error fetching data for date: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Tambah habit baru dengan list hari berulang
  Future<void> addHabitWithDays(String title, String time, List<String> repeatDays) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('habits').insert({
        'user_id': user.id,
        'title': title,
        'reminder_time': '$time:00',
        'repeat_days': repeatDays, // Menyimpan array hari
      });
      await fetchHabitsForDate(_selectedDate);
    } catch (e) {
      debugPrint("Error adding habit: $e");
      rethrow;
    }
  }

  // 🔴 FITUR HAPUS HABIT PERMANEN
  Future<void> deleteHabit(String habitId) async {
    try {
      await _supabase.from('habits').delete().eq('id', habitId);
      await fetchHabitsForDate(_selectedDate);
    } catch (e) {
      debugPrint("Error deleting habit: $e");
      rethrow;
    }
  }

  Future<void> toggleHabit(String habitId, bool isDone) async {
    final dateStr = _formatDate(_selectedDate);
    final oldStatus = _selectedDateProgress[habitId] ?? false;

    try {
      _selectedDateProgress[habitId] = isDone;
      notifyListeners();

      await _supabase.from('daily_progress').upsert({
        'habit_id': habitId,
        'date': dateStr,
        'is_completed': isDone,
      }, onConflict: 'habit_id, date');

      await calculateStreaks();
    } catch (e) {
      debugPrint("Error toggling habit: $e");
      _selectedDateProgress[habitId] = oldStatus;
      notifyListeners();
    }
  }

  Future<void> calculateStreaks() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _habits.isEmpty) {
      _currentStreak = 0;
      _longestStreak = 0;
      _weeklyCompletionCounts = [0, 0, 0, 0, 0, 0, 0];
      notifyListeners();
      return;
    }

    try {
      final response = await _supabase
          .from('daily_progress')
          .select('date, is_completed')
          .eq('is_completed', true);

      if (response == null || (response as List).isEmpty) {
        _currentStreak = 0;
        _longestStreak = 0;
        _weeklyCompletionCounts = [0, 0, 0, 0, 0, 0, 0];
        notifyListeners();
        return;
      }

      final List<dynamic> progressList = response as List;

      final DateTime now = DateTime.now();
      final DateTime mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));

      List<String> thisWeekDaysStr = List.generate(7, (index) {
        return _formatDate(mondayThisWeek.add(Duration(days: index)));
      });

      List<double> updatedWeeklyCounts = [0, 0, 0, 0, 0, 0, 0];

      for (var progress in progressList) {
        String pDate = progress['date'] as String;
        int dayIndex = thisWeekDaysStr.indexOf(pDate);
        if (dayIndex != -1) {
          updatedWeeklyCounts[dayIndex] += 1;
        }
      }
      _weeklyCompletionCounts = updatedWeeklyCounts;

      final List<String> rawDates = progressList.map((item) => item['date'] as String).toList();
      final Set<String> uniqueDatesSet = Set.from(rawDates);
      List<DateTime> sortedDates = uniqueDatesSet.map((d) => DateTime.parse(d)).toList();

      sortedDates.sort((a, b) => a.compareTo(b));
      if (sortedDates.isEmpty) return;

      int maxStreak = 0;
      int currentRunningStreak = 0;

      for (int i = 0; i < sortedDates.length; i++) {
        if (i == 0) {
          currentRunningStreak = 1;
        } else {
          final difference = sortedDates[i].difference(sortedDates[i - 1]).inDays;
          if (difference == 1) {
            currentRunningStreak++;
          } else if (difference > 1) {
            if (currentRunningStreak > maxStreak) {
              maxStreak = currentRunningStreak;
            }
            currentRunningStreak = 1;
          }
        }
      }

      if (currentRunningStreak > maxStreak) maxStreak = currentRunningStreak;
      _longestStreak = maxStreak;

      final todayStr = _formatDate(DateTime.now());
      final yesterdayStr = _formatDate(DateTime.now().subtract(const Duration(days: 1)));

      bool hasActivityToday = uniqueDatesSet.contains(todayStr);
      bool hasActivityYesterday = uniqueDatesSet.contains(yesterdayStr);

      if (!hasActivityToday && !hasActivityYesterday) {
        _currentStreak = 0;
      } else {
        int currentStreakCount = 0;
        DateTime checkDate = hasActivityToday ? DateTime.now() : DateTime.now().subtract(const Duration(days: 1));

        while (uniqueDatesSet.contains(_formatDate(checkDate))) {
          currentStreakCount++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
        _currentStreak = currentStreakCount;
      }
    } catch (e) {
      debugPrint("Gagal kalkulasi streak: $e");
    } finally {
      notifyListeners();
    }
  }

  void clearDataOnLogout() {
    _habits = [];
    _selectedDateProgress = {};
    _currentStreak = 0;
    _longestStreak = 0;
    _weeklyCompletionCounts = [0, 0, 0, 0, 0, 0, 0];
    notifyListeners();
  }
}