/// Menu tab — quick links to settings sub-sections and info pages.
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:simple_icons/simple_icons.dart';

/// Menu tab page providing direct entry points into all settings sections
/// and external links.
class MenuPage extends StatelessWidget {
  /// Creates a [MenuPage].
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('選單'.i18n),
            pinned: true,
          ),
          SliverList.list(
            children: [
              // 設定
              SegmentedList(
                label: Text('設定'.i18n),
                children: [
                  SegmentedListTile(
                    isFirst: true,
                    leading: ContainedIcon(
                      Symbols.pin_drop_rounded,
                      color: Colors.deepOrangeAccent,
                    ),
                    title: Text('所在地'.i18n),
                    subtitle: Text('設定接收即時資訊的地區'.i18n),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    onTap: () => const SettingsLocationRoute().push(context),
                  ),
                  SegmentedListTile(
                    leading: ContainedIcon(
                      Symbols.notifications_rounded,
                      color: Colors.amberAccent,
                    ),
                    title: Text('通知'.i18n),
                    subtitle: Text('推播通知設定與測試'.i18n),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    onTap: () => const SettingsNotifyRoute().push(context),
                  ),
                  SegmentedListTile(
                    leading: ContainedIcon(
                      Symbols.palette_rounded,
                      color: Colors.indigoAccent,
                    ),
                    title: Text('主題'.i18n),
                    subtitle: Text('調整 DPIP 的外觀與顏色'.i18n),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    onTap: () => const SettingsThemeRoute().push(context),
                  ),
                  SegmentedListTile(
                    leading: ContainedIcon(
                      Symbols.translate_rounded,
                      color: Colors.tealAccent,
                    ),
                    title: Text('語言'.i18n),
                    subtitle: Text('調整顯示語言'.i18n),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    onTap: () => const SettingsLocaleRoute().push(context),
                  ),
                  SegmentedListTile(
                    leading: ContainedIcon(
                      Symbols.percent_rounded,
                      color: Colors.orangeAccent,
                    ),
                    title: Text('單位'.i18n),
                    subtitle: Text('調整顯示數值的單位'.i18n),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    onTap: () => const SettingsUnitRoute().push(context),
                  ),
                  SegmentedListTile(
                    isLast: true,
                    leading: ContainedIcon(
                      Symbols.tune_rounded,
                      color: Colors.blueGrey,
                    ),
                    title: Text('進階設定'.i18n),
                    subtitle: Text('版面、地圖、網路、實驗性功能'.i18n),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    onTap: () => const SettingsIndexRoute().push(context),
                  ),
                ],
              ),

              // 資訊
              SegmentedList(
                label: Text('資訊'.i18n),
                children: [
                  SegmentedListTile(
                    isFirst: true,
                    leading: ContainedIcon(
                      Symbols.update_rounded,
                      color: Colors.cyanAccent,
                    ),
                    title: Text('更新日誌'.i18n),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    onTap: () => const ChangelogRoute().push(context),
                  ),
                  SegmentedListTile(
                    isLast: true,
                    leading: ContainedIcon(
                      Symbols.book_rounded,
                      color: Colors.brown,
                    ),
                    title: Text('第三方套件授權'.i18n),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    onTap: () => const LicenseRoute().push(context),
                  ),
                ],
              ),

              // 贊助
              SegmentedList(
                children: [
                  SegmentedListTile(
                    isFirst: true,
                    isLast: true,
                    leading: ContainedIcon(
                      Symbols.volunteer_activism_rounded,
                      color: Colors.black,
                      backgroundGradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        begin: .topLeft,
                        end: .bottomRight,
                      ),
                    ),
                    title: Text('贊助我們'.i18n, style: .new(color: Colors.amber[600])),
                    subtitle: Text('幫助伺服器穩定與持續開發'.i18n),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    tileColor: Colors.amber.withValues(alpha: 0.16),
                    shape: RoundedRectangleBorder(
                      borderRadius: .circular(20),
                      side: BorderSide(color: Colors.amber.withValues(alpha: 0.6)),
                    ),
                    onTap: () => const SettingsDonateRoute().push(context),
                  ),
                ],
              ),

              // 社群連結
              SegmentedList(
                label: Text('ExpTech Studio'),
                children: [
                  SegmentedListTile(
                    isFirst: true,
                    leading: ContainedIcon(
                      SimpleIcons.github,
                      color: context.theme.brightness == .dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    title: const Text('GitHub'),
                    subtitle: const Text('ExpTechTW'),
                    trailing: const Icon(Symbols.arrow_outward_rounded),
                    onTap: () => 'https://github.com/ExpTechTW/DPIP-Pocket'.launch(),
                  ),
                  SegmentedListTile(
                    leading: const ContainedIcon(
                      SimpleIcons.discord,
                      color: Color(0xff5865F2),
                    ),
                    title: const Text('Discord'),
                    subtitle: const Text('.gg/exptech-studio'),
                    trailing: const Icon(Symbols.arrow_outward_rounded),
                    onTap: () => 'https://discord.gg/exptech-studio'.launch(),
                  ),
                  SegmentedListTile(
                    leading: ContainedIcon(
                      SimpleIcons.threads,
                      color: context.theme.brightness == .dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    title: const Text('Threads'),
                    subtitle: const Text('@dpip.tw'),
                    trailing: const Icon(Symbols.arrow_outward_rounded),
                    onTap: () => 'https://www.threads.net/@dpip.tw'.launch(),
                  ),
                  SegmentedListTile(
                    isLast: true,
                    leading: const ContainedIcon(
                      SimpleIcons.youtube,
                      color: Color(0xFFFF0000),
                    ),
                    title: const Text('YouTube'),
                    subtitle: const Text('@exptechtw'),
                    trailing: const Icon(Symbols.arrow_outward_rounded),
                    onTap: () => 'https://www.youtube.com/@exptechtw/live'.launch(),
                  ),
                ],
              ),
              SizedBox(height: context.padding.bottom + 96),
            ],
          ),
        ],
      ),
    );
  }
}
