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
import 'package:intl/intl.dart';

import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/widget_button.dart';
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
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black);

    return GetBuilder(
      init: BlacklistController(
        Get.find(),
        Get.find(),
        pop: Navigator.of(context).pop,
      ),
      builder: (BlacklistController c) {
        return Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(
                header: Center(
                  child: Text(
                    'label_users_count'.l10nfmt({'count': c.blacklist.length}),
                    style: thin?.copyWith(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (c.blacklist.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('label_no_users'.l10n),
                )
              else
                Flexible(
                  child: Scrollbar(
                    controller: c.scrollController,
                    child: ListView.builder(
                      controller: c.scrollController,
                      shrinkWrap: true,
                      padding: ModalPopup.padding(context),
                      itemBuilder: (context, i) {
                        RxUser? user = c.blacklist[i];

                        return ContactTile(
                          user: user,
                          onTap: () {
                            Navigator.of(context).pop();
                            router.user(user.id, push: true);
                          },
                          darken: 0.03,
                          subtitle: [
                            const SizedBox(height: 5),
                            Text(
                              'label_date_ymd'.l10nfmt({
                                'year': user
                                    .user.value.isBlacklisted!.at.val.year
                                    .toString()
                                    .padLeft(4, '0'),
                                'month': user
                                    .user.value.isBlacklisted!.at.val.month
                                    .toString()
                                    .padLeft(2, '0'),
                                'day': user.user.value.isBlacklisted!.at.val.day
                                    .toString()
                                    .padLeft(2, '0'),
                              }),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          trailing: [
                            WidgetButton(
                              onPressed: () => c.unblacklist(user),
                              child: Text(
                                'btn_unblock_short'.l10n,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        );
                      },
                      itemCount: c.blacklist.length,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          );
        });
      },
    );
  }
}
