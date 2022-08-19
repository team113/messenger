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
import 'package:messenger/ui/page/home/widget/app_bar.dart';

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
      builder: (MenuTabController c) => Scaffold(
        // backgroundColor: Colors.white,
        // backgroundColor: const Color(0xFFF5F8FA),
        appBar: CustomAppBar.from(
          context: context,
          // backgroundColor: const Color(0xFFF9FBFB),
          title: Text(
            'label_menu'.l10n,
            style: Theme.of(context).textTheme.caption?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                ),
          ),
          // bottom: PreferredSize(
          //   preferredSize: const Size.fromHeight(0.5),
          //   child: Container(
          //     color: const Color(0xFFE0E0E0),
          //     height: 0.5,
          //   ),
          // ),
        ),
        body: Obx(
          () => ListView(
            controller: ScrollController(),
            children: [
              const SizedBox(height: 10),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: router.me,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        AvatarWidget.fromMyUser(c.myUser.value, radius: 25),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.myUser.value?.name?.val ??
                                'btn_your_profile'.l10n,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.headline5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ListTile(
              //   key: const Key('MyProfileButton'),
              //   title: Text(c.myUser.value?.name?.val ?? 'btn_your_profile'.l10n),
              //   leading: AvatarWidget.fromMyUser(c.myUser.value),
              //   onTap: router.me,
              // ),
              ...divider,
              ListTile(
                key: const Key('PersonalizationButton'),
                title: Text('btn_personalize'.l10n),
                leading: const Icon(Icons.design_services),
                onTap: router.personalization,
              ),
              ListTile(
                key: const Key('SettingsButton'),
                title: Text('btn_settings'.l10n),
                leading: const Icon(Icons.settings),
                onTap: router.settings,
              ),
              ...divider,
              ListTile(
                key: const Key('LogoutButton'),
                title: Text('btn_logout'.l10n),
                leading: const Icon(Icons.logout),
                onTap: () async {
                  if (await c.confirmLogout()) {
                    router.go(await c.logout());
                    router.tab = HomeTab.chats;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
