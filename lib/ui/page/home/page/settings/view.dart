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
import 'package:messenger/fluent/fluent_localization.dart';

import '/fluent/extension.dart';
import '/routes.dart';
import 'controller.dart';

/// View of the [Routes.settings] page.
class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: SettingsController(Get.find()),
      builder: (SettingsController c) {
        return Scaffold(
          appBar: AppBar(title: Text('label_settings'.td())),
          body: ListView(
            children: [
              ListTile(
                title: Text('btn_media_settings'.td()),
                onTap: router.settingsMedia,
              ),
              ListTile(
                title: Row(
                  children: [
                    Text('label_enable_popup_calls'.td()),
                    const SizedBox(width: 10),
                    Obx(() {
                      return Switch(
                        value: c.settings.value?.enablePopups ?? true,
                        onChanged: c.setPopupsEnabled,
                      );
                    }),
                  ],
                ),
              ),
              ListTile(
                title: language,
              )
            ],
          ),
        );
      },
    );
  }
}

Widget language = StatefulBuilder(
    builder: (context, setState) => Obx(
          () => DropdownButton<String>(
            value: LocalizationUtils.chosen.value,
            items: LocalizationUtils.languages.entries
                .map<DropdownMenuItem<String>>(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                        '${LocalizationUtils.locales[e.key]!.countryCode}, ${e.value}'),
                  ),
                )
                .toList(),
            onChanged: (d) async {
              await LocalizationUtils.setUserLocale(
                  LocalizationUtils.locales[d!]!.toString());
            },
            borderRadius: BorderRadius.circular(18),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 15,
            ),
            icon: const SizedBox(),
            underline: const SizedBox(),
          ),
        ));
