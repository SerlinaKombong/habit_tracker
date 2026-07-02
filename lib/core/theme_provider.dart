theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // Key konstanta untuk menyimpan preferensi di memori lokal perangkat
  static const String _themeKey = "is_dark_mode";

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get currentTheme => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Constructor: Otomatis memuat tema yang terakhir kali disimpan saat aplikasi dijalankan
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // 1. Membaca preferensi tema dari penyimpanan lokal HP saat inisialisasi awal
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal memuat preferensi tema: $e");
    }
  }

  // 2. Mengubah tema secara real-time sekaligus menyimpannya ke memori fisik HP
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Memicu pembangunan ulang visual (re-render) pada seluruh UI

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint("Gagal menyimpan preferensi tema: $e");
    }
  }
}