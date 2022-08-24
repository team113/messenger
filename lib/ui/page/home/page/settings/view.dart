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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/widget/selector.dart';
import '/util/platform_utils.dart';
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
          appBar: AppBar(title: Text('label_settings'.l10n)),
          body: Column(
            children: [
              SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['Recent', 'Contact', 'User'].mapIndexed((i, e) {
                    return Obx(() {
                      return WidgetButton(
                        onPressed: () {
                          if (i == 0) {
                            c.scrollTo(c.recent);
                          } else if (i == 1) {
                            c.scrollTo(c.contacts);
                          } else if (i == 2) {
                            c.scrollTo(c.users);
                          }
                        },
                        child: Container(
                          color: c.selected.value == i
                              ? Colors.blue
                              : Colors.white,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(e),
                        ),
                      );
                    });
                  }).toList(),
                ),
              ),
              Expanded(
                child: FlutterListView(
                  controller: c.controller,
                  delegate: FlutterListViewDelegate(
                    (context, i) {
                      if (i >= c.contacts.length + c.recent.length) {
                        User user =
                            c.users[i - c.contacts.length - c.recent.length];
                        return ListTile(title: Text('User ${user.name}'));
                      } else if (i >= c.recent.length) {
                        Contact contact = c.contacts[i - c.recent.length];
                        return ListTile(title: Text('Contact ${contact.name}'));
                      } else {
                        Recent recent = c.recent[i];
                        return ListTile(title: Text('Recent ${recent.name}'));
                      }
                    },
                    childCount:
                        c.recent.length + c.contacts.length + c.users.length,
                  ),
                ),
              ),
            ],
          ),
        );

        return Scaffold(
          appBar: AppBar(title: Text('label_settings'.l10n)),
          body: ListView(
            children: [
              ListTile(
                title: Text('btn_media_settings'.l10n),
                onTap: router.settingsMedia,
              ),
              ListTile(
                title: Row(
                  children: [
                    Text('label_enable_popup_calls'.l10n),
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
              KeyedSubtree(
                key: c.languageKey,
                child: ListTile(
                  key: const Key('LanguageDropdown'),
                  title: Text(
                    '${L10n.chosen.value!.locale.countryCode}, ${L10n.chosen.value!.name}',
                  ),
                  onTap: () async {
                    final TextStyle? thin = context.textTheme.caption
                        ?.copyWith(color: Colors.black);
                    await Selector.show<Language>(
                      context: context,
                      buttonKey: c.languageKey,
                      alignment: Alignment.bottomCenter,
                      items: L10n.languages,
                      initial: L10n.chosen.value!,
                      onSelected: (l) => L10n.set(l),
                      debounce: context.isMobile
                          ? const Duration(milliseconds: 500)
                          : null,
                      itemBuilder: (Language e) => Row(
                        key: Key(
                            'Language_${e.locale.languageCode}${e.locale.countryCode}'),
                        children: [
                          Text(
                            e.name,
                            style: thin?.copyWith(fontSize: 15),
                          ),
                          const Spacer(),
                          Text(
                            e.locale.languageCode.toUpperCase(),
                            style: thin?.copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
