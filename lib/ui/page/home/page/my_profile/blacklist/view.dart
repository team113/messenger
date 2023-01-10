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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// View displaying the blacklisted [User]s.
///
/// Intended to be displayed with the [show] method.
class BlacklistView extends StatelessWidget {
  const BlacklistView({super.key});

  /// Displays a [BlacklistView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const BlacklistView());
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: BlacklistController(Get.find(), Get.find()),
      builder: (BlacklistController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            ModalPopupHeader(
              header: Center(
                child: Text(
                  'label_blocked_users'.l10n,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Obx(() {
              if (c.blacklist.isEmpty ||
                  c.blacklist.none((e) => e.user.value.isBlacklisted)) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('label_no_users'.l10n),
                );
              }

              return Flexible(
                child: Scrollbar(
                  controller: c.scrollController,
                  child: ListView.builder(
                    controller: c.scrollController,
                    shrinkWrap: true,
                    padding: ModalPopup.padding(context),
                    itemBuilder: (context, i) {
                      RxUser? user = c.blacklist[i];

                      return Obx(() {
                        if (user.user.value.isBlacklisted == false) {
                          return const SizedBox();
                        }

                        return ContactTile(
                          user: user,
                          onTap: () {
                            Navigator.of(context).pop();
                            router.user(user.id, push: true);
                          },
                          darken: 0.03,
                          trailing: [
                            InkWell(
                              onTap: () => c.unblacklist(user),
                              borderRadius: BorderRadius.circular(25),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgLoader.asset(
                                  'assets/icons/delete.svg',
                                  height: 14 * 1.5,
                                ),
                              ),
                            ),
                          ],
                        );
                      });
                    },
                    itemCount: c.blacklist.length,
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
