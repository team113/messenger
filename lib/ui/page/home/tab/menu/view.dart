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
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/menu_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/api/backend/schema.dart' show Presence;

import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'accounts/view.dart';
import 'controller.dart';

/// View of the `HomeTab.menu` tab.
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
              actions: [
                ContextMenuButton(
                  label: 'label_presence_present'.l10n,
                  onPressed: () => c.setPresence(Presence.present),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(8),
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
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.myUser.value?.name?.val ??
                                  c.myUser.value?.num.toString() ??
                                  'dot'.l10n * 3,
                              style: style.fonts.big.regular.onBackground,
                            ),
                            Text(
                              // c.myUser.value?.status?.val ??
                              'label_online'.l10n,
                              style: style.fonts.small.regular.secondary,
                            ),
                            // Obx(() {
                            //   return Text(
                            //     // c.myUser.value?.status?.val ??
                            //     'label_online'.l10n,
                            //     style: style.fonts.small.regular.secondary,
                            //   );
                            // }),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            leading: context.isNarrow
                ? const [StyledBackButton()]
                : [const SizedBox(width: 20)],
            actions: [
              WidgetButton(
                behavior: HitTestBehavior.translucent,
                onPressed: () => AccountsView.show(context),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Obx(() {
                    if (router.accounts.value == 0) {
                      return AnimatedButton(
                        child: Transform.translate(
                          offset: const Offset(0, 1),
                          child: const SvgIcon(SvgIcons.addAccount),
                        ),
                      );
                    } else if (router.accounts.value == 1) {
                      return AnimatedButton(
                        child: AvatarWidget(
                          radius: AvatarRadius.small,
                          title: c.myUser.value!.name?.val ??
                              c.myUser.value!.num.toString(),
                          color: c.myUser.value!.num.val.sum() - 1,
                        ),
                      );
                    } else {
                      return AnimatedButton(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AvatarWidget(
                              radius: AvatarRadius.small,
                              title: c.myUser.value!.name?.val ??
                                  c.myUser.value!.num.toString(),
                              color: c.myUser.value!.num.val.sum() - 2,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: style.colors.onPrimary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(1),
                                child: AvatarWidget(
                                  radius: AvatarRadius.small,
                                  title: c.myUser.value!.name?.val ??
                                      c.myUser.value!.num.toString(),
                                  color: c.myUser.value!.num.val.sum() - 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
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
                final Widget child;
                final ProfileTab tab = ProfileTab.values[i];

                Widget card({
                  Key? key,
                  required String title,
                  required String subtitle,
                  IconData? icon,
                  Widget? child,
                  SvgData? primary,
                  SvgData? inverted,
                  Widget? leading,
                  String? asset,
                  double? assetWidth,
                  double? assetHeight,
                  void Function()? onPressed,
                }) {
                  return Obx(() {
                    final bool invert = tab == router.profileSection.value &&
                        router.route == Routes.me;

                    return MenuButton.tab(
                      tab,
                      inverted: invert,
                      onPressed: onPressed ??
                          () {
                            if (router.profileSection.value == tab) {
                              router.profileSection.refresh();
                            } else {
                              router.profileSection.value = tab;
                            }
                            router.me();
                          },
                    );
                  });
                }

                switch (ProfileTab.values[i]) {
                  case ProfileTab.public:
                    child = card(
                      key: const Key('PublicInformation'),
                      icon: Icons.person,
                      primary: SvgIcons.publicInformation,
                      inverted: SvgIcons.publicInformationWhite,
                      title: 'label_profile'.l10n,
                      subtitle: 'label_public_section_hint'.l10n,
                    );
                    break;

                  case ProfileTab.signing:
                    child = card(
                      key: const Key('Signing'),
                      icon: Icons.lock,
                      title: 'label_login_options'.l10n,
                      subtitle: 'label_login_section_hint'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[0],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.link:
                    child = card(
                      icon: Icons.link,
                      title: 'label_link_to_chat'.l10n,
                      subtitle: 'label_your_direct_link'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[1],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.background:
                    child = card(
                      icon: Icons.image,
                      title: 'label_background'.l10n,
                      subtitle: 'label_app_background'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[2],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.chats:
                    child = card(
                      icon: Icons.chat_bubble,
                      title: 'label_chats'.l10n,
                      subtitle: 'label_timeline_style'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[3],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.calls:
                    if (!PlatformUtils.isWeb || !PlatformUtils.isDesktop) {
                      return const SizedBox();
                    } else {
                      child = card(
                        icon: Icons.call,
                        title: 'label_calls'.l10n,
                        subtitle: 'label_calls_displaying'.l10n,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.primaries[4],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                    break;

                  case ProfileTab.media:
                    if (PlatformUtils.isMobile) {
                      return const SizedBox();
                    } else {
                      child = card(
                        icon: Icons.video_call,
                        title: 'label_media'.l10n,
                        subtitle: 'label_media_section_hint'.l10n,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.primaries[5],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                    break;

                  case ProfileTab.welcome:
                    child = card(
                      icon: Icons.message,
                      title: 'label_welcome_message'.l10n,
                      subtitle: 'label_public_description'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[6],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.getPaid:
                    child = card(
                      icon: Icons.paid,
                      title: 'label_get_paid_for_incoming'.l10n,
                      subtitle: 'label_message_and_call_cost'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[7],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.donates:
                    child = card(
                      icon: Icons.donut_small,
                      title: 'label_donates'.l10n,
                      subtitle: 'label_donates_preferences'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[8],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.notifications:
                    child = card(
                      icon: Icons.notifications,
                      title: 'label_notifications'.l10n,
                      subtitle: 'label_sound_and_vibrations'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[9],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.storage:
                    child = card(
                      icon: Icons.storage,
                      title: 'label_storage'.l10n,
                      subtitle: 'label_cache_and_downloads'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[10],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.language:
                    child = card(
                      key: const Key('Language'),
                      icon: Icons.language,
                      title: 'label_language'.l10n,
                      subtitle: L10n.chosen.value?.name ??
                          'label_current_language'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[11],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.blocklist:
                    child = card(
                      key: const Key('Blocked'),
                      icon: Icons.block,
                      title: 'label_blocked_users'.l10n,
                      subtitle: 'label_your_blacklist'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[12],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.devices:
                    child = card(
                      icon: Icons.devices,
                      title: 'label_linked_devices'.l10n,
                      subtitle: 'label_scan_qr_code'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[13],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.download:
                    if (PlatformUtils.isWeb) {
                      child = card(
                        icon: Icons.download,
                        title: 'label_download'.l10n,
                        subtitle: 'label_application'.l10n,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.primaries[13],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                    break;

                  case ProfileTab.danger:
                    child = card(
                      key: const Key('DangerZone'),
                      icon: Icons.dangerous,
                      title: 'label_danger_zone'.l10n,
                      subtitle: 'label_delete_account'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[15],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.vacancies:
                    child = card(
                      key: const Key('VacanciesButton'),
                      icon: Icons.work,
                      title: 'label_work_with_us'.l10n,
                      subtitle: 'label_vacancies_and_partnership'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[16],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // onPressed: () => router.vacancy(null),
                    );
                    break;

                  case ProfileTab.styles:
                    child = card(
                      key: const Key('StylesButton'),
                      icon: Icons.style,
                      title: 'Styles'.l10n,
                      subtitle: 'Colors, typography, elements'.l10n,
                      onPressed: () => router.go(Routes.style),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[17],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    break;

                  case ProfileTab.logout:
                    child = card(
                      key: const Key('LogoutButton'),
                      icon: Icons.logout,
                      title: 'btn_logout'.l10n,
                      subtitle: 'label_end_session'.l10n,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.primaries[0],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (await c.confirmLogout()) {
                          router.go(await c.logout());
                          router.tab = HomeTab.chats;
                        }
                      },
                    );
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: child,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
