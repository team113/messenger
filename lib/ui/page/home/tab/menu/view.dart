// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_button.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'accounts/view.dart';
import 'controller.dart';

/// View of the [HomeTab.menu] tab.
class MenuTabView extends StatelessWidget {
  const MenuTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('MenuTab'),
      init: MenuTabController(Get.find(), Get.find()),
      builder: (MenuTabController c) {
        final style = Theme.of(context).style;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: ContextMenuRegion(
              selector: c.profileKey,
              alignment: Alignment.topLeft,
              margin: const EdgeInsets.only(top: 7, right: 32),
              enablePrimaryTap: true,
              enableLongTap: false,
              actions: [
                ContextMenuButton(
                  label: 'label_presence_present'.l10n,
                  onPressed: () => c.setPresence(Presence.present),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: style.colors.acceptAuxiliary,
                    ),
                  ),
                ),
                ContextMenuButton(
                  label: 'label_presence_away'.l10n,
                  onPressed: () => c.setPresence(Presence.away),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: style.colors.warning,
                    ),
                  ),
                ),
              ],
              child: Row(
                children: [
                  Material(
                    elevation: 6,
                    type: MaterialType.circle,
                    shadowColor: style.colors.onBackgroundOpacity27,
                    color: style.colors.onPrimary,
                    child: Center(
                      child: Obx(() {
                        return AvatarWidget.fromMyUser(
                          c.myUser.value,
                          key: c.profileKey,
                          radius: AvatarRadius.medium,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: DefaultTextStyle.merge(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: Obx(() {
                        return Text(
                          c.myUser.value?.name?.val ??
                              c.myUser.value?.num.toString() ??
                              'dot'.l10n * 3,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            leading: const [SizedBox(width: 20)],
            actions: [
              WidgetButton(
                behavior: HitTestBehavior.translucent,
                onPressed: () => AccountsView.show(context),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Obx(() {
                    final bool hasMultipleAccounts = c.profiles.length > 1;
                    final String label = hasMultipleAccounts
                        ? 'btn_change_account_desc'
                        : 'btn_add_account_with_desc';

                    return Text(
                      label.l10n,
                      style: style.fonts.small.regular.primary,
                      textAlign: TextAlign.center,
                    );
                  }),
                ),
              ),
            ],
          ),
          body: SafeScrollbar(
            controller: c.scrollController,
            child: ListView.builder(
              controller: c.scrollController,
              key: const Key('MenuListView'),
              itemCount: ProfileTab.values.length,
              itemBuilder: (context, i) {
                final ProfileTab tab = ProfileTab.values[i];

                switch (tab) {
                  case ProfileTab.calls:
                    if (!PlatformUtils.isDesktop || !PlatformUtils.isWeb) {
                      return const SizedBox();
                    }
                    break;

                  case ProfileTab.media:
                    if (PlatformUtils.isMobile) {
                      return const SizedBox();
                    }
                    break;

                  case ProfileTab.download:
                    if (!PlatformUtils.isWeb) {
                      return const SizedBox();
                    }
                    break;

                  case ProfileTab.storage:
                    if (PlatformUtils.isWeb) {
                      return const SizedBox();
                    }
                    break;

                  default:
                    // No-op.
                    break;
                }

                return Obx(() {
                  final bool inverted = tab == router.profileSection.value &&
                      router.route == Routes.me;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: MenuButton.tab(
                      tab,
                      key: key,
                      inverted: switch (tab) {
                        ProfileTab.support => router.route == Routes.support,
                        (_) => inverted,
                      },
                      onPressed: switch (tab) {
                        ProfileTab.support => router.support,
                        ProfileTab.logout => () async {
                            if (await c.confirmLogout()) {
                              c.logout();
                              router.auth();
                              router.tab = HomeTab.chats;
                            }
                          },
                        (_) => () {
                            if (router.profileSection.value == tab) {
                              router.profileSection.refresh();
                            } else {
                              router.profileSection.value = tab;
                            }
                            router.me();
                          },
                      },
                    ),
                  );
                });
              },
            ),
          ),
        );
      },
    );
  }
}
