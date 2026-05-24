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
            children: eews.map((e) => _EewCard(eew: e)).toList(),
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
    if (_arrivalMs == null) return;
    final remaining = ((_arrivalMs! - GlobalProviders.data.currentTime) / 1000).floor();
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
    final eq = widget.eew.info;
    final intensity = _localIntensity;
    final arrived = _countdown <= 0;

    return Padding(
      padding: const .symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: .circular(24),
        child: InkWell(
          onTap: () => MapRoute(layers: 'monitor').push(context),
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
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const .symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: .circular(999),
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        spacing: 4,
                        children: [
                          Icon(Symbols.crisis_alert_rounded,
                              color: colors.onError, size: 16, weight: 700),
                          Text('EEW'.i18n,
                              style: context.texts.labelMedium?.copyWith(
                                color: colors.onError,
                                fontWeight: .w800,
                              )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '第 {serial} 報'.i18n.args({'serial': widget.eew.serial}),
                        style: context.texts.labelLarge?.copyWith(
                          color: colors.onErrorContainer,
                          fontWeight: .w600,
                        ),
                      ),
                    ),
                    Icon(Symbols.chevron_right_rounded,
                        color: colors.onErrorContainer),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  eq.location,
                  style: context.texts.titleLarge?.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: .w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  spacing: 8,
                  children: [
                    _Chip(
                      label: 'M ${eq.magnitude.toStringAsFixed(1)}',
                      color: colors.onErrorContainer,
                    ),
                    _Chip(
                      label: '${eq.depth.toStringAsFixed(0)} km',
                      color: colors.onErrorContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: .end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            '所在地預估'.i18n,
                            style: context.texts.labelMedium?.copyWith(
                              color: colors.onErrorContainer.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            intensity?.asIntensityLabel ?? '—',
                            style: context.texts.displaySmall?.copyWith(
                              color: colors.onErrorContainer,
                              fontWeight: .w800,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 56,
                      color: colors.onErrorContainer.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .end,
                        children: [
                          Text(
                            '震波抵達'.i18n,
                            style: context.texts.labelMedium?.copyWith(
                              color: colors.onErrorContainer.withValues(alpha: 0.7),
                            ),
                          ),
                          if (arrived)
                            Text(
                              '抵達'.i18n,
                              style: context.texts.displaySmall?.copyWith(
                                color: colors.onErrorContainer,
                                fontWeight: .w800,
                                height: 1.0,
                              ),
                            )
                          else
                            Row(
                              mainAxisAlignment: .end,
                              crossAxisAlignment: .baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$_countdown',
                                  style: context.texts.displayMedium?.copyWith(
                                    color: colors.onErrorContainer,
                                    fontWeight: .w800,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '秒'.i18n,
                                  style: context.texts.titleMedium?.copyWith(
                                    color: colors.onErrorContainer.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
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
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
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
