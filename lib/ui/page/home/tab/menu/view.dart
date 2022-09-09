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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/avatar.dart';
import 'controller.dart';

/// View of the `HomeTab.menu` tab.
class MenuTabView extends StatelessWidget {
  const MenuTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> divider = [
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        color: const Color(0xFFE0E0E0),
        height: 0.5,
      ),
      const SizedBox(height: 10),
    ];

    return GetBuilder(
      key: const Key('MenuTab'),
      init: MenuTabController(Get.find(), Get.find(), Get.find()),
      builder: (MenuTabController c) {
        Widget button({
          Key? key,
          Widget? leading,
          required Widget title,
          void Function()? onTap,
        }) {
          Style style = Theme.of(context).extension<Style>()!;
          return Padding(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 55,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: style.cardRadius,
                  border: style.cardBorder,
                  color: Colors.transparent,
                ),
                child: Material(
                  type: MaterialType.card,
                  borderRadius: style.cardRadius,
                  color: style.cardColor,
                  child: InkWell(
                    borderRadius: style.cardRadius,
                    onTap: onTap,
                    hoverColor: const Color.fromARGB(255, 244, 249, 255),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                      child: Row(
                        children: [
                          if (leading != null) ...[
                            const SizedBox(width: 12),
                            leading,
                            const SizedBox(width: 18),
                          ],
                          Expanded(
                            child: DefaultTextStyle(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.headline5!,
                              child: title,
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

        return Scaffold(
          appBar: CustomAppBar.from(
            context: context,
            title: Text(
              'label_menu'.l10n,
              style: Theme.of(context).textTheme.caption?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w300,
                    fontSize: 18,
                  ),
            ),
          ),
          body: Obx(() {
            return ListView(
              controller: ScrollController(),
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ContactTile(
                    darken: 0,
                    myUser: c.myUser.value,
                    onTap: router.me,
                    subtitle: const [
                      SizedBox(height: 5),
                      Text(
                        'В сети',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                // Material(
                //   type: MaterialType.transparency,
                //   child: InkWell(
                //     onTap: router.me,
                //     child: Padding(
                //       padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                //       child: Row(
                //         children: [
                //           AvatarWidget.fromMyUser(c.myUser.value, radius: 25),
                //           const SizedBox(width: 12),
                //           Expanded(
                //             child: Text(
                //               c.myUser.value?.name?.val ??
                //                   'btn_your_profile'.l10n,
                //               overflow: TextOverflow.ellipsis,
                //               maxLines: 1,
                //               style: Theme.of(context).textTheme.headline5,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 18),
                button(
                  leading: const Icon(
                    Icons.design_services,
                    color: Color(0xFF63B4FF),
                  ),
                  title: Text('btn_personalize'.l10n),
                  onTap: router.personalization,
                ),
                const SizedBox(height: 8),
                button(
                  key: const Key('SettingsButton'),
                  leading: const Icon(
                    Icons.settings,
                    color: Color(0xFF63B4FF),
                  ),
                  title: Text('btn_settings'.l10n),
                  onTap: router.settings,
                ),
                const SizedBox(height: 8),
                button(
                  key: const Key('DownloadButton'),
                  leading: const Icon(
                    Icons.download,
                    color: Color(0xFF63B4FF),
                  ),
                  title: Text('Download application'.l10n),
                  onTap: router.download,
                ),
                const SizedBox(height: 8),
                button(
                  key: const Key('LogoutButton'),
                  leading: const Icon(
                    Icons.design_services,
                    color: Color(0xFF63B4FF),
                  ),
                  title: Text('btn_logout'.l10n),
                  onTap: () async {
                    if (await c.confirmLogout()) {
                      router.go(await c.logout());
                      router.tab = HomeTab.chats;
                    }
                  },
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
