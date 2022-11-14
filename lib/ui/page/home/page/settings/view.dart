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

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

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
              ListTile(
                title: Row(
                  children: [
                    Text('SendNotification'.l10n),
                    const SizedBox(width: 10),
                    Obx(() {
                      return Switch(
                        value: c.settings.value?.enablePopups ?? true,
                        onChanged: (_) async {
                          await Future.delayed(1.seconds);
                          String? token = await FirebaseMessaging.instance.getToken(
                              vapidKey: PlatformUtils.isWeb
                                  ? 'BGYb_L78Y9C-X8Egon75EL8aci2K2UqRb850ibVpC51TXjmnapW9FoQqZ6Ru9rz5IcBAMwBIgjhBi-wn7jAMZC0'
                                  : null);
                          await http
                              .post(
                                Uri.parse(
                                    'https://fcm.googleapis.com/fcm/send'),
                                headers: <String, String>{
                                  'Content-Type': 'application/json',
                                  'Authorization':
                                      'key=AAAA5Y3eNzc:APA91bFYrrb1rdKqLFBKv6KRLc7YeYQHYVFJK-0058cun3azgZcQTG9GeJZQc04pd18gXzahodkgBk2n3FxXusR7GdGo23aDUr1JNExPLO4WoI1e4ATk0BaL333AED8gEGEJcHb7IX3E'
                                },
                                body: json.encode({
                                  'to': token,
                                  'data': {
                                    'title': 'Push Notification',
                                    'body': 'Firebase  push notification'
                                  }
                                }),
                              )
                              .then((value) => print(value.body));
                        },
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
