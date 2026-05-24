/// Full-screen hero weather section displayed at the top of the home page.
library;

import 'dart:math';

import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Displays the current temperature and weather condition as a large hero
/// widget.
///
/// Shows a loading skeleton while [isLoading] is `true`, an empty state when
/// [weather] is `null`, or the full weather content otherwise.
class HeroWeather extends StatelessWidget {
  /// The current weather data, or `null` when unavailable.
  final RealtimeWeather? weather;

  /// When `true`, shows a loading placeholder instead of weather data.
  final bool isLoading;

  /// Creates a [HeroWeather] widget.
  const HeroWeather({
    super.key,
    this.weather,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = context.dimension.height;
    final statusBarHeight = context.padding.top;

    return SizedBox(
      height: screenHeight * 0.5,
      child: Stack(
        children: [
          Positioned(
            top: statusBarHeight + 80,
            left: 32,
            right: 32,
            child: isLoading
                ? _buildLoadingState(context)
                : weather != null
                ? _buildWeatherContent(context)
                : _buildEmptyState(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Container(
          width: 100,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: .circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: .circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: .circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherContent(BuildContext context) {
    final data = weather!.data;
    final e =
        data.humidity / 100 * 6.105 * exp(17.27 * data.temperature / (data.temperature + 237.3));
    final feelsLike = data.temperature + 0.33 * e - 0.7 * data.wind.speed - 4.0;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          '${data.temperature.round()}°',
          style: context.texts.displayLarge?.copyWith(
            fontSize: 72,
            fontWeight: .w300,
            color: Colors.white,
            height: 1,
            letterSpacing: -2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: .min,
          children: [
            Icon(
              _getWeatherIcon(data.weatherCode),
              size: 24,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              data.weather,
              style: context.texts.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: .w400,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '體感 {feelsLike}°'.i18n.args({
            'feelsLike': feelsLike.round(),
          }),
          style: context.texts.bodyMedium?.copyWith(
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          '--°',
          style: context.texts.displayLarge?.copyWith(
            fontSize: 72,
            fontWeight: .w300,
            color: Colors.white.withValues(alpha: 0.5),
            height: 1,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: .min,
          children: [
            Icon(
              Symbols.cloud_off_rounded,
              size: 24,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              '無天氣資料'.i18n,
              style: context.texts.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Returns the appropriate [IconData] for the given CWA weather [code].
  IconData _getWeatherIcon(int code) => switch (code) {
    >= 1 && <= 3 => Symbols.clear_day_rounded,
    >= 4 && <= 7 => Symbols.partly_cloudy_day_rounded,
    >= 8 && <= 14 => Symbols.cloud_rounded,
    >= 15 && <= 22 => Symbols.rainy_rounded,
    >= 23 && <= 28 => Symbols.rainy_heavy_rounded,
    >= 29 && <= 35 => Symbols.thunderstorm_rounded,
    >= 36 && <= 41 => Symbols.weather_snowy_rounded,
    >= 42 => Symbols.foggy_rounded,
    _ => Symbols.cloud_rounded,
  };
}
