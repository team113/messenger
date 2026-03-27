// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/config.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View displaying the blocked [User]s.
///
/// Intended to be displayed with the [show] method.
class BlocklistView extends StatelessWidget {
  const BlocklistView({super.key});

  /// Displays a [BlocklistView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    final style = Theme.of(context).style;

    return ModalPopup.show(
      context: context,
      child: const BlocklistView(),
      background: style.colors.background,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('BlocklistView'),
      init: BlocklistController(
        Get.find(),
        Get.find(),
        Get.find(),
        pop: context.popModal,
      ),
      builder: (BlocklistController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(text: 'label_blocked_users'.l10n),
            const SizedBox(height: 4),
            Flexible(
              child: SafeAnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Obx(() {
                  // Show only users with [User.isBlocked] for optimistic
                  // deletion from blocklist.
                  final Iterable<RxUser> blocklist = c.blocklist.where(
                    (e) => e.user.value.isBlocked != null,
                  );

                  if (c.status.value.isLoading) {
                    return SizedBox(
                      height: c.blocklistCount.value * 95,
                      child: const Center(
                        child: CustomProgressIndicator.primary(),
                      ),
                    );
                  } else if (blocklist.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'label_no_users'.l10n,
                        style: style.fonts.small.regular.secondary,
                      ),
                    );
                  } else {
                    return Scrollbar(
                      controller: c.scrollController,
                      child: ListView(
                        controller: c.scrollController,
                        shrinkWrap: true,
                        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                        children: [
                          SizedBox(height: 12),
                          LineDivider(
                            'label_users_count'.l10nfmt({
                              'count': c.blocklistCount.value,
                            }),
                          ),
                          SizedBox(height: 16),
                          ...c.blocklist.mapIndexed((i, e) {
                            final RxUser user = blocklist.elementAt(i);
                            final BlocklistRecord? blocked =
                                user.user.value.isBlocked;

                            Widget child = ContactTile(
                              user: user,
                              onTap: () {
                                Navigator.of(context).pop();
                                router.user(user.id, push: true);
                              },
                              darken: 0.03,
                              subtitle: [
                                const SizedBox(height: 5),
                                Text(
                                  blocked?.reason == null
                                      ? blocked?.at.val.yMd ?? ''
                                      : 'label_reason_described'.l10nfmt({
                                          'reason': blocked?.reason?.val,
                                        }),
                                  style: style.fonts.normal.regular.secondary,
                                ),
                              ],
                              trailing: [
                                WidgetButton(
                                  onPressed: () => c.unblock(user),
                                  child: SvgIcon(SvgIcons.unblockSmall),
                                ),
                                const SizedBox(width: 4),
                              ],
                            );

                            if (i == c.blocklist.length - 1) {
                              if (c.hasNext.isTrue) {
                                child = Column(
                                  children: [
                                    child,
                                    CustomProgressIndicator(
                                      key: const Key('BlocklistLoading'),
                                      value: Config.disableInfiniteAnimations
                                          ? 0
                                          : null,
                                    ),
                                  ],
                                );
                              }
                            }

                            return child;
                          }),
                        ],
                      ),
                    );
                  }
                }),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
