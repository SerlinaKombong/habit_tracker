import 'package:flutter/material.dart';

class HabitTile extends StatefulWidget {
  final String title;
  final String reminderTime;
  final bool isCompleted;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onDelete; // 🔴 Tambahan: Callback untuk memicu fungsi hapus

  const HabitTile({
    super.key,
    required this.title,
    required this.reminderTime,
    required this.isCompleted,
    required this.onChanged,
    required this.onDelete, // 🔴 Tambahan: Diwajibkan di constructor
  });

  @override
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _strikeThroughAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    // Animasi memanjang untuk garis coretan (0.0 belum tercoret, 1.0 coretan penuh)
    _strikeThroughAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Animasi pop skala kartu saat dicentang untuk efek dopamin taktil
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.96), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.96, end: 1.02), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Set kondisi awal animasi sesuai status completion dari database/provider
    if (widget.isCompleted) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant HabitTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Menyelaraskan status animasi jika ada perubahan eksternal (misal pindah tanggal kalender)
    if (widget.isCompleted != oldWidget.isCompleted) {
      if (widget.isCompleted) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            elevation: widget.isCompleted ? 0 : 2,
            color: widget.isCompleted
                ? (isDark ? Colors.grey[950] : Colors.grey[200])
                : (isDark ? Colors.grey[900] : Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: widget.isCompleted
                    ? Colors.transparent
                    : (isDark ? Colors.grey[800]! : Colors.grey[100]!),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => widget.onChanged(!widget.isCompleted),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Kustom Lingkaran Centang untuk Estetika yang Lebih Lembut
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: widget.isCompleted,
                        activeColor: theme.colorScheme.primary,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: widget.onChanged,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Area Informasi Konten Utama
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Efek Dopamin: Teks Beranimasi Coretan CustomPainter
                          CustomPaint(
                            foregroundPainter: _StrikeThroughPainter(
                              progress: _strikeThroughAnimation.value,
                              color: isDark ? Colors.grey[600]! : Colors.grey[500]!,
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: widget.isCompleted
                                    ? (isDark ? Colors.grey[600] : Colors.grey[500])
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                              child: Text(widget.title),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Subtitle Penanda Waktu Pengingat (Reminder Cue)
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: widget.isCompleted ? Colors.grey[600] : Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Reminder: ${widget.reminderTime}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isCompleted ? Colors.grey[600] : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 🔴 Tambahan: Tombol Titik Tiga untuk Menu Hapus Permanen
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'delete') {
                          widget.onDelete(); // Memanggil callback hapus dari HomeScreen
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              SizedBox(width: 8),
                              Text('Hapus Permanen', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom Painter untuk Menggambar Coretan Halus Beranimasi dari Kiri ke Kanan
class _StrikeThroughPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StrikeThroughPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Menghitung titik koordinat coretan di tengah-tengah tinggi teks secara vertikal
    final yPosition = size.height / 2;
    final startPoint = Offset(0, yPosition);
    final endPoint = Offset(size.width * progress, yPosition);

    canvas.drawLine(startPoint, endPoint, paint);
  }

  @override
  bool shouldRepaint(covariant _StrikeThroughPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}