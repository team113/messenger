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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/my_user.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '../swipeable_status.dart';

/// [Widget] which renders [item] as [ChatInfo].
class RenderAsChatInfo extends StatelessWidget {
  const RenderAsChatInfo({
    super.key,
    required this.chat,
    required this.item,
    required this.fromMe,
    required this.isRead,
    this.rxUser,
    this.animation,
    this.getUser,
  });

  /// Reactive value of a [Chat] this [item] is posted in.
  final Chat? chat;

  /// Reactive value of a [ChatItem] to display.
  final ChatItem item;

  /// [User] posted this [item].
  final RxUser? rxUser;

  /// Animation that controls a [SwipeableStatus].
  final AnimationController? animation;

  /// Indicator whether this [ChatItemWidget.item] was posted by the
  /// authenticated [MyUser].
  final bool fromMe;

  /// Indicator whether this [ChatItem] was read by any [User].
  final bool isRead;

  /// Callback, called when a [RxUser] identified by the provided [UserId]
  /// is required.
  final Future<RxUser?> Function(UserId)? getUser;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final ChatInfo message = item as ChatInfo;

    final Widget content;

    // Builds a [FutureBuilder] returning a [User] fetched by the provided [id].
    Widget userBuilder(
      UserId id,
      Widget Function(BuildContext context, User? user) builder,
    ) {
      return FutureBuilder(
        future: getUser?.call(id),
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            return builder(context, snapshot.data!.user.value);
          }

          return builder(context, null);
        },
      );
    }

    switch (message.action.kind) {
      case ChatInfoActionKind.created:
        if (chat?.isGroup == true) {
          content = userBuilder(message.authorId, (context, user) {
            if (user != null) {
              final Map<String, dynamic> args = {
                'author': user.name?.val ?? user.num.val,
              };

              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'label_group_created_by1'.l10nfmt(args),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => router.user(user.id, push: true),
                    ),
                    TextSpan(
                      text: 'label_group_created_by2'.l10nfmt(args),
                      style: style.systemMessageStyle.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  style: style.systemMessageStyle.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              );
            }

            return Text('label_group_created'.l10n);
          });
        } else if (chat?.isMonolog == true) {
          content = Text('label_monolog_created'.l10n);
        } else {
          content = Text('label_dialog_created'.l10n);
        }
        break;

      case ChatInfoActionKind.memberAdded:
        final action = message.action as ChatInfoActionMemberAdded;

        if (action.user.id != message.authorId) {
          content = userBuilder(action.user.id, (context, user) {
            final User author = rxUser?.user.value ?? message.author;
            user ??= action.user;

            final Map<String, dynamic> args = {
              'author': author.name?.val ?? author.num.val,
              'user': user.name?.val ?? user.num.val,
            };

            return Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'label_user_added_user1'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => router.user(author.id, push: true),
                  ),
                  TextSpan(
                    text: 'label_user_added_user2'.l10nfmt(args),
                    style: style.systemMessageStyle.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: 'label_user_added_user3'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => router.user(user!.id, push: true),
                  ),
                ],
                style: style.systemMessageStyle.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            );
          });
        } else {
          final Map<String, dynamic> args = {
            'author': action.user.name?.val ?? action.user.num.val,
          };

          content = Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'label_was_added1'.l10nfmt(args),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => router.user(action.user.id, push: true),
                ),
                TextSpan(
                  text: 'label_was_added2'.l10nfmt(args),
                  style: style.systemMessageStyle.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
              style: style.systemMessageStyle.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          );
        }
        break;

      case ChatInfoActionKind.memberRemoved:
        final action = message.action as ChatInfoActionMemberRemoved;

        if (action.user.id != message.authorId) {
          content = userBuilder(action.user.id, (context, user) {
            final User author = rxUser?.user.value ?? message.author;
            user ??= action.user;

            final Map<String, dynamic> args = {
              'author': author.name?.val ?? author.num.val,
              'user': user.name?.val ?? user.num.val,
            };

            return Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'label_user_removed_user1'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => router.user(author.id, push: true),
                  ),
                  TextSpan(
                    text: 'label_user_removed_user2'.l10nfmt(args),
                    style: style.systemMessageStyle.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: 'label_user_removed_user3'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => router.user(user!.id, push: true),
                  ),
                ],
                style: style.systemMessageStyle.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            );
          });
        } else {
          final Map<String, dynamic> args = {
            'author': action.user.name?.val ?? action.user.num.val,
          };

          content = Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'label_was_removed1'.l10nfmt(args),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => router.user(action.user.id, push: true),
                ),
                TextSpan(
                  text: 'label_was_removed2'.l10nfmt(args),
                  style: style.systemMessageStyle.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
              style: style.systemMessageStyle.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          );
        }
        break;

      case ChatInfoActionKind.avatarUpdated:
        final action = message.action as ChatInfoActionAvatarUpdated;

        final User user = rxUser?.user.value ?? message.author;
        final Map<String, dynamic> args = {
          'author': user.name?.val ?? user.num.val,
        };

        final String phrase1, phrase2;
        if (action.avatar == null) {
          phrase1 = 'label_avatar_removed1';
          phrase2 = 'label_avatar_removed2';
        } else {
          phrase1 = 'label_avatar_updated1';
          phrase2 = 'label_avatar_updated2';
        }

        content = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: phrase1.l10nfmt(args),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => router.user(user.id, push: true),
              ),
              TextSpan(
                text: phrase2.l10nfmt(args),
                style: style.systemMessageStyle.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            style: style.systemMessageStyle.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        );
        break;

      case ChatInfoActionKind.nameUpdated:
        final action = message.action as ChatInfoActionNameUpdated;

        final User user = rxUser?.user.value ?? message.author;
        final Map<String, dynamic> args = {
          'author': user.name?.val ?? user.num.val,
          if (action.name != null) 'name': action.name?.val,
        };

        final String phrase1, phrase2;
        if (action.name == null) {
          phrase1 = 'label_name_removed1';
          phrase2 = 'label_name_removed2';
        } else {
          phrase1 = 'label_name_updated1';
          phrase2 = 'label_name_updated2';
        }

        content = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: phrase1.l10nfmt(args),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => router.user(user.id, push: true),
              ),
              TextSpan(
                text: phrase2.l10nfmt(args),
                style: style.systemMessageStyle.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            style: style.systemMessageStyle.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        );
        break;
    }

    final bool isSent = item.status.value == SendingStatus.sent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SwipeableStatus(
        animation: animation,
        translate: false,
        isSent: isSent && fromMe,
        isDelivered: isSent &&
            fromMe &&
            chat?.lastDelivery.isBefore(message.at) == false,
        isRead: isSent && (!fromMe || isRead),
        isError: message.status.value == SendingStatus.error,
        isSending: message.status.value == SendingStatus.sending,
        swipeable: Text(DateFormat.Hm().format(message.at.val.toLocal())),
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: style.systemMessageBorder,
              color: style.systemMessageColor,
            ),
            child: DefaultTextStyle(
              style: style.systemMessageStyle,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
