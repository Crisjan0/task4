import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WalkToGrowApp());
}

const Color armyGreen = Color(0xFF4B5320);
const Color forestGreen = Color(0xFF228B22);
const Color softGreen = Color(0xFFE8F5E9);

class WalkToGrowApp extends StatelessWidget {
  const WalkToGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Walk to Grow',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: armyGreen,
          primary: armyGreen,
          secondary: forestGreen,
          surface: const Color(0xFFF7FAF2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F6EC),
        appBarTheme: const AppBarTheme(
          backgroundColor: armyGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const UsernameGate(),
    );
  }
}

/// Lets each user enter their name so progress is saved per user.
class UsernameGate extends StatefulWidget {
  const UsernameGate({super.key});

  @override
  State<UsernameGate> createState() => _UsernameGateState();
}

class _UsernameGateState extends State<UsernameGate> {
  final _controller = TextEditingController();

  void _start() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(username: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, size: 72, color: armyGreen),
              const SizedBox(height: 16),
              const Text(
                'Walk to Grow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: armyGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Every step helps your plant grow',
                style: TextStyle(color: Color(0xFF6B7049)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _start(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: armyGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _start,
                  child: const Text('Start', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _steps = 0;
  String _status = 'Step tracking waiting...';
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  String get _key => 'steps_${widget.username.toLowerCase()}';

  @override
  void initState() {
    super.initState();
    _load();
    _initPedometer();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _steps = prefs.getInt(_key) ?? 0);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, _steps);
  }

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      setState(() => _status = 'Permission denied. Use + button to add steps.');
      return;
    }
    try {
      _stepSub = Pedometer.stepCountStream.listen(
        (event) {
          final last = _lastSensorSteps;
          _lastSensorSteps = event.steps;
          if (last == null) return; // first reading establishes baseline
          final delta = event.steps - last;
          if (delta > 0) {
            setState(() => _steps += delta);
            _save();
          }
        },
        onError: (_) => setState(() => _status = 'Step sensor unavailable. Use + button.'),
      );
      _statusSub = Pedometer.pedestrianStatusStream.listen(
        (event) => setState(() => _status = event.status),
        onError: (_) {},
      );
    } catch (_) {
      setState(() => _status = 'Step sensor unavailable. Use + button.');
    }
  }

  int? _lastSensorSteps;

  void _addSteps(int n) {
    setState(() => _steps += n);
    _save();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  // Growth: 0-499 seed, 500-1999 sprout, 2000-4999 stem, 5000-9999 leaves, 10000+ flower
  int get _stage {
    if (_steps >= 10000) return 4;
    if (_steps >= 5000) return 3;
    if (_steps >= 2000) return 2;
    if (_steps >= 500) return 1;
    return 0;
  }

  String get _stageName =>
      ['Seed', 'Sprout', 'Growing Stem', 'Leafy Plant', 'Blooming Flower'][_stage];

  @override
  Widget build(BuildContext context) {
    final progress = (_steps % 10000) / 10000.0;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${widget.username} 🌱'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UsernameGate()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CustomPaint(
                  size: const Size(220, 260),
                  painter: PlantPainter(stage: _stage, steps: _steps),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _stageName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: armyGreen,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress == 0 && _stage < 4 ? 0.02 : progress,
              color: forestGreen,
              backgroundColor: const Color(0xFFDDE7D0),
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 20),
            _statCard('Total Steps', '$_steps', Icons.directions_walk),
            const SizedBox(height: 12),
            _statCard('Status', _status, Icons.sensors),
            const SizedBox(height: 12),
            _statCard('Next stage', _nextTarget, Icons.flag_outlined),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(onPressed: () => _addSteps(100), child: const Text('+100')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: armyGreen),
                  onPressed: () => _addSteps(500),
                  child: const Text('+500'),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() => _steps = 0);
                    _save();
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _nextTarget {
    if (_steps >= 10000) return 'Fully grown!';
    if (_steps >= 5000) return '10,000 steps to bloom';
    if (_steps >= 2000) return '5,000 steps for leaves';
    if (_steps >= 500) return '2,000 steps for stem';
    return '500 steps to sprout';
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: armyGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: armyGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlantPainter extends CustomPainter {
  final int stage;
  final int steps;
  PlantPainter({required this.stage, required this.steps});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final groundY = h * 0.85;

    // Pot
    final potPaint = Paint()..color = const Color(0xFF8D6E63);
    final pot = Path()
      ..moveTo(cx - 45, groundY)
      ..lineTo(cx + 45, groundY)
      ..lineTo(cx + 35, h)
      ..lineTo(cx - 35, h)
      ..close();
    canvas.drawPath(pot, potPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - 50, groundY - 12, 100, 16), const Radius.circular(6)),
      Paint()..color = const Color(0xFF6D4C41),
    );

    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final leafPaint = Paint()..color = const Color(0xFF43A047);

    if (stage == 0) {
      // Seed
      canvas.drawCircle(Offset(cx, groundY - 8), 8, Paint()..color = const Color(0xFF795548));
      return;
    }

    final stemHeight = [0.0, 25.0, 70.0, 130.0, 160.0][stage];
    final topY = groundY - 12 - stemHeight;
    canvas.drawLine(Offset(cx, groundY - 12), Offset(cx, topY), stemPaint);

    if (stage >= 3) {
      // Leaves
      _leaf(canvas, Offset(cx, groundY - 50), -1, leafPaint);
      _leaf(canvas, Offset(cx, groundY - 85), 1, leafPaint);
      if (stage == 4) _leaf(canvas, Offset(cx, groundY - 120), -1, leafPaint);
    } else if (stage == 2) {
      _leaf(canvas, Offset(cx, groundY - 45), 1, leafPaint);
    } else if (stage == 1) {
      // Sprout leaves
      _leaf(canvas, Offset(cx, topY), -1, leafPaint, scale: 0.5);
      _leaf(canvas, Offset(cx, topY), 1, leafPaint, scale: 0.5);
    }

    if (stage == 4) {
      // Flower
      final petalPaint = Paint()..color = const Color(0xFFFFC0CB);
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        canvas.drawCircle(
          Offset(cx + 14 * math.cos(angle), topY - 4 + 14 * math.sin(angle)),
          9,
          petalPaint,
        );
      }
      canvas.drawCircle(Offset(cx, topY - 4), 10, Paint()..color = const Color(0xFFFFD54F));
    }
  }

  void _leaf(Canvas canvas, Offset base, int dir, Paint paint, {double scale = 1}) {
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + dir * 30 * scale, base.dy - 20 * scale, base.dx + dir * 45 * scale, base.dy)
      ..quadraticBezierTo(base.dx + dir * 30 * scale, base.dy + 12 * scale, base.dx, base.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PlantPainter old) => old.stage != stage || old.steps != steps;
}
