/// Compact events timeline shown at the bottom of the new home page.
library;

import 'package:collection/collection.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/app/home/_widgets/history_timeline_item.dart';
import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/app/new_home/layout.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart';

/// Compact events list grouped by date, reusing the original
/// [HistoryTimelineItem] for visual continuity.
class EventsTimeline extends StatelessWidget {
  /// Maximum events to display inline; tapping "查看全部" opens the full list.
  final int maxItems;

  /// Creates an [EventsTimeline].
  const EventsTimeline({super.key, this.maxItems = 5});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, List<History>>(
      selector: (_, m) => m.alerts,
      builder: (context, events, _) {
        return Padding(
          padding: const .symmetric(horizontal: 12, vertical: 8),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                InkWell(
                  onTap: () => NewHomeShell.of(context)?.setTab(tabEvents),
                  child: Padding(
                    padding: const .fromLTRB(16, 12, 12, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.colors.secondaryContainer,
                            borderRadius: .circular(10),
                          ),
                          child: Icon(
                            Symbols.history_rounded,
                            color: context.colors.onSecondaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '事件'.i18n,
                            style: context.texts.titleMedium?.copyWith(
                              fontWeight: .w700,
                            ),
                          ),
                        ),
                        Text(
                          '更多'.i18n,
                          style: context.texts.labelMedium?.copyWith(
                            color: context.colors.primary,
                            fontWeight: .w600,
                          ),
                        ),
                        Icon(
                          Symbols.chevron_right_rounded,
                          color: context.colors.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (events.isEmpty)
                  Padding(
                    padding: const .fromLTRB(16, 8, 16, 24),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: .circle,
                            color: context.colors.outlineVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          TZDateTime.now(UTC).toLocaleFullDateString(context),
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '尚無近期事件'.i18n,
                            style: context.texts.bodySmall?.copyWith(
                              color: context.colors.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _GroupedList(events: events.take(maxItems).toList()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GroupedList extends StatelessWidget {
  final List<History> events;
  const _GroupedList({required this.events});

  @override
  Widget build(BuildContext context) {
    final grouped = groupBy(
      events,
      (History e) => e.time.send.toLocaleFullDateString(context),
    ).entries.sorted((a, b) => b.key.compareTo(a.key)).toList();

    return Padding(
      padding: const .symmetric(vertical: 4),
      child: Column(
        children: [
          for (final entry in grouped) ...[
            _DateChip(date: entry.key),
            for (final item in entry.value)
              HistoryTimelineItem(
                history: item,
                expired: item.isExpired,
                last: item == grouped.last.value.last,
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String date;
  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const .symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.secondaryContainer,
              borderRadius: .circular(8),
            ),
            child: Text(
              date,
              style: context.texts.labelMedium?.copyWith(
                color: context.colors.onSecondaryContainer,
                fontWeight: .w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
