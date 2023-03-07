// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/modal_popup.dart';

import 'controller.dart';

class MoreView extends StatelessWidget {
  const MoreView({Key? key}) : super(key: key);

  /// Displays an [IntroductionView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const MoreView());
  }

  @override
  Widget build(BuildContext context) {
    Widget button({
      Key? key,
      Widget? leading,
      required Widget title,
      void Function()? onTap,
    }) {
      final Style style = Theme.of(context).extension<Style>()!;
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
                          style: Theme.of(context).textTheme.headlineSmall!,
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

    return GetBuilder(
        init: MoreController(Get.find(), Get.find(), Get.find()),
        builder: (MoreController c) {
          return ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 8),
              button(
                leading: const Icon(
                  Icons.design_services,
                  color: Color(0xFF63B4FF),
                ),
                title: Text('btn_personalize'.l10n),
                // onTap: router.personalization,
              ),
              const SizedBox(height: 8),
              button(
                key: const Key('SettingsButton'),
                leading: const Icon(
                  Icons.settings,
                  color: Color(0xFF63B4FF),
                ),
                title: Text('btn_settings'.l10n),
                // onTap: router.settings,
              ),
              const SizedBox(height: 8),
              button(
                key: const Key('DownloadButton'),
                leading: const Icon(
                  Icons.download,
                  color: Color(0xFF63B4FF),
                ),
                title: Text('Download application'.l10n),
                // onTap: router.download,
              ),
              const SizedBox(height: 8),
              button(
                key: const Key('LogoutButton'),
                leading: const Icon(
                  Icons.logout,
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
              const SizedBox(height: 8),
            ],
          );
        });
  }
}
