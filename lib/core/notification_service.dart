import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Fungsi menjadwalkan notifikasi harian berdasarkan string waktu "HH:mm:ss"
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String timeString, // Contoh: "07:00:00"
  }) async {
    try {
      final parts = timeString.split(':');
      final int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      // Jika waktu hari ini sudah lewat, jadwalkan untuk besok hari
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        'Waktunya membangun habit! ⚡',
        'Jangan lupa penuhi target: $title',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_loop_channel',
            'Habit Reminders',
            channelDescription: 'Notifikasi pengingat rutinitas harian',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Berulang setiap hari pada jam yang sama
      );
    } catch (e) {
      print("Gagal menjadwalkan notifikasi: $e");
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}