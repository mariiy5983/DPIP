/// GPU-light particle overlay (rain, snow, lightning) for the weather background.
library;

import 'dart:math';

import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/app/new_home/_models/weather_params.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef _ParticleParams = ({
  double rain,
  int weatherCode,
  double wind,
});

/// Animated weather particles layered above the shader sky background.
///
/// Renders nothing when rain weight is negligible. Snow takes over below ~5°C
/// when rain weight is moderate, and rare lightning flashes appear with the
/// thunderstorm weather code.
class WeatherParticles extends StatefulWidget {
  /// Creates a [WeatherParticles] overlay.
  const WeatherParticles({super.key});

  @override
  State<WeatherParticles> createState() => _WeatherParticlesState();
}

class _WeatherParticlesState extends State<WeatherParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, _ParticleParams>(
      selector: (_, m) {
        final d = m.weather?.data;
        return (
          rain: rainWeight(d),
          weatherCode: d?.weatherCode ?? 0,
          wind: windWeight(d),
        );
      },
      builder: (context, p, _) {
        if (p.rain < 0.05) return const SizedBox.shrink();

        final temp = context.read<HomeModel>().weather?.data.temperature ?? 20;
        final isSnow = temp < 5 && p.rain > 0.2;
        final isThunder = (p.weatherCode % 100) == 14 ||
            (p.weatherCode % 100) == 17 ||
            (p.weatherCode % 100) == 18 ||
            (p.weatherCode % 100) == 19;

        return IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              size: .infinite,
              painter: _ParticlePainter(
                listenable: _ticker,
                isSnow: isSnow,
                isThunder: isThunder,
                density: p.rain.clamp(0.0, 1.0),
                wind: p.wind,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _ParticlePainter extends CustomPainter {
  final Animation<double> listenable;
  final bool isSnow;
  final bool isThunder;
  final double density;
  final double wind;

  /// Deterministic particle seeds so each particle keeps a stable identity
  /// across frames — only its phase advances.
  static final List<_Seed> _seeds = List.generate(120, (i) {
    final r = Random(i * 31 + 7);
    return _Seed(
      x: r.nextDouble(),
      speed: 0.6 + r.nextDouble() * 0.9,
      scale: 0.5 + r.nextDouble() * 0.7,
      phase: r.nextDouble(),
    );
  });

  _ParticlePainter({
    required this.listenable,
    required this.isSnow,
    required this.isThunder,
    required this.density,
    required this.wind,
  }) : super(repaint: listenable);

  @override
  void paint(Canvas canvas, Size size) {
    final t = listenable.value;
    final count = (_seeds.length * density).clamp(8, _seeds.length.toDouble()).toInt();
    final windOffset = wind * 80;

    if (isSnow) {
      _paintSnow(canvas, size, t, count, windOffset);
    } else {
      _paintRain(canvas, size, t, count, windOffset);
    }
    if (isThunder) {
      _paintLightning(canvas, size, t);
    }
  }

  void _paintRain(Canvas canvas, Size size, double t, int count, double wOff) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    for (var i = 0; i < count; i++) {
      final s = _seeds[i];
      // Vertical fall cycle: phase advances by speed * 4 cycles per minute (t∈[0,1)).
      final progress = (s.phase + t * s.speed * 8) % 1.0;
      final y = progress * (size.height + 60) - 30;
      final x = s.x * size.width + wOff * progress;
      final dropLen = 12 + s.scale * 8;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - wOff * 0.04, y + dropLen),
        paint..strokeWidth = 1.2 * s.scale,
      );
    }
  }

  void _paintSnow(Canvas canvas, Size size, double t, int count, double wOff) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < count; i++) {
      final s = _seeds[i];
      final progress = (s.phase + t * s.speed * 2) % 1.0;
      final y = progress * (size.height + 30) - 15;
      // Slight horizontal sway.
      final sway = sin((s.phase + t * 4) * pi * 2) * 12 * s.scale;
      final x = s.x * size.width + wOff * progress + sway;
      final radius = 1.5 + s.scale * 2.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _paintLightning(Canvas canvas, Size size, double t) {
    // ~3 flashes per minute. Each flash lasts ~120ms.
    final phase = (t * 6) % 1.0;
    if (phase > 0.04) return;
    final alpha = (1 - phase / 0.04) * 0.7;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.7)),
    );
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.isSnow != isSnow ||
      old.isThunder != isThunder ||
      old.density != density ||
      old.wind != wind;
}

class _Seed {
  final double x;
  final double speed;
  final double scale;
  final double phase;

  const _Seed({
    required this.x,
    required this.speed,
    required this.scale,
    required this.phase,
  });
}
