/// Earthquake Early Warning alert card for the new home page.
library;

import 'dart:async';

import 'package:dpip/api/model/eew.dart';
import 'package:dpip/core/eew.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

/// Foreground/border alpha for the muted onErrorContainer text style.
const double _mutedAlpha = 0.7;

/// Displays the active EEW alert(s) as compact tappable cards.
///
/// Renders nothing when no EEW is active. Tap navigates to the monitor map.
class EewAlerts extends StatelessWidget {
  /// Creates an [EewAlerts].
  const EewAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<DpipDataModel, List<Eew>>(
      selector: (_, m) => m.eew,
      builder: (context, eews, _) {
        if (eews.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const .symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: .min,
            children: [for (final e in eews) _EewCard(eew: e)],
          ),
        );
      },
    );
  }
}

class _EewCard extends StatefulWidget {
  final Eew eew;
  const _EewCard({required this.eew});

  @override
  State<_EewCard> createState() => _EewCardState();
}

class _EewCardState extends State<_EewCard> {
  int? _localIntensity;
  int? _arrivalMs;
  int _countdown = 0;
  Timer? _ticker;

  void _tick() {
    final arrival = _arrivalMs;
    if (arrival == null) return;
    final remaining = ((arrival - GlobalProviders.data.currentTime) / 1000).floor();
    if (remaining < -1) return;
    if (mounted && remaining != _countdown) setState(() => _countdown = remaining);
  }

  @override
  void initState() {
    super.initState();
    final coords = GlobalProviders.location.coordinates;
    if (coords != null) {
      final info = eewLocationInfo(
        widget.eew.info.magnitude,
        widget.eew.info.depth,
        widget.eew.info.latitude,
        widget.eew.info.longitude,
        coords.latitude,
        coords.longitude,
      );
      _localIntensity = intensityFloatToInt(info.i);
      _arrivalMs = (widget.eew.info.time +
              sWaveTimeByDistance(widget.eew.info.depth, info.dist))
          .floor();
    }
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onContainer = colors.onErrorContainer;
    final muted = onContainer.withValues(alpha: _mutedAlpha);
    final eq = widget.eew.info;
    final intensity = _localIntensity;

    return Padding(
      padding: const .symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: .circular(24),
        child: InkWell(
          onTap: () => const MapRoute(layers: 'monitor').push(context),
          splashColor: colors.error.withValues(alpha: 0.18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: .topLeft,
                end: .bottomRight,
                colors: [
                  colors.errorContainer,
                  Color.alphaBlend(
                    colors.error.withValues(alpha: 0.18),
                    colors.errorContainer,
                  ),
                ],
              ),
              border: Border.all(color: colors.error, width: 1.5),
              borderRadius: .circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors.error.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const .all(16),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                _Header(serial: widget.eew.serial, onContainer: onContainer, error: colors.error, onError: colors.onError),
                const SizedBox(height: 12),
                Text(
                  eq.location,
                  style: context.texts.titleLarge?.copyWith(
                    color: onContainer,
                    fontWeight: .w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  spacing: 8,
                  children: [
                    _Chip(label: 'M ${eq.magnitude.toStringAsFixed(1)}', color: onContainer),
                    _Chip(label: '${eq.depth.toStringAsFixed(0)} km', color: onContainer),
                  ],
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: .stretch,
                    children: [
                      Expanded(
                        child: _InfoBlock(
                          label: '所在地預估'.i18n,
                          muted: muted,
                          child: Text(
                            intensity?.asIntensityLabel ?? '—',
                            style: context.texts.displaySmall?.copyWith(
                              color: onContainer,
                              fontWeight: .w800,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      VerticalDivider(
                        color: onContainer.withValues(alpha: 0.25),
                        width: 24,
                      ),
                      Expanded(
                        child: _InfoBlock(
                          label: '震波抵達'.i18n,
                          align: .end,
                          muted: muted,
                          child: _countdown <= 0
                              ? Text(
                                  '抵達'.i18n,
                                  style: context.texts.displaySmall?.copyWith(
                                    color: onContainer,
                                    fontWeight: .w800,
                                    height: 1.0,
                                  ),
                                )
                              : _Countdown(seconds: _countdown, onContainer: onContainer, muted: muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

class _Header extends StatelessWidget {
  final int serial;
  final Color onContainer;
  final Color error;
  final Color onError;

  const _Header({
    required this.serial,
    required this.onContainer,
    required this.error,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Container(
          padding: const .symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: error, borderRadius: .circular(999)),
          child: Row(
            mainAxisSize: .min,
            spacing: 4,
            children: [
              Icon(Symbols.crisis_alert_rounded, color: onError, size: 16, weight: 700),
              Text(
                'EEW'.i18n,
                style: context.texts.labelMedium?.copyWith(
                  color: onError,
                  fontWeight: .w800,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            '第 {serial} 報'.i18n.args({'serial': serial}),
            style: context.texts.labelLarge?.copyWith(
              color: onContainer,
              fontWeight: .w600,
            ),
          ),
        ),
        Icon(Symbols.chevron_right_rounded, color: onContainer),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final Widget child;
  final Color muted;
  final CrossAxisAlignment align;

  const _InfoBlock({
    required this.label,
    required this.child,
    required this.muted,
    this.align = .start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: context.texts.labelMedium?.copyWith(color: muted)),
        child,
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  final int seconds;
  final Color onContainer;
  final Color muted;

  const _Countdown({
    required this.seconds,
    required this.onContainer,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .end,
      crossAxisAlignment: .baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$seconds',
          style: context.texts.displayMedium?.copyWith(
            color: onContainer,
            fontWeight: .w800,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '秒'.i18n,
          style: context.texts.titleMedium?.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: .circular(6),
      ),
      child: Text(
        label,
        style: context.texts.labelMedium?.copyWith(
          color: color,
          fontWeight: .w600,
        ),
      ),
    );
  }
}
