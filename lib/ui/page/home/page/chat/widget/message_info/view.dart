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

import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View displaying the provided [ChatItem] info.
///
/// Intended to be displayed with the [show] method.
class MessageInfo extends StatelessWidget {
  const MessageInfo(this.id, {super.key});

  /// ID of the [ChatItem] for this [MessageInfo].
  final ChatItemId id;

  /// Displays a [MessageInfo] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, ChatItemId id) {
    return ModalPopup.show(context: context, child: MessageInfo(id));
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).style;

    return GetBuilder(
      init: MessageInfoController(id, Get.find()),
      builder: (MessageInfoController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(text: 'label_information'.l10n),
            Flexible(
              child: Obx(() {
                final ChatItem? item = c.item.value;
                if (item == null) {
                  if (c.status.value.isError) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      child: CustomProgressIndicator(),
                    );
                  } else if (c.status.value.isLoading) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      child: CustomProgressIndicator(),
                    );
                  }

                  return const SizedBox();
                }

                return Padding(
                  padding: ModalPopup.padding(
                    context,
                  ).copyWith(top: 6, right: 0),
                  child: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: MinColumnWidth(
                        FixedColumnWidth(260),
                        FractionColumnWidth(0.7),
                      ),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.top,
                    children: [
                      _tableRow(
                        context,
                        'label_id'.l10n,
                        WidgetButton(
                          onPressed: () {
                            PlatformUtils.copy(text: item.id.val);
                            MessagePopup.success('label_copied'.l10n);
                          },
                          child: Row(
                            children: [
                              Text(
                                item.id.val,
                                style: style.fonts.small.regular.onBackground,
                              ),
                              const SizedBox(width: 8),
                              const SvgIcon(SvgIcons.copySmall),
                            ],
                          ),
                        ),
                      ),
                      _tableRow(
                        context,
                        'label_sent'.l10n,
                        Text(
                          item.at.val.toLocal().hmyMd,
                          style: style.fonts.small.regular.onBackground,
                        ),
                      ),
                      if (c.displayMembers.value)
                        _tableRow(
                          context,
                          'label_status'.l10n,
                          _members(context, c),
                        )
                      else
                        _tableRow(
                          context,
                          'label_status'.l10n,
                          Text(
                            _status(item.status.value, c.reads.isNotEmpty),
                            style: style.fonts.small.regular.onBackground,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// Builds a stylized [TableRow] with [label] and [child].
  TableRow _tableRow(BuildContext context, String label, Widget child) {
    final style = Theme.of(context).style;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
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
  }

  /// Returns a list of [RxUser] visualized.
  Widget _members(BuildContext context, MessageInfoController c) {
    final style = Theme.of(context).style;

    final List<Widget> children = [];

    for (int i = 0; i < c.members.length; ++i) {
      final RxUser member = c.members.elementAt(i);
      final bool isRead = c.reads.map((r) => r.memberId).contains(member.id);

      final Widget widget = Container(
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: style.colors.onPrimary,
          border: style.cardBorder,
        ),
        child: Row(
          children: [
            AvatarWidget.fromRxUser(member, radius: AvatarRadius.smaller),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                member.title(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: 4),
            SvgIcon(isRead ? SvgIcons.read : SvgIcons.sent),
          ],
        ),
      );

      children.add(widget);
      if (i != c.members.length) {
        children.add(const SizedBox(height: 4));
      }
    }

    return Column(children: children);
  }

  /// Returns a localized string of [ChatItem] status.
  String _status(SendingStatus status, bool isRead) {
    if (isRead) {
      return 'label_message_status_read'.l10n;
    }

    if (status.name == 'sent') {
      return 'label_message_status_delivered'.l10n;
    }

    if (status.name == 'sending') {
      return 'label_message_status_sent'.l10n;
    }

    return 'label_message_status_not_sent'.l10n;
  }
}
