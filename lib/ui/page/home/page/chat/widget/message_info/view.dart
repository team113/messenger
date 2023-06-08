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

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View displaying the provided [ChatItem] info.
///
/// Intended to be displayed with the [show] method.
class MessageInfo extends StatelessWidget {
  const MessageInfo({super.key, this.id, this.reads = const []});

  /// [ChatItemId] of a [ChatItem] this [MessageInfo] is about.
  final ChatItemId? id;

  /// [LastChatRead]s of a [ChatItem] this [MessageInfo] is about.
  final Iterable<LastChatRead> reads;

  /// Displays a [MessageInfo] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    ChatItemId? id,
    Iterable<LastChatRead> reads = const [],
  }) {
    return ModalPopup.show(
      context: context,
      child: MessageInfo(id: id, reads: reads),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles();

    return GetBuilder(
      init: MessageInfoController(Get.find(), reads: reads),
      builder: (MessageInfoController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            ModalPopupHeader(
              header: Center(
                child: Text('label_message'.l10n, style: fonts.headlineMedium),
              ),
            ),
            if (id != null)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: ModalPopup.padding(context),
                alignment: Alignment.center,
                child: WidgetButton(
                  onPressed: () {
                    PlatformUtils.copy(text: id!.val);
                    MessagePopup.success('label_copied'.l10n);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ID${'colon_space'.l10n}$id',
                        style: fonts.bodySmall!,
                      ),
                      const SizedBox(width: 8),
                      SvgImage.asset('assets/icons/copy.svg', height: 12),
                    ],
                  ),
                ),
              ),
            Obx(() {
              if (c.users.length < 10) {
                return const SizedBox();
              }

              return Container(
                padding: ModalPopup.padding(context),
                margin: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 50,
                  child: CustomAppBar(
                    border: !c.search.isEmpty.value || c.search.isFocused.value
                        ? Border.all(color: style.colors.primary, width: 2)
                        : null,
                    margin: const EdgeInsets.only(top: 4),
                    title: Theme(
                      data: MessageFieldView.theme(context),
                      child: Transform.translate(
                        offset: const Offset(0, 1),
                        child: ReactiveTextField(
                          key: const Key('SearchField'),
                          state: c.search,
                          hint: 'label_search'.l10n,
                          maxLines: 1,
                          filled: false,
                          dense: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          style: fonts.bodyLarge!,
                          onChanged: () => c.query.value = c.search.text,
                        ),
                      ),
                    ),
                    leading: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 12),
                        child: SvgImage.asset(
                          'assets/icons/search.svg',
                          width: 17.77,
                        ),
                      )
                    ],
                    actions: [
                      Obx(() {
                        final Widget close = WidgetButton(
                          onPressed: () {
                            c.search.clear();
                            c.search.unsubmit();
                            c.query.value = '';
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 18),
                            child: SvgImage.asset(
                              'assets/icons/close_primary.svg',
                              height: 15,
                            ),
                          ),
                        );

                        return AnimatedSwitcher(
                          duration: 250.milliseconds,
                          child: c.search.isEmpty.value ? null : close,
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
            if (reads.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: ModalPopup.padding(context),
                  child: Scrollbar(
                    controller: c.scrollController,
                    child: Obx(() {
                      final users = c.users.where((u) {
                        if (c.query.isNotEmpty) {
                          return u.user.value.name?.val
                                  .toLowerCase()
                                  .contains(c.query.toLowerCase()) ==
                              true;
                        }

                        return true;
                      });

                      return ListView(
                        controller: c.scrollController,
                        shrinkWrap: true,
                        children: [
                          if (users.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('label_nothing_found'.l10n),
                              ),
                            )
                          else
                            ...users.map((e) {
                              final DateTime time = reads.first.at.val;
                              return ContactTile(
                                user: e,
                                dense: true,
                                darken: 0.05,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  router.user(e.id, push: true);
                                },
                                subtitle: [
                                  const SizedBox(height: 3),
                                  Text(
                                    'label_read_at'
                                        .l10nfmt({'date': time.yMdHm}),
                                    style: fonts.bodySmall!.copyWith(
                                      color: style.colors.secondary,
                                    ),
                                  ),
                                ],
                              );
                            }),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
