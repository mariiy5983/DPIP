/// Events tab page — full history list grouped by date.
library;

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/app/home/_widgets/history_timeline_item.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Mode for the events list — regional vs national, active vs history.
enum _EventsMode { localActive, localHistory, nationalActive, nationalHistory }

/// Dedicated events tab page with mode-switchable timeline.
class EventsPage extends StatefulWidget {
  /// Creates an [EventsPage].
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  _EventsMode _mode = _EventsMode.localActive;
  List<History>? _events;
  Object? _error;
  bool _loading = false;

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final code = GlobalProviders.location.code;
    // Fall back to national when no location is set and a local mode is selected.
    var effectiveMode = _mode;
    if (code == null) {
      if (_mode == _EventsMode.localActive) effectiveMode = _EventsMode.nationalActive;
      if (_mode == _EventsMode.localHistory) effectiveMode = _EventsMode.nationalHistory;
    }

    try {
      final list = switch (effectiveMode) {
        _EventsMode.localActive => await ExpTech().getRealtimeRegion(code!),
        _EventsMode.localHistory => await ExpTech().getHistoryRegion(code!),
        _EventsMode.nationalActive => await ExpTech().getRealtime(),
        _EventsMode.nationalHistory => await ExpTech().getHistory(),
      };
      if (!mounted) return;
      setState(() {
        _events = list..sort((a, b) => b.time.send.compareTo(a.time.send));
        _error = null;
        _loading = false;
      });
    } catch (e, s) {
      TalkerManager.instance.error('EventsPage.fetch', e, s);
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text('事件'.i18n),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: _ModeBar(
                current: _mode,
                hasLocation: GlobalProviders.location.code != null,
                onChanged: (m) {
                  if (m == _mode) return;
                  setState(() => _mode = m);
                  _fetch();
                },
              ),
            ),
            if (_loading && _events == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _events == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: .center,
                    children: [
                      Icon(
                        Symbols.error_rounded,
                        color: colors.error,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text('載入失敗'.i18n),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: _fetch,
                        child: Text('再試一次'.i18n),
                      ),
                    ],
                  ),
                ),
              )
            else if (_events == null || _events!.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const .all(24),
                    child: Column(
                      mainAxisAlignment: .center,
                      children: [
                        Icon(
                          Symbols.event_busy_rounded,
                          size: 48,
                          color: colors.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '尚無事件'.i18n,
                          style: context.texts.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              _Timeline(events: _events!),
            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        ),
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  final _EventsMode current;
  final bool hasLocation;
  final ValueChanged<_EventsMode> onChanged;

  const _ModeBar({
    required this.current,
    required this.hasLocation,
    required this.onChanged,
  });

  bool get _isLocal =>
      current == _EventsMode.localActive || current == _EventsMode.localHistory;

  bool get _isActive =>
      current == _EventsMode.localActive || current == _EventsMode.nationalActive;

  void _select({required bool local, required bool active}) {
    onChanged(switch ((local, active)) {
      (true, true) => _EventsMode.localActive,
      (true, false) => _EventsMode.localHistory,
      (false, true) => _EventsMode.nationalActive,
      (false, false) => _EventsMode.nationalHistory,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          // Region filter.
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text('所在地'.i18n),
                icon: const Icon(Symbols.location_on_rounded),
                enabled: hasLocation,
              ),
              ButtonSegment(
                value: false,
                label: Text('全國'.i18n),
                icon: const Icon(Symbols.public_rounded),
              ),
            ],
            selected: {_isLocal && hasLocation},
            onSelectionChanged: (s) => _select(local: s.first, active: _isActive),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 8),
          // Time filter.
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text('生效中'.i18n),
                icon: const Icon(Symbols.notifications_active_rounded),
              ),
              ButtonSegment(
                value: false,
                label: Text('歷史'.i18n),
                icon: const Icon(Symbols.history_rounded),
              ),
            ],
            selected: {_isActive},
            onSelectionChanged: (s) =>
                _select(local: _isLocal && hasLocation, active: s.first),
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<History> events;
  const _Timeline({required this.events});

  @override
  Widget build(BuildContext context) {
    final grouped = groupBy(
      events,
      (History e) => e.time.send.toLocaleFullDateString(context),
    ).entries.sorted((a, b) => b.key.compareTo(a.key)).toList();

    return SliverList.list(
      children: [
        for (var i = 0; i < grouped.length; i++) ...[
          Padding(
            padding: const .fromLTRB(16, 16, 16, 8),
            child: Text(
              grouped[i].key,
              style: context.texts.titleMedium?.copyWith(
                fontWeight: .w700,
              ),
            ),
          ),
          for (final item in grouped[i].value)
            HistoryTimelineItem(
              history: item,
              expired: item.isExpired,
              last: item == grouped[i].value.last,
            ),
        ],
      ],
    );
  }
}
