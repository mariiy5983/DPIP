/// Horizontal 24-hour weather forecast with a continuous temperature curve.
library;

import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

/// Width allotted to a single hourly column inside the scroll viewport.
const double _columnWidth = 56;

/// Height of the temperature curve area (above the icons row).
const double _chartHeight = 86;

/// Top padding inside the chart so labels don't clip the card edge.
const double _chartTopPad = 22;

/// Bottom padding inside the chart so dots clear the icons row.
const double _chartBottomPad = 12;

/// Parsed hourly forecast entry — kept lightweight for the painter.
class _Hour {
  final String time;
  final String weather;
  final int pop;
  final double temp;

  const _Hour({
    required this.time,
    required this.weather,
    required this.pop,
    required this.temp,
  });

  factory _Hour.from(Map<String, dynamic> m) => _Hour(
        time: (m['time'] as String?) ?? '',
        weather: (m['weather'] as String?) ?? '',
        pop: (m['pop'] as num?)?.toInt() ?? 0,
        temp: (m['temperature'] as num?)?.toDouble() ?? 0.0,
      );
}

/// A horizontally-scrolling 24-hour forecast strip with a smooth temperature
/// curve overlay (Apple Weather-style).
///
/// Reads from [HomeModel.forecast]. Renders nothing when forecast data is
/// missing or malformed.
class ForecastStrip extends StatelessWidget {
  /// Creates a [ForecastStrip].
  const ForecastStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, Map<String, dynamic>?>(
      selector: (_, m) => m.forecast,
      builder: (context, forecast, _) {
        final raw = forecast?['forecast'] as List?;
        if (raw == null || raw.isEmpty) return const SizedBox.shrink();

        final hours = [for (final m in raw) _Hour.from(m as Map<String, dynamic>)];
        var minTemp = double.infinity;
        var maxTemp = double.negativeInfinity;
        for (final h in hours) {
          if (h.temp < minTemp) minTemp = h.temp;
          if (h.temp > maxTemp) maxTemp = h.temp;
        }
        if (maxTemp - minTemp < 1) {
          // Avoid a flat-line look when the day is isothermal.
          minTemp -= 1;
          maxTemp += 1;
        }

        return Padding(
          padding: const .symmetric(horizontal: 12, vertical: 8),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const .symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  _Header(low: minTemp, high: maxTemp),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: _chartHeight + 78,
                    child: SingleChildScrollView(
                      scrollDirection: .horizontal,
                      padding: const .symmetric(horizontal: 12),
                      child: _Chart(
                        hours: hours,
                        minTemp: minTemp,
                        maxTemp: maxTemp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final double low;
  final double high;

  const _Header({required this.low, required this.high});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const .fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Icon(Symbols.schedule_rounded, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            '24 小時預報'.i18n,
            style: context.texts.titleSmall?.copyWith(fontWeight: .w700),
          ),
          const Spacer(),
          _TempRange(label: '最低'.i18n, value: low, color: _coolColor),
          const SizedBox(width: 12),
          _TempRange(label: '最高'.i18n, value: high, color: _warmColor),
        ],
      ),
    );
  }
}

class _TempRange extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TempRange({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: .circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ${value.round()}°',
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: .w600,
          ),
        ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  final List<_Hour> hours;
  final double minTemp;
  final double maxTemp;

  const _Chart({
    required this.hours,
    required this.minTemp,
    required this.maxTemp,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final width = hours.length * _columnWidth;

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          // Smooth curve + filled area + dots + temperature labels.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: _chartHeight,
            child: CustomPaint(
              painter: _CurvePainter(
                hours: hours,
                minTemp: minTemp,
                maxTemp: maxTemp,
                labelStyle: context.texts.labelMedium!.copyWith(
                  color: colors.onSurface,
                  fontWeight: .w700,
                ),
              ),
            ),
          ),
          // Icon + pop% + time row, anchored under the chart.
          Positioned(
            left: 0,
            right: 0,
            top: _chartHeight,
            child: Row(
              children: [
                for (final h in hours)
                  SizedBox(
                    width: _columnWidth,
                    child: _HourColumn(hour: h),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HourColumn extends StatelessWidget {
  final _Hour hour;
  const _HourColumn({required this.hour});

  static (IconData, Color) _iconFor(String weather) => switch (weather) {
        final s when s.contains('晴') => (Symbols.sunny_rounded, Colors.orangeAccent),
        final s when s.contains('雷') => (Symbols.thunderstorm_rounded, Colors.amber),
        final s when s.contains('雨') => (Symbols.rainy_rounded, Colors.lightBlue),
        final s when s.contains('雪') => (Symbols.snowflake_rounded, Colors.lightBlueAccent),
        final s when s.contains('雲') || s.contains('陰') => (Symbols.cloud_rounded, Colors.blueGrey),
        _ => (Symbols.wb_cloudy_rounded, Colors.grey),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, iconColor) = _iconFor(hour.weather);

    return Padding(
      padding: const .symmetric(vertical: 8),
      child: Column(
        mainAxisSize: .min,
        children: [
          Icon(icon, color: iconColor, fill: 1, size: 22),
          const SizedBox(height: 6),
          SizedBox(
            height: 14,
            child: hour.pop > 0
                ? Row(
                    mainAxisAlignment: .center,
                    mainAxisSize: .min,
                    children: [
                      const Icon(
                        Symbols.water_drop_rounded,
                        size: 10,
                        color: Colors.lightBlue,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${hour.pop}%',
                        style: context.texts.labelSmall?.copyWith(
                          color: Colors.lightBlue,
                          fontWeight: .w600,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            hour.time,
            style: context.texts.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cool end of the temperature gradient (≤ minTemp).
const Color _coolColor = Color(0xFF42A5F5);

/// Warm end of the temperature gradient (≥ maxTemp).
const Color _warmColor = Color(0xFFFF7043);

/// Paints a smooth temperature curve with dots and labels.
///
/// Uses a quadratic-bezier midpoint smoothing technique: each curve segment
/// passes through midpoints between consecutive data points using the actual
/// point as the control. Produces a clean Apple-Weather-style line.
class _CurvePainter extends CustomPainter {
  final List<_Hour> hours;
  final double minTemp;
  final double maxTemp;
  final TextStyle labelStyle;

  const _CurvePainter({
    required this.hours,
    required this.minTemp,
    required this.maxTemp,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hours.isEmpty) return;

    final range = maxTemp - minTemp;
    final chartUsable = size.height - _chartTopPad - _chartBottomPad;
    Offset pointFor(int i) {
      final h = hours[i];
      final pct = (h.temp - minTemp) / range;
      final x = i * _columnWidth + _columnWidth / 2;
      final y = _chartTopPad + (1 - pct) * chartUsable;
      return Offset(x, y);
    }

    final points = [for (var i = 0; i < hours.length; i++) pointFor(i)];

    // Smooth curve through points via midpoint quadratic bezier.
    final curve = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      curve.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    curve.lineTo(points.last.dx, points.last.dy);

    // Vertical gradient: warm at the top of the chart (high temps), cool at
    // the bottom (low temps). Each segment of the curve picks up the colour
    // that matches its own height — semantically correct regardless of which
    // way the temperature trend runs.
    final chartRect = Rect.fromLTWH(0, _chartTopPad, size.width, chartUsable);

    // Soft filled area below the curve.
    final fill = Path.from(curve)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _warmColor.withValues(alpha: 0.28),
            _coolColor.withValues(alpha: 0.04),
          ],
        ).createShader(chartRect),
    );

    // Curve stroke uses the same vertical gradient at full opacity.
    canvas.drawPath(
      curve,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_warmColor, _coolColor],
        ).createShader(chartRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots + labels per point. Dot colour is computed from the same vertical
    // ramp so a dot's appearance matches the underlying curve.
    final dotPaintInner = Paint()..color = Colors.white;
    for (var i = 0; i < hours.length; i++) {
      final p = points[i];
      // Map the dot's Y position into the [_warmColor, _coolColor] ramp
      // exactly like the curve gradient does.
      final tempColor = Color.lerp(
        _warmColor,
        _coolColor,
        ((p.dy - _chartTopPad) / chartUsable).clamp(0.0, 1.0),
      )!;

      // Dot: outer color ring + inner white.
      canvas.drawCircle(p, 4.5, Paint()..color = tempColor);
      canvas.drawCircle(p, 2.2, dotPaintInner);

      // Temperature label above the dot.
      final label = TextPainter(
        text: TextSpan(text: '${hours[i].temp.round()}°', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(p.dx - label.width / 2, p.dy - label.height - 8),
      );
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.hours != hours ||
      old.minTemp != minTemp ||
      old.maxTemp != maxTemp ||
      old.labelStyle != labelStyle;
}
