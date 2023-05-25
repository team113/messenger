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
import 'package:messenger/ui/page/home/page/chat/widget/chat_item/chat_item.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart' show ChatCallFinishReasonL10n;
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/svg/svg.dart';
import '../message_timestamp.dart';

/// [Widget] which renders [item] as [ChatCall].
class RenderAsChatCall extends StatefulWidget {
  const RenderAsChatCall({
    super.key,
    required this.item,
    required this.fromMe,
    required this.isRead,
    required this.chat,
    required this.avatar,
    required this.timestamp,
    required this.timestampWidget,
    required this.margin,
    required this.rounded,
    required this.startCallTimer,
    this.rxUser,
    this.me,
  });

  /// Reactive value of a [ChatItem] to display.
  final ChatItem item;

  /// Indicates whether this [ChatItemWidget.item] was posted by the
  /// authenticated [MyUser].
  final bool fromMe;

  /// Indicates whether this [ChatItem] was read by any [User].
  final bool isRead;

  /// Reactive value of a [Chat] this [item] is posted in.
  final Chat? chat;

  /// Indicator whether this [ChatItemWidget] should display an [AvatarWidget].
  final bool avatar;

  /// [UserId] of the authenticated [MyUser].
  final UserId? me;

  /// [User] posted this [item].
  final RxUser? rxUser;

  /// Indicator whether a [ChatItem.at] should be displayed within this [ChatItemWidget].
  final bool timestamp;

  /// Builds a [MessageTimestamp] of the provided [item].
  final Widget Function(ChatItem item) timestampWidget;

  /// [EdgeInsets] being margin to apply to this [ChatItemWidget].
  final EdgeInsets margin;

  /// Returns rounded rectangle of a child representing a message box.
  final Widget Function(
    BuildContext context,
    Widget Function(bool) builder, {
    double avatarOffset,
  }) rounded;

  /// Starts the call timer.
  final void Function() startCallTimer;

  @override
  State<RenderAsChatCall> createState() => _RenderAsChatCallState();
}

class _RenderAsChatCallState extends State<RenderAsChatCall> {
  @override
  Widget build(BuildContext context) {
    var message = widget.item as ChatCall;
    bool isOngoing =
        message.finishReason == null && message.conversationStartedAt != null;

    widget.startCallTimer();

    bool isMissed = false;

    String title = 'label_chat_call_ended'.l10n;
    String? time;

    if (isOngoing) {
      title = 'label_chat_call_ongoing'.l10n;
      time = message.conversationStartedAt!.val
          .difference(DateTime.now())
          .localizedString();
    } else if (message.finishReason != null) {
      title = message.finishReason!.localizedString(widget.fromMe) ?? title;
      isMissed = (message.finishReason == ChatCallFinishReason.dropped) ||
          (message.finishReason == ChatCallFinishReason.unanswered);

      if (message.finishedAt != null && message.conversationStartedAt != null) {
        time = message.finishedAt!.val
            .difference(message.conversationStartedAt!.val)
            .localizedString();
      }
    } else {
      title = message.authorId == widget.me
          ? 'label_outgoing_call'.l10n
          : 'label_incoming_call'.l10n;
    }

    final Style style = Theme.of(context).extension<Style>()!;

    final Color color = widget.fromMe
        ? style.colors.primary
        : style.colors.userColors[
            (widget.rxUser?.user.value.num.val.sum() ?? 3) %
                style.colors.userColors.length];

    final Widget call = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: style.colors.onBackground.withOpacity(0.03),
      ),
      padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            child: message.withVideo
                ? SvgImage.asset(
                    'assets/icons/call_video${isMissed && !widget.fromMe ? '_red' : ''}.svg',
                    height: 13 * 1.4,
                  )
                : SvgImage.asset(
                    'assets/icons/call_audio${isMissed && !widget.fromMe ? '_red' : ''}.svg',
                    height: 15 * 1.4,
                  ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style.boldBody,
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ).fixedDigits(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );

    final Widget child = AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: widget.isRead || !widget.fromMe ? 1 : 0.55,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.fromMe &&
                    widget.chat?.isGroup == true &&
                    widget.avatar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: Text(
                      widget.rxUser?.user.value.name?.val ??
                          widget.rxUser?.user.value.num.val ??
                          'dot'.l10n * 3,
                      style: style.boldBody.copyWith(color: color),
                    ),
                  ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(child: call),
                      if (widget.timestamp)
                        WidgetSpan(
                          child: Opacity(
                            opacity: 0,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: widget.timestampWidget(widget.item),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.timestamp)
            Positioned(
              right: 8,
              bottom: 4,
              child: widget.timestampWidget(widget.item),
            )
        ],
      ),
    );

    return widget.rounded(
      context,
      (_) => Padding(
        padding: widget.margin.add(const EdgeInsets.fromLTRB(5, 1, 5, 1)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            border: widget.fromMe
                ? widget.isRead
                    ? style.secondaryBorder
                    : Border.all(
                        color: style.colors.backgroundAuxiliaryLighter,
                        width: 0.5,
                      )
                : style.primaryBorder,
            color: widget.fromMe
                ? widget.isRead
                    ? style.readMessageColor
                    : style.unreadMessageColor
                : style.messageColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: child,
          ),
        ),
      ),
    );
  }
}
