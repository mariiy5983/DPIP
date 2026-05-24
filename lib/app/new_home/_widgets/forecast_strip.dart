/// Horizontal 24-hour weather forecast strip for the new home page.
library;

import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

/// A horizontally-scrolling 24-hour forecast strip.
///
/// Reads from [HomeModel.forecast]. Renders nothing when forecast data is
/// missing or malformed. Each column shows a time, an icon, probability of
/// precipitation, and a normalized temperature bar.
class ForecastStrip extends StatelessWidget {
  /// Creates a [ForecastStrip].
  const ForecastStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, Map<String, dynamic>?>(
      selector: (_, m) => m.forecast,
      builder: (context, forecast, _) {
        final data = forecast?['forecast'] as List?;
        if (data == null || data.isEmpty) return const SizedBox.shrink();

        double minTemp = double.infinity;
        double maxTemp = double.negativeInfinity;
        for (final item in data) {
          final t = (item['temperature'] as num?)?.toDouble() ?? 0.0;
          if (t < minTemp) minTemp = t;
          if (t > maxTemp) maxTemp = t;
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
                  Padding(
                    padding: const .fromLTRB(16, 0, 16, 8),
                    child: Row(
                      spacing: 8,
                      children: [
                        Icon(
                          Symbols.schedule_rounded,
                          size: 18,
                          color: context.colors.primary,
                        ),
                        Text(
                          '24 小時預報'.i18n,
                          style: context.texts.titleSmall?.copyWith(
                            fontWeight: .w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 168,
                    child: ListView.builder(
                      scrollDirection: .horizontal,
                      padding: const .symmetric(horizontal: 8),
                      itemCount: data.length,
                      itemBuilder: (context, i) {
                        final item = data[i] as Map<String, dynamic>;
                        return _Column(
                          item: item,
                          minTemp: minTemp,
                          maxTemp: maxTemp,
                        );
                      },
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

class _Column extends StatelessWidget {
  final Map<String, dynamic> item;
  final double minTemp;
  final double maxTemp;

  const _Column({
    required this.item,
    required this.minTemp,
    required this.maxTemp,
  });

  static (IconData, Color) _icon(String weather) => switch (weather) {
    final s when s.contains('晴') => (Symbols.sunny_rounded, Colors.orangeAccent),
    final s when s.contains('雷') => (Symbols.thunderstorm_rounded, Colors.amber),
    final s when s.contains('雨') => (Symbols.rainy_rounded, Colors.lightBlue),
    final s when s.contains('雪') => (Symbols.snowflake_rounded, Colors.lightBlueAccent),
    final s when s.contains('雲') || s.contains('陰') => (
      Symbols.cloud_rounded,
      Colors.blueGrey,
    ),
    _ => (Symbols.wb_cloudy_rounded, Colors.grey),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final time = item['time'] as String? ?? '';
    final weather = item['weather'] as String? ?? '';
    final pop = (item['pop'] as num?)?.toInt() ?? 0;
    final temp = (item['temperature'] as num?)?.toDouble() ?? 0.0;
    final range = maxTemp - minTemp;
    final pct = range > 0 ? (temp - minTemp) / range : 0.5;
    final (icon, color) = _icon(weather);

    return Container(
      width: 52,
      padding: const .symmetric(horizontal: 4, vertical: 6),
      child: Column(
        children: [
          Text(
            '${temp.round()}°',
            style: context.texts.titleSmall?.copyWith(fontWeight: .w700),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const .all(6),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: .circular(8),
            ),
            child: Icon(icon, color: color, fill: 1, size: 20),
          ),
          const SizedBox(height: 4),
          if (pop > 0)
            Text(
              '$pop%',
              style: context.texts.labelSmall?.copyWith(
                color: Colors.lightBlue,
                fontWeight: .w600,
              ),
            )
          else
            const SizedBox(height: 14),
          Expanded(
            child: Padding(
              padding: const .symmetric(vertical: 4),
              child: FractionallySizedBox(
                widthFactor: 0.4,
                heightFactor: pct.clamp(0.15, 1.0),
                alignment: .bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: .topCenter,
                      end: .bottomCenter,
                      colors: [
                        colors.tertiary,
                        colors.tertiary.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: .circular(8),
                  ),
                ),
              ),
            ),
          ),
          Text(
            time,
            style: context.texts.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
