/// Thunderstorm advisory card for the new home page.
library;

import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/route/event_viewer/thunderstorm.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color_scheme.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:styled_text/styled_text.dart';

/// Displays an active thunderstorm advisory pulled from [HomeModel].
///
/// Renders nothing when no thunderstorm is active near the user's location.
class ThunderstormAlert extends StatelessWidget {
  /// Creates a [ThunderstormAlert].
  const ThunderstormAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, History?>(
      selector: (_, m) => m.thunderstorm,
      builder: (context, alert, _) {
        if (alert == null) return const SizedBox.shrink();
        return _Card(alert: alert);
      },
    );
  }
}

class _Card extends StatelessWidget {
  final History alert;
  const _Card({required this.alert});

  @override
  Widget build(BuildContext context) {
    final extended = context.theme.extendedColors;
    return Padding(
      padding: const .symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: .circular(20),
        child: InkWell(
          onTap: () => context.navigator.push(
            MaterialPageRoute(builder: (_) => ThunderstormPage(item: alert)),
          ),
          splashColor: extended.blue.withValues(alpha: 0.18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: .topLeft,
                end: .bottomRight,
                colors: [
                  extended.blueContainer,
                  Color.alphaBlend(
                    extended.blue.withValues(alpha: 0.18),
                    extended.blueContainer,
                  ),
                ],
              ),
              border: Border.all(color: extended.blue, width: 1.2),
              borderRadius: .circular(20),
            ),
            padding: const .all(14),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  padding: const .all(10),
                  decoration: BoxDecoration(
                    color: extended.blue,
                    borderRadius: .circular(12),
                  ),
                  child: Icon(
                    Symbols.thunderstorm_rounded,
                    color: extended.onBlue,
                    size: 24,
                    weight: 700,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        '雷雨即時訊息'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          color: extended.onBlueContainer,
                          fontWeight: .w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      StyledText(
                        text: '持續至 <bold>{time}</bold>'.i18n.args({
                          'time': alert.time.expiresAt.toSimpleDateTimeString(),
                        }),
                        style: context.texts.bodySmall?.copyWith(
                          color: extended.onBlueContainer.withValues(alpha: 0.85),
                        ),
                        tags: {
                          'bold': StyledTextTag(
                            style: const TextStyle(fontWeight: .w700),
                          ),
                        },
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right_rounded,
                  color: extended.onBlueContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
