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
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View displaying the provided [reads] along with corresponding [User]s.
///
/// Intended to be displayed with the [show] method.
class ChatItemReads extends StatelessWidget {
  const ChatItemReads({
    super.key,
    this.id,
    this.reads = const [],
    this.getUser,
  });

  /// [ChatItemId] of this [ChatItemReads].
  final ChatItemId? id;

  /// [LastChatRead]s themselves.
  final Iterable<LastChatRead> reads;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  /// Displays a [ChatItemReads] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    ChatItemId? id,
    Iterable<LastChatRead> reads = const [],
    Future<RxUser?> Function(UserId userId)? getUser,
  }) {
    return ModalPopup.show(
      context: context,
      child: ChatItemReads(id: id, reads: reads, getUser: getUser),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);
    final Style style = Theme.of(context).extension<Style>()!;
    final OutlineInputBorder inputStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide.none,
    );

    return GetBuilder(
      init: ChatItemReadsController(reads: reads, getUser: getUser),
      builder: (ChatItemReadsController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            ModalPopupHeader(
              header: Center(
                child: Text(
                  'label_message'.l10n,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
            ),
            if (id != null)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: ModalPopup.padding(context),
                alignment: Alignment.center,
                child: WidgetButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: id!.val));
                    MessagePopup.success('label_copied_to_clipboard'.l10n);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${'label_id'.l10n}${'colon_space'.l10n}$id',
                        style: thin?.copyWith(fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      SvgLoader.asset(
                        'assets/icons/copy.svg',
                        height: 12,
                      ),
                    ],
                  ),
                ),
              ),
            Obx(() {
              if (c.users.length > 2) {
                return Container(
                  padding: ModalPopup.padding(context).subtract(
                    context.isMobile
                        ? EdgeInsets.zero
                        : const EdgeInsets.only(left: 8, right: 8),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: 50,
                    child: CustomAppBar(
                      padding: EdgeInsets.zero,
                      border: !c.search.isEmpty.value || c.isFocused.value
                          ? Border.all(
                              color: Theme.of(context).colorScheme.secondary,
                              width: 2,
                            )
                          : null,
                      title: Theme(
                        data: Theme.of(context).copyWith(
                          shadowColor: const Color(0x55000000),
                          iconTheme: const IconThemeData(color: Colors.blue),
                          inputDecorationTheme: InputDecorationTheme(
                            border: inputStyle,
                            errorBorder: inputStyle,
                            enabledBorder: inputStyle,
                            focusedBorder: inputStyle,
                            disabledBorder: inputStyle,
                            focusedErrorBorder: inputStyle,
                            focusColor: Colors.white,
                            fillColor: Colors.white,
                            hoverColor: Colors.transparent,
                            filled: true,
                            isDense: true,
                            contentPadding: EdgeInsets.fromLTRB(
                              15,
                              PlatformUtils.isDesktop ? 40 : 33,
                              15,
                              10,
                            ),
                          ),
                        ),
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
                            style: style.boldBody.copyWith(fontSize: 17),
                            onChanged: () => c.query.value = c.search.text,
                          ),
                        ),
                      ),
                      leading: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 12),
                          child: SvgLoader.asset(
                            'assets/icons/search.svg',
                            width: 17.77,
                          ),
                        )
                      ],
                      actions: [
                        Obx(() {
                          return AnimatedSwitcher(
                            duration: 250.milliseconds,
                            child: !c.search.isEmpty.value
                                ? WidgetButton(
                                    onPressed: () {
                                      c.search.clear();
                                      c.search.unsubmit();
                                      c.query.value = '';
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        right: 18,
                                      ),
                                      child: SvgLoader.asset(
                                        'assets/icons/close_primary.svg',
                                        height: 15,
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox();
            }),
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
                            child: Center(child: Text('label_not_found'.l10n)),
                          )
                        else
                          ...users.map((e) {
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
                                  '${'label_read_at'.l10n}'
                                  '${DateFormat('dd.MM.yyyy, kk:mm').format(
                                    reads.first.at.val,
                                  )}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
