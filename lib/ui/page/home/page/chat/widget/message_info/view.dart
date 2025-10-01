// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View displaying the provided [ChatItem] info.
///
/// Intended to be displayed with the [show] method.
class MessageInfo extends StatelessWidget {
  const MessageInfo({
    super.key,
    this.chatId,
    this.chatItemId,
    this.reads = const [],
  });

  /// [ChatItem] for this [MessageInfo].
  final ChatId? chatId;

  /// [ChatItem] for this [MessageInfo].
  final ChatItemId? chatItemId;

  /// [LastChatRead]s of a [ChatItem] this [MessageInfo] is about.
  final Iterable<LastChatRead> reads;

  /// Displays a [MessageInfo] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    ChatId? chatId,
    ChatItemId? chatItemId,
    Iterable<LastChatRead> reads = const [],
  }) {
    return ModalPopup.show(
      context: context,
      child: MessageInfo(chatId: chatId, chatItemId: chatItemId, reads: reads),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).style;

    return GetBuilder(
      init: MessageInfoController(chatId, chatItemId, Get.find(), reads: reads),
      builder: (MessageInfoController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            ModalPopupHeader(text: 'label_message'.l10n),
            Obx(() {
              if (c.chatItem.value == null) {
                return const SizedBox();
              }

              final ChatItem chatItem = c.chatItem.value!.value;

              return Padding(
                padding: ModalPopup.padding(context),
                child: Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.top,
                  children: [
                    _tableRow(
                      style,
                      'label_id'.l10n,
                      WidgetButton(
                        onPressed: () {
                          PlatformUtils.copy(text: chatItem.id.val);
                          MessagePopup.success('label_copied'.l10n);
                        },
                        child: Row(
                          children: [
                            Text(
                              chatItem.id.val,
                              style: style.fonts.small.regular.onBackground,
                            ),
                            const SizedBox(width: 8),
                            const SvgIcon(SvgIcons.copySmall),
                          ],
                        ),
                      ),
                    ),
                    _tableRow(
                      style,
                      'label_sent'.l10n,
                      Text(
                        chatItem.at.val.toLocal().hmyMd,
                        style: style.fonts.small.regular.onBackground,
                      ),
                    ),
                    _tableRow(
                      style,
                      'label_status'.l10n,
                      c.displayMembers.value == true
                          ? _contactList(context, c, reads)
                          : Text(
                              _getLabelStatus(c.chatItem.value!.value),
                              style: style.fonts.small.regular.onBackground,
                            ),
                      addPadding: c.displayMembers.value == true ? 10 : 0,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// Represents a table row for table with info
  TableRow _tableRow(
    Style style,
    String label,
    Widget child, {
    double addPadding = 0,
  }) => TableRow(
    children: [
      Padding(
        padding: EdgeInsets.only(top: 4 + addPadding),
        child: Text(
          label,
          style: style.fonts.small.regular.secondary,
          textAlign: TextAlign.right,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle(
            style: style.fonts.small.regular.secondary.copyWith(
              color: style.colors.secondaryBackgroundLight,
            ),
            child: child,
          ),
        ),
      ),
    ],
  );

  /// Returns a list of [ContactTile] with the icon status
  Widget _contactList(
    BuildContext context,
    MessageInfoController c,
    Iterable<LastChatRead> reads,
  ) {
    final List<Widget> contactTiles = [];

    for (final member in c.members) {
      final bool isRead = reads.map((r) => r.memberId).contains(member.id);
      final Widget widget = ContactTile(
        user: member,
        onTap: () {
          Navigator.of(context).pop();
          router.user(member.id, push: true);
        },
        height: 38,
        trailing: [
          isRead ? SvgIcon(SvgIcons.read) : SvgIcon(SvgIcons.delivered),
        ],
      );

      if (isRead) {
        contactTiles.insert(0, widget);
      } else {
        contactTiles.add(widget);
      }
    }

    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Scrollbar(
            controller: c.scrollController,
            child: ListView.builder(
              controller: c.scrollController,
              itemCount: contactTiles.length,
              itemBuilder: (_, i) => contactTiles[i],
            ),
          ),
        ),
      ],
    );
  }

  /// Returns localized string of [chatItem] status
  String _getLabelStatus(ChatItem chatItem) {
    if (reads.isNotEmpty) {
      return 'label_message_status_read'.l10n;
    }

    if (chatItem.status.value.name == 'sent') {
      return 'label_message_status_delivered'.l10n;
    }

    if (chatItem.status.value.name == 'sending') {
      return 'label_message_status_sent'.l10n;
    }

    return 'label_message_status_not_sent'.l10n;
  }
}
