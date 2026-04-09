// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/api/backend/schema.dart' show UserPresence;
import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/tab/chats/widget/unread_counter.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/login/terms_of_use/view.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/menu_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'accounts/view.dart';
import 'confirm/view.dart';
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
                  onPressed: () => c.setPresence(UserPresence.present),
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
                  onPressed: () => c.setPresence(UserPresence.away),
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
                  Center(
                    child: Obx(() {
                      return AvatarWidget.fromMyUser(
                        c.myUser.value,
                        key: c.profileKey,
                        radius: AvatarRadius.medium,
                      );
                    }),
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
                key: const Key('AccountsButton'),
                behavior: HitTestBehavior.translucent,
                onPressed: () => AccountsView.show(context),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Obx(() {
                    final bool hasMultipleAccounts = c.profiles.length > 1;
                    if (hasMultipleAccounts) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 0.5,
                            color: style.colors.secondary,
                          ),
                        ),
                        width: 30,
                        height: 30,
                        child: Center(child: SvgIcon(SvgIcons.changeAccount)),
                      );
                    }

                    return Text(
                      'btn_add_account_with_desc'.l10n,
                      style: style.fonts.small.regular.primary,
                      textAlign: TextAlign.center,
                    );
                  }),
                ),
              ),
            ],
          ),
          body: Scrollbar(
            controller: c.scrollController,
            child: ListView(
              controller: c.scrollController,
              padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
              key: const Key('MenuListView'),
              children: [
                const SizedBox(height: 8),
                LineDivider('label_account_settings'.l10n),
                const SizedBox(height: 8),
                _tab(ProfileTab.public, c),
                _tab(ProfileTab.signing, c),
                _tab(ProfileTab.link, c),
                _tab(ProfileTab.welcome, c),
                _tab(ProfileTab.notifications, c),
                _tab(ProfileTab.confidential, c),
                _tab(ProfileTab.devices, c),

                const SizedBox(height: 8),
                LineDivider('label_device_settings'.l10n),
                const SizedBox(height: 8),
                _tab(ProfileTab.interface, c),
                _tab(ProfileTab.media, c),
                _tab(ProfileTab.storage, c),
                _tab(ProfileTab.download, c),

                const SizedBox(height: 8),
                LineDivider('btn_help'.l10n),
                const SizedBox(height: 8),
                _tab(ProfileTab.support, c),
                _tab(ProfileTab.legal, c),

                const SizedBox(height: 8),
                LineDivider('label_actions'.l10n),
                const SizedBox(height: 8),
                _tab(ProfileTab.logout, c),
                _tab(ProfileTab.danger, c),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the provided [ProfileTab].
  Widget _tab(ProfileTab tab, MenuTabController c) {
    switch (tab) {
      case ProfileTab.media:
        if (PlatformUtils.isMobile) {
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
      final bool inverted =
          tab == router.profileSection.value && router.route == Routes.me;

      Widget? trailing;

      switch (tab) {
        case ProfileTab.signing:
          final bool hasPassword = c.myUser.value?.hasPassword == true;
          final bool hasEmail =
              c.myUser.value?.emails.confirmed.isNotEmpty == true;

          if (!hasPassword || !hasEmail) {
            trailing = UnreadCounter.text('!');
          }
          break;

        default:
          // No-op.
          break;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: MenuButton.tab(
          tab,
          key: key,
          inverted: switch (tab) {
            ProfileTab.danger => router.route == Routes.erase,
            ProfileTab.support =>
              router.route ==
                  '${Routes.chats}/${ChatId.local(UserId(Config.supportId))}',
            (_) => inverted,
          },
          trailing: trailing,
          onPressed: switch (tab) {
            ProfileTab.legal => () async {
              await TermsOfUseView.show(router.context!);
            },
            ProfileTab.danger => () => router.erase(push: true),
            ProfileTab.support => router.support,
            ProfileTab.logout => () async {
              // Don't show a confirmation when e-mail is set.
              if (c.myUser.value?.emails.confirmed.isNotEmpty == true) {
                return c.logout();
              }

              await ConfirmLogoutView.show(router.context!);
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
  }
}
