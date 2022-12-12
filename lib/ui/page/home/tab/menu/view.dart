// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/my_profile/controller.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/selector.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the `HomeTab.menu` tab.
class MenuTabView extends StatelessWidget {
  const MenuTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('MenuTab'),
      init: MenuTabController(Get.find(), Get.find()),
      builder: (MenuTabController c) {
        final Style style = Theme.of(context).extension<Style>()!;

        Widget bigButton({
          Key? key,
          Widget? leading,
          required Widget title,
          required Widget subtitle,
          void Function()? onTap,
          bool selected = false,
        }) {
          return Padding(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 73,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: style.cardRadius,
                  border: style.cardBorder,
                  color: Colors.transparent,
                ),
                child: Material(
                  type: MaterialType.card,
                  borderRadius: style.cardRadius,
                  color: selected ? style.cardSelectedColor : style.cardColor,
                  child: InkWell(
                    borderRadius: style.cardRadius,
                    onTap: onTap,
                    hoverColor: const Color.fromARGB(255, 244, 249, 255),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        children: [
                          if (leading != null) ...[
                            const SizedBox(width: 12),
                            leading,
                            const SizedBox(width: 18),
                          ],
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DefaultTextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.headline5!,
                                  child: title,
                                ),
                                const SizedBox(height: 6),
                                DefaultTextStyle.merge(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  child: subtitle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        void Function()? onBack =
            context.isNarrow && ModalRoute.of(context)?.canPop == true
                ? Navigator.of(context).pop
                : null;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: Row(
              children: [
                Material(
                  elevation: 6,
                  type: MaterialType.circle,
                  shadowColor: const Color(0x55000000),
                  color: Colors.white,
                  child: InkWell(
                    onTap: onBack,
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: Obx(() {
                        return Stack(
                          children: [
                            AvatarWidget.fromMyUser(
                              onAvatarTap: c.uploadAvatar,
                              c.myUser.value,
                              radius: 17,
                              showBadge: false,
                            ),
                            Positioned.fill(
                              child: Obx(() {
                                final Widget child;

                                if (c.avatarUpload.value.isLoading) {
                                  child = Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                    child: const Center(
                                      child: SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  );
                                } else {
                                  child = const SizedBox();
                                }

                                return AnimatedSwitcher(
                                  duration: 200.milliseconds,
                                  child: child,
                                );
                              }),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: WidgetButton(
                    onPressed: () async {
                      await Selector.menu(
                        context,
                        actions: [
                          ContextMenuButton(
                            label: 'label_presence_present'.l10n,
                            onPressed: () => c.setPresence(Presence.present),
                            leading: const CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.green,
                            ),
                          ),
                          ContextMenuButton(
                            label: 'label_presence_away'.l10n,
                            onPressed: () => c.setPresence(Presence.away),
                            leading: const CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.orange,
                            ),
                          ),
                          ContextMenuButton(
                            label: 'label_presence_hidden'.l10n,
                            onPressed: () => c.setPresence(Presence.hidden),
                            leading: const CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    },
                    child: DefaultTextStyle.merge(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.myUser.value?.name?.val ??
                                c.myUser.value?.num.val ??
                                '...',
                            style: const TextStyle(color: Colors.black),
                          ),
                          Row(
                            key: c.profileKey,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Obx(() {
                                return Text(
                                  c.myUser.value?.presence.localizedString() ??
                                      'dot'.l10n * 3,
                                  style: Theme.of(context).textTheme.caption,
                                );
                              }),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.expand_more,
                                size: 18,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            leading: context.isNarrow
                ? const [StyledBackButton()]
                : [const SizedBox(width: 23)],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              itemCount: ProfileTab.values.length,
              itemBuilder: (context, i) {
                final Widget child;
                final ProfileTab tab = ProfileTab.values[i];

                Widget widget({
                  required String title,
                  required String subtitle,
                  required IconData icon,
                  VoidCallback? onTap,
                }) {
                  return Obx(() {
                    return bigButton(
                      leading: Icon(icon, color: const Color(0xFF63B4FF)),
                      title: Text(title),
                      subtitle: Text(subtitle),
                      onTap: onTap ??
                          () {
                            if (router.profileTab.value == tab) {
                              router.profileTab.refresh();
                            } else {
                              router.profileTab.value = tab;
                            }
                            router.profile();
                          },
                      selected: tab == router.profileTab.value &&
                          router.route == Routes.profile,
                    );
                  });
                }

                switch (ProfileTab.values[i]) {
                  case ProfileTab.public:
                    child = widget(
                      icon: Icons.person,
                      title: 'label_public_information'.l10n,
                      subtitle: 'label_public_section_hint'.l10n,
                    );
                    break;

                  case ProfileTab.signing:
                    child = widget(
                      icon: Icons.lock,
                      title: 'label_login_options'.l10n,
                      subtitle: 'label_login_section_hint'.l10n,
                    );
                    break;

                  case ProfileTab.link:
                    child = widget(
                      icon: Icons.link,
                      title: 'label_link_to_chat'.l10n,
                      subtitle: 'label_your_direct_link'.l10n,
                    );
                    break;

                  case ProfileTab.background:
                    child = widget(
                      icon: Icons.image,
                      title: 'label_background'.l10n,
                      subtitle: 'label_app_background'.l10n,
                    );
                    break;

                  case ProfileTab.calls:
                    if (PlatformUtils.isMobile) {
                      return const SizedBox();
                    } else {
                      child = widget(
                        icon: Icons.call,
                        title: 'label_calls'.l10n,
                        subtitle: 'label_calls_displaying'.l10n,
                      );
                    }
                    break;

                  case ProfileTab.media:
                    if (PlatformUtils.isMobile) {
                      return const SizedBox();
                    } else {
                      child = widget(
                        icon: Icons.video_call,
                        title: 'label_media'.l10n,
                        subtitle: 'label_media_section_hint'.l10n,
                      );
                    }
                    break;

                  case ProfileTab.language:
                    child = widget(
                      icon: Icons.language,
                      title: 'label_language'.l10n,
                      subtitle: L10n.chosen.value?.name ??
                          'label_current_language'.l10n,
                    );
                    break;

                  case ProfileTab.download:
                    child = widget(
                      icon: Icons.download,
                      title: 'label_download'.l10n,
                      subtitle: 'label_application'.l10n,
                    );
                    break;

                  case ProfileTab.danger:
                    child = widget(
                      icon: Icons.dangerous,
                      title: 'label_danger_zone'.l10n,
                      subtitle: 'label_delete_account'.l10n,
                    );
                    break;

                  case ProfileTab.logout:
                    child = widget(
                        icon: Icons.logout,
                        title: 'btn_logout'.l10n,
                        subtitle: 'label_end_session'.l10n,
                        onTap: () async {
                          if (await c.confirmLogout()) {
                            router.go(await c.logout());
                            router.tab = HomeTab.chats;
                          }
                        });
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
