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

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/util/platform_utils.dart';
import '/util/fixed_timer.dart';

/// Subtitle visual representation of a [RxChat].
class ChatSubtitle extends StatefulWidget {
  const ChatSubtitle(
    this.chat,
    this.me, {
    super.key,
    this.withActivities = true,
  });

  /// [RxChat] to display subtitle of.
  final RxChat chat;

  /// [UserId] of the currently authorized [MyUser].
  final UserId? me;

  /// Indicator whether ongoing activities of the provided [chat] should be
  /// displayed within this [ChatSubtitle].
  final bool withActivities;

  @override
  State<ChatSubtitle> createState() => _ChatSubtitleState();
}

/// State of an [ChatSubtitle] maintaining the [_durationTimer].
class _ChatSubtitleState extends State<ChatSubtitle> {
  /// Duration of a [Chat.ongoingCall] to display, if any.
  Duration? _duration;

  /// Previous [Chat.ongoingCall], used to reset the [_durationTimer] on its
  /// changes.
  ChatItemId? _previousCall;

  /// [FixedTimer] for updating [_duration] of a [Chat.ongoingCall], if any.
  FixedTimer? _durationTimer;

  /// Worker invoking the [_updateTimer] on the [RxChat.chat] changes.
  Worker? _chatWorker;

  @override
  void dispose() {
    _durationTimer?.cancel();
    _chatWorker?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.withActivities) {
      _updateTimer(widget.chat.chat.value);
      _chatWorker = ever(widget.chat.chat, _updateTimer);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Chat chat = widget.chat.chat.value;

      final Set<UserId>? actualMembers = widget
          .chat
          .chat
          .value
          .ongoingCall
          ?.members
          .map((k) => k.user.id)
          .toSet();

      if (widget.withActivities) {
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
                'b': widget.chat.chat.value.membersCount,
              }),
            ),
          );

          if (_duration != null) {
            spans.add(TextSpan(text: 'space_vertical_space'.l10n));
            spans.add(TextSpan(text: _duration?.hhMmSs()));
          }

          return Text.rich(
            TextSpan(
              children: spans,
              style: style.fonts.small.regular.secondary,
            ),
          );
        }

        final bool isTyping =
            widget.chat.typingUsers.any((e) => e.id != widget.me) == true;
        if (isTyping) {
          if (!chat.isGroup) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'label_typing'.l10n,
                  style: style.fonts.small.regular.primary,
                ),
                const SizedBox(width: 2),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: AnimatedTyping(),
                ),
              ],
            );
          }

          final Iterable<String> typings = widget.chat.typingUsers
              .where((e) => e.id != widget.me)
              .map((e) => e.title());

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  typings.join('comma_space'.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.fonts.small.regular.primary,
                ),
              ),
              const SizedBox(width: 2),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: AnimatedTyping(),
              ),
            ],
          );
        }
      }

      if (chat.isGroup) {
        final String? subtitle = chat.getSubtitle();

        if (subtitle != null) {
          return Text(subtitle, style: style.fonts.small.regular.secondary);
        }

        return const SizedBox();
      } else if (chat.isDialog) {
        final RxUser? member = widget.chat.members.values
            .firstWhereOrNull((u) => u.user.user.value.id != widget.me)
            ?.user;

        if (member != null) {
          return Obx(() {
            final String? presence = chat.getSubtitle(partner: member);

            if (presence == null) {
              return const SizedBox();
            }

            final String subtitle = [
              presence,
            ].nonNulls.join('space_vertical_space'.l10n);

            return Text(subtitle, style: style.fonts.small.regular.secondary);
          });
        }
      }

      return const SizedBox();
    });
  }

  // Updates the [_durationTimer], if current [Chat.ongoingCall] differs
  // from the stored [_previousCall].
  void _updateTimer(Chat chat) {
    if (_previousCall != chat.ongoingCall?.id) {
      _previousCall = chat.ongoingCall?.id;

      _duration = null;
      _durationTimer?.cancel();
      _durationTimer = null;

      if (chat.ongoingCall != null) {
        _durationTimer = FixedTimer.periodic(const Duration(seconds: 1), () {
          if (chat.ongoingCall?.conversationStartedAt != null) {
            _duration = DateTime.now().difference(
              chat.ongoingCall!.conversationStartedAt!.val,
            );

            if (mounted) {
              setState(() {});
            }
          }
        });
      }
    }
  }
}
