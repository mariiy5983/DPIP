/// Weather detail tab — observation values, forecast, sun/moon cycle.
library;

import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/app/new_home/_widgets/all_observation_average.dart';
import 'package:dpip/app/new_home/_widgets/assistant_hint.dart';
import 'package:dpip/app/new_home/_widgets/day_cycle.dart';
import 'package:dpip/app/new_home/_widgets/forecast_strip.dart';
import 'package:dpip/app/new_home/_widgets/weather_parameters.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Detailed weather tab page.
///
/// Provides a [HomeModel] so the weather widgets work the same way they do on
/// the main home tab, even when the user lands here directly.
class WeatherDetailPage extends StatefulWidget {
  /// Creates a [WeatherDetailPage].
  const WeatherDetailPage({super.key});

  @override
  State<WeatherDetailPage> createState() => _WeatherDetailPageState();
}

class _WeatherDetailPageState extends State<WeatherDetailPage> {
  HomeModel? _homeModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeModel ??= HomeModel(context.read<SettingsLocationModel>())..startAutoRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _homeModel!,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text('天氣'.i18n),
              pinned: true,
            ),
            const SliverToBoxAdapter(
              child: Column(
                children: [
                  AssistantHint(),
                  ForecastStrip(),
                  AllObservationAverage(),
                  WeatherParameters(),
                  DayCycle(),
                ],
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _homeModel?.dispose();
    super.dispose();
  }
}
