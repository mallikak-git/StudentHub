import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum TimerMode { focus, shortBreak, longBreak }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  TimerMode _mode = TimerMode.focus;
  int _seconds = 25 * 60;
  bool _running = false;
  Timer? _timer;
  int _sessionsCompleted = 0;
  List<Map<String, String>> _log = [];
  late AnimationController _pulseCtrl;

  static const _durations = {
    TimerMode.focus: 25 * 60,
    TimerMode.shortBreak: 5 * 60,
    TimerMode.longBreak: 15 * 60,
  };

  static const _modeLabels = {
    TimerMode.focus: 'Focus',
    TimerMode.shortBreak: 'Short Break',
    TimerMode.longBreak: 'Long Break',
  };

  static const _modeColors = {
    TimerMode.focus: Color(0xFF6C63FF),
    TimerMode.shortBreak: Color(0xFF43E97B),
    TimerMode.longBreak: Color(0xFFF7971E),
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _switchMode(TimerMode mode) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _seconds = _durations[mode]!;
      _running = false;
    });
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_seconds > 0) {
          setState(() => _seconds--);
        } else {
          _timer?.cancel();
          setState(() {
            _running = false;
            if (_mode == TimerMode.focus) {
              _sessionsCompleted++;
              final now = DateTime.now();
              _log.insert(0, {
                'label': 'Focus session #$_sessionsCompleted',
                'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              });
              if (_log.length > 10) _log.removeLast();
            }
            _seconds = 0;
          });
          _showDoneSnackbar();
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _seconds = _durations[_mode]!;
      _running = false;
    });
  }

  void _showDoneSnackbar() {
    if (!mounted) return;
    final msg = _mode == TimerMode.focus ? 'Focus session done! Take a break 🎉' : 'Break over! Time to focus 💪';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _modeColors[_mode], behavior: SnackBarBehavior.floating),
    );
  }

  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = _durations[_mode]!;
    return 1 - (_seconds / total);
  }

  @override
  Widget build(BuildContext context) {
    final color = _modeColors[_mode]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Study Timer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Mode selector
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8)],
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                children: TimerMode.values.map((m) {
                  final sel = _mode == m;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _switchMode(m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? _modeColors[m] : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _modeLabels[m]!,
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),
            // Circular timer
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: _running ? 240 + _pulseCtrl.value * 10 : 240,
                      height: _running ? 240 + _pulseCtrl.value * 10 : 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha:_running ? 0.05 + _pulseCtrl.value * 0.03 : 0.05),
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: _RingPainter(progress: _progress, color: color),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_timeStr, style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: color)),
                      Text(_modeLabels[_mode]!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.replay, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 20),
                // Play/Pause
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [BoxShadow(color: color.withValues(alpha:0.4), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Icon(_running ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 20),
                // Skip
                GestureDetector(
                  onTap: () {
                    final next = TimerMode.values[(_mode.index + 1) % TimerMode.values.length];
                    _switchMode(next);
                  },
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.skip_next, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Session dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(4, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < (_sessionsCompleted % 4) ? color : Colors.grey[200],
                    border: Border.all(color: i < (_sessionsCompleted % 4) ? color : Colors.grey[300]!),
                  ),
                )),
                const SizedBox(width: 12),
                Text('$_sessionsCompleted session${_sessionsCompleted == 1 ? '' : 's'} today',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            // Session log
            if (_log.isNotEmpty) ...[
              const SizedBox(height: 28),
              Align(alignment: Alignment.centerLeft,
                  child: const Text('Session Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: _log.map((l) => ListTile(
                    dense: true,
                    leading: CircleAvatar(backgroundColor: color.withValues(alpha:0.15), radius: 16,
                        child: Icon(Icons.check, size: 14, color: color)),
                    title: Text(l['label']!, style: const TextStyle(fontSize: 14)),
                    trailing: Text(l['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track
    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = color.withValues(alpha:0.15));

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}
