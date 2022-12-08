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
import 'package:messenger/api/backend/schema.dart' show Presence;
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/widget/modal_popup.dart';

import 'controller.dart';

class StatusView extends StatelessWidget {
  const StatusView({Key? key}) : super(key: key);

  /// Displays an [StatusView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      child: const StatusView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: MoreController(Get.find()),
      builder: (MoreController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(
              header: Center(
                child: Text(
                  'Status'.l10n,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: ModalPopup.padding(context),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 8),
                  ...[Presence.present, Presence.away, Presence.hidden]
                      .map((e) {
                    return Obx(() {
                      final bool selected = c.presence.value == e;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          borderRadius: BorderRadius.circular(10),
                          color: selected
                              ? const Color(0xFFD7ECFF).withOpacity(0.8)
                              : Colors.white.darken(0.05),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => c.presence.value = e,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 8,
                                    backgroundColor: e == Presence.present
                                        ? Colors.green
                                        : e == Presence.away
                                            ? Colors.orange
                                            : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    e == Presence.present
                                        ? 'btn_online'.l10n
                                        : e == Presence.away
                                            ? 'btn_away'.l10n
                                            : 'btn_hidden'.l10n,
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                  const Spacer(),
                                  AnimatedSwitcher(
                                    duration: 200.milliseconds,
                                    child: selected
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  Color(0xFF63B4FF),
                                              radius: 12,
                                              child: Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                          )
                                        : const SizedBox(key: Key('0')),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
