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

import '../controller.dart';
import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

/// Builds a visual representation of the provided [item].
class MessageFieldMessage extends StatefulWidget {
  const MessageFieldMessage(
    this.item,
    this.c,
    this.onClose, {
    super.key,
    this.isEdit = false,
  });

  /// [ChatItem] used to builds a visual representation.
  final ChatItem item;

  /// Controller of message field.
  final MessageFieldController c;

  /// Indicator whether is editing message or not.
  final bool isEdit;

  /// Callback, called when tapped close button.
  final void Function() onClose;

  @override
  State<MessageFieldMessage> createState() => _MessageFieldMessageState();
}

/// [State] of [MessageFieldMessage].
class _MessageFieldMessageState extends State<MessageFieldMessage> {
  /// Reactive [User] value, author of message.
  RxUser? user;

  @override
  void initState() {
    _init();
    super.initState();
  }

  /// Initialize [user] value.
  Future<void> _init() async {
    if (widget.isEdit == false) {
      user = await widget.c.getUser(widget.item.authorId);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final ChatItem item = widget.item;
    final bool fromMe = item.authorId == widget.c.me;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      if (item.attachments.isNotEmpty) {
        additional = item.attachments.map((a) {
          ImageAttachment? image;

          if (a is ImageAttachment) {
            image = a;
          }

          return Container(
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: fromMe
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(4),
            ),
            width: 30,
            height: 30,
            child: image == null
                ? Icon(
                    Icons.file_copy,
                    color: fromMe ? Colors.white : const Color(0xFFDDDDDD),
                    size: 16,
                  )
                : RetryImage(
                    image.small.url,
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(4),
                  ),
          );
        }).toList();
      }

      if (item.text != null && item.text!.val.isNotEmpty) {
        content = Text(
          item.text!.val,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.boldBody,
        );
      }
    } else if (item is ChatCall) {
      String title = 'label_chat_call_ended'.l10n;
      String? time;
      bool fromMe = widget.c.me == item.authorId;
      bool isMissed = false;

      if (item.finishReason == null && item.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.l10n;
      } else if (item.finishReason != null) {
        title = item.finishReason!.localizedString(fromMe) ?? title;
        isMissed = item.finishReason == ChatCallFinishReason.dropped ||
            item.finishReason == ChatCallFinishReason.unanswered;

        if (item.finishedAt != null && item.conversationStartedAt != null) {
          time = item.conversationStartedAt!.val
              .difference(item.finishedAt!.val)
              .localizedString();
        }
      } else {
        title = item.authorId == widget.c.me
            ? 'label_outgoing_call'.l10n
            : 'label_incoming_call'.l10n;
      }

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            child: item.withVideo
                ? SvgLoader.asset(
                    'assets/icons/call_video${isMissed && !fromMe ? '_red' : ''}.svg',
                    height: 13,
                  )
                : SvgLoader.asset(
                    'assets/icons/call_audio${isMissed && !fromMe ? '_red' : ''}.svg',
                    height: 15,
                  ),
          ),
          Flexible(child: Text(title, style: style.boldBody)),
          if (time != null) ...[
            const SizedBox(width: 9),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.boldBody.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      );
    } else if (item is ChatForward) {
      // TODO: Implement `ChatForward`.
      content = Text('label_forwarded_message'.l10n, style: style.boldBody);
    } else if (item is ChatMemberInfo) {
      // TODO: Implement `ChatMemberInfo`.
      content = Text(item.action.toString(), style: style.boldBody);
    } else {
      content = Text('err_unknown'.l10n, style: style.boldBody);
    }

    return MouseRegion(
      opaque: false,
      onEnter: (d) => widget.c.hoveredReply.value = item,
      onExit: (d) => widget.c.hoveredReply.value = null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.isEdit == true
                ? Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 12),
                        SvgLoader.asset(
                          'assets/icons/edit.svg',
                          width: 17,
                          height: 17,
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  width: 2,
                                  color: Color(0xFF63B4FF),
                                ),
                              ),
                            ),
                            margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            padding: const EdgeInsets.only(left: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'label_edit'.l10n,
                                  style: style.boldBody.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                if (content != null) ...[
                                  const SizedBox(height: 2),
                                  DefaultTextStyle.merge(
                                    maxLines: 1,
                                    child: content,
                                  ),
                                ],
                                if (additional.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(children: additional),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Expanded(
                    child: Builder(builder: (context) {
                      Color color = user?.user.value.id == widget.c.me
                          ? Theme.of(context).colorScheme.secondary
                          : AvatarWidget.colors[
                              (user?.user.value.num.val.sum() ?? 3) %
                                  AvatarWidget.colors.length];

                      return Container(
                        key: Key('Reply_${widget.c.replied.indexOf(item)}'),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(width: 2, color: color),
                          ),
                        ),
                        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Builder(
                              builder: (context) {
                                String? name;

                                if (user != null) {
                                  name = user?.user.value.name?.val;
                                  if (user?.user.value != null) {
                                    return Obx(() {
                                      return Text(
                                        user!.user.value.name?.val ??
                                            user!.user.value.num.val,
                                        style: style.boldBody
                                            .copyWith(color: color),
                                      );
                                    });
                                  }
                                }

                                return Text(
                                  name ?? ('dot'.l10n * 3),
                                  style: style.boldBody.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                );
                              },
                            ),
                            if (content != null) ...[
                              const SizedBox(height: 2),
                              DefaultTextStyle.merge(
                                maxLines: 1,
                                child: content,
                              ),
                            ],
                            if (additional.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(children: additional),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
            Obx(() {
              final Widget child;

              if (widget.c.hoveredReply.value == item ||
                  PlatformUtils.isMobile) {
                child = WidgetButton(
                  key: const Key('CancelReplyButton'),
                  onPressed: () => widget.onClose.call(),
                  child: Container(
                    width: 15,
                    height: 15,
                    margin: const EdgeInsets.only(right: 4, top: 4),
                    child: Container(
                      key: const Key('Close'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: style.cardColor,
                      ),
                      child: Center(
                        child: SvgLoader.asset(
                          'assets/icons/close_primary.svg',
                          width: 7,
                          height: 7,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                child = const SizedBox();
              }

              return AnimatedSwitcher(duration: 200.milliseconds, child: child);
            }),
          ],
        ),
      ),
    );
  }
}
