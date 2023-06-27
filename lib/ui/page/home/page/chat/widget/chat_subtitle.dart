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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// [Widget] which returns a header subtitle of the chat.
class ChatSubtitle extends StatefulWidget {
  const ChatSubtitle({
    super.key,
    required this.rxChat,
    required this.onWillAccept,
    this.text,
    this.subtitle,
    this.future,
    this.member = true,
  });

  /// [RxChat] of this [ChatSubtitle].
  final RxChat? rxChat;

  /// [Text] to display in this [ChatSubtitle].
  final String? text;

  /// Indicator whether the chat is with a member.
  final bool member;

  /// Subtitle [Widget] of this [ChatSubtitle].
  final Widget? subtitle;

  /// Computation of the [FutureBuilder].
  final Future? future;

  /// Callback, called to determine whether this widget of the currently
  /// typing users takes part in the [ChatSubtitle].
  final bool Function(User) onWillAccept;

  @override
  State<ChatSubtitle> createState() => _ChatSubtitleState();
}

/// State of an [ChatSubtitle] maintaining the [_durationTimer].
class _ChatSubtitleState extends State<ChatSubtitle> {
  /// Duration of a [Chat.ongoingCall].
  final Rx<Duration?> duration = Rx(null);

  /// [Timer] for updating [duration] of a [Chat.ongoingCall], if any.
  Timer? _durationTimer;

  /// Previous [Chat.ongoingCall], used to reset the [_durationTimer] on its
  /// changes.
  ChatItemId? previousCall;

  /// Worker capturing any [RxChat.chat] changes.
  Worker? _chatWorker;

  @override
  void dispose() {
    _durationTimer?.cancel();
    _chatWorker?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _chatWorker = ever(
      widget.rxChat!.chat,
      (Chat e) => updateChatAndTimer(e),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    final Chat chat = widget.rxChat!.chat.value;

    final Set<UserId>? actualMembers = widget
        .rxChat!.chat.value.ongoingCall?.members
        .map((k) => k.user.id)
        .toSet();

    if (chat.ongoingCall != null) {
      final List<TextSpan> spans = [];
      if (!context.isMobile) {
        spans.add(TextSpan(text: 'label_call_active'.l10n));
        spans.add(TextSpan(text: 'space_vertical_space'.l10n));
      }

      spans.add(
        TextSpan(
          text: 'label_a_of_b'.l10nfmt({
            'a': actualMembers?.length,
            'b': widget.rxChat!.members.length,
          }),
        ),
      );

      if (duration.value != null) {
        spans.add(TextSpan(text: 'space_vertical_space'.l10n));
        spans.add(TextSpan(text: duration.value?.hhMmSs()));
      }

      return Text.rich(
        TextSpan(
          children: spans,
          style: fonts.bodySmall!.copyWith(color: style.colors.secondary),
        ),
      );
    }

    if (widget.rxChat?.typingUsers.any(widget.onWillAccept) == true) {
      if (!chat.isGroup) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'label_typing'.l10n,
              style: fonts.labelMedium!.copyWith(color: style.colors.primary),
            ),
            const SizedBox(width: 3),
            const Padding(
              padding: EdgeInsets.only(bottom: 3),
              child: AnimatedTyping(),
            ),
          ],
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.text != null)
            Flexible(
              child: Text(
                widget.text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: fonts.labelMedium!.copyWith(color: style.colors.primary),
              ),
            ),
          const SizedBox(width: 3),
          const Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: AnimatedTyping(),
          ),
        ],
      );
    }

    if (chat.isGroup) {
      return Text(
        chat.getSubtitle()!,
        style: fonts.bodySmall!.copyWith(color: style.colors.secondary),
      );
    } else if (chat.isDialog) {
      if (widget.member) {
        return Row(
          children: [
            if (chat.muted != null) ...[
              SvgImage.asset(
                'assets/icons/muted_dark.svg',
                width: 19.99 * 0.6,
                height: 15 * 0.6,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: FutureBuilder(
                future: widget.future,
                builder: (_, snapshot) {
                  if (snapshot.data != null) {
                    final String? subtitle =
                        chat.getSubtitle(partner: snapshot.data!.user.value);

                    final UserTextStatus? status =
                        snapshot.data!.user.value.status;

                    if (status != null || subtitle != null) {
                      final StringBuffer buffer = StringBuffer(status ?? '');

                      if (status != null && subtitle != null) {
                        buffer.write('space_vertical_space'.l10n);
                      }

                      buffer.write(subtitle ?? '');

                      return Text(
                        buffer.toString(),
                        style: fonts.bodySmall!.copyWith(
                          color: style.colors.secondary,
                        ),
                      );
                    }

                    return const SizedBox();
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        );
      }
    }

    return const SizedBox();
  }

  // Updates the [_durationTimer], if current [Chat.ongoingCall] differs
  // from the stored [previousCall].
  void updateChatAndTimer(Chat chat) {
    if (chat.id != widget.rxChat!.chat.value.id) {
      WebUtils.replaceState(widget.rxChat!.chat.value.id.val, chat.id.val);
      widget.rxChat!.chat.value.id = chat.id;
    }

    if (previousCall != chat.ongoingCall?.id) {
      previousCall = chat.ongoingCall?.id;

      duration.value = null;
      _durationTimer?.cancel();
      _durationTimer = null;

      if (chat.ongoingCall != null) {
        _durationTimer = Timer.periodic(
          const Duration(seconds: 1),
          (_) {
            if (chat.ongoingCall!.conversationStartedAt != null) {
              duration.value = DateTime.now().difference(
                chat.ongoingCall!.conversationStartedAt!.val,
              );
              if (mounted) {
                setState(() {});
              }
            }
          },
        );
      }
    }
  }
}
