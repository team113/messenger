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

import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View displaying the blacklisted [User]s.
///
/// Intended to be displayed with the [show] method.
class PaidListView extends StatelessWidget {
  const PaidListView({super.key});

  /// Displays a [PaidListView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const PaidListView());
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black);

    return GetBuilder(
      init: PaidListController(
        Get.find(),
        Get.find(),
        pop: Navigator.of(context).pop,
      ),
      builder: (PaidListController c) {
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

                        final textStyle = Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 13,
                            );

                        return ContactTile(
                          user: user,
                          onTap: () {
                            Navigator.of(context).pop();
                            router.user(user.id, push: true);
                          },
                          darken: 0.03,
                          subtitle: [
                            // const SizedBox(height: 5),
                            if (true) ...[
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '¤',
                                      style: textStyle?.copyWith(
                                        fontFamily: 'Gapopa',
                                        fontWeight: FontWeight.w300,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const WidgetSpan(child: SizedBox(width: 1)),
                                    const TextSpan(text: '50 per message'),
                                  ],
                                  style: textStyle?.copyWith(fontSize: 13),
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '¤',
                                      style: textStyle?.copyWith(
                                        fontFamily: 'Gapopa',
                                        fontWeight: FontWeight.w300,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const WidgetSpan(child: SizedBox(width: 1)),
                                    const TextSpan(text: '120 per call minute'),
                                  ],
                                  style: textStyle?.copyWith(fontSize: 13),
                                ),
                              )
                            ],
                            // RichText(
                            //   text: TextSpan(
                            //     children: [
                            //       TextSpan(
                            //         text: '¤',
                            //         style: textStyle?.copyWith(
                            //           height: 0.8,
                            //           fontFamily: 'Gapopa',
                            //           fontWeight: FontWeight.w300,
                            //           fontSize: 13,
                            //         ),
                            //       ),
                            //       const TextSpan(text: '50 per message and '),
                            //       TextSpan(
                            //         text: '¤',
                            //         style: textStyle?.copyWith(
                            //           height: 0.8,
                            //           fontFamily: 'Gapopa',
                            //           fontWeight: FontWeight.w300,
                            //           fontSize: 13,
                            //         ),
                            //       ),
                            //       const TextSpan(text: '120 per call minute'),
                            //     ],
                            //     style: textStyle?.copyWith(fontSize: 13),
                            //   ),
                            // ),
                            // Text(
                            //   '28.12.2022',
                            //   style: TextStyle(
                            //     color: Theme.of(context).colorScheme.secondary,
                            //     fontSize: 13,
                            //   ),
                            // ),
                          ],
                          trailing: const [
                            // WidgetButton(
                            //   onPressed: () => c.unblacklist(user),
                            //   child: Text(
                            //     'btn_unblock_short'.l10n,
                            //     style: TextStyle(
                            //       color:
                            //           Theme.of(context).colorScheme.primary,
                            //       fontSize: 13,
                            //     ),
                            //   ),
                            // ),
                            // const SizedBox(width: 4),
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
