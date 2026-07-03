import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/habit_provider.dart';
import 'home_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habitProv = context.read<HabitProvider>();
      // Pastikan data statistik terbaru ditarik/dihitung
      habitProv.calculateStreaks();
      // habitProv.calculateWeeklyStats(); // Panggil fungsi ini jika sudah dibuat
    });
  }

  // Indeks 0 = Senin, 6 = Minggu
  String _getWeekdayName(int index) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[index % 7];
  }

  @override
  Widget build(BuildContext context) {
    final habitProv = Provider.of<HabitProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Data mingguan: Mengambil list [Senin, Selasa, ..., Minggu]
    final List<double> weeklyData = habitProv.weeklyCompletionCounts ?? [0, 0, 0, 0, 0, 0, 0];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistik Performa", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Section 1: Streaks
            Row(
              children: [
                _buildStatCard("🔥 Runtunan", "${habitProv.currentStreak} hari", Colors.orange, theme),
                const SizedBox(width: 16),
                _buildStatCard("🏆 Rekor", "${habitProv.longestStreak} hari", Colors.amber, theme),
              ],
            ),
            const SizedBox(height: 32),

            // Section 2: Chart
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Performa Minggu Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              padding: const EdgeInsets.only(top: 16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (weeklyData.reduce((a, b) => a > b ? a : b) + 2).toDouble(), // Dinamis
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.primary,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem('${rod.toY.toInt()} Selesai', const TextStyle(color: Colors.white)),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(_getWeekdayName(value.toInt()), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: weeklyData[index],
                          color: theme.colorScheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const HomeScreen(), transitionDuration: Duration.zero));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Kalender"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistik"),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, ThemeData theme) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}