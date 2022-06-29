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

import '/fluent/extension.dart';
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
        appBar: AppBar(
          title: Text('label_menu'.td()),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(
              color: const Color(0xFFE0E0E0),
              height: 0.5,
            ),
          ),
        ),
        body: Obx(
          () => ListView(
            children: [
              const SizedBox(height: 10),
              ListTile(
                key: const Key('MyProfileButton'),
                title:
                    Text(c.myUser.value?.name?.val ?? 'btn_your_profile'.td()),
                leading: AvatarWidget.fromMyUser(c.myUser.value),
                onTap: router.me,
              ),
              ...divider,
              ListTile(
                key: const Key('SettingsButton'),
                title: Text('btn_settings'.td()),
                leading: const Icon(Icons.settings),
                onTap: router.settings,
              ),
              ...divider,
              ListTile(
                key: const Key('LogoutButton'),
                title: Text('btn_logout'.td()),
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
