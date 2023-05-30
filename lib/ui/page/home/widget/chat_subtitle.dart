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

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// [Widget] which builds a subtitle for the provided [RxChat] containing
/// either its [Chat.lastItem] or an [AnimatedTyping] indicating an ongoing
/// typing.
class ChatSubtitle extends StatelessWidget {
  const ChatSubtitle(
    this.me, {
    super.key,
    required this.rxChat,
    required this.selected,
    required this.inverted,
    this.getUser,
  });

  /// [RxChat] this [RecentChatTile] is about.
  final RxChat rxChat;

  /// Indicator of whether this [RecentChatTile] is selected and should be
  /// inverted.
  final bool inverted;

  /// Indicator whether this [RecentChatTile] is selected.
  final bool selected;

  /// [UserId] of the authenticated [MyUser].
  final UserId? me;

  /// Callback, called when a [RxUser] identified by the provided [UserId]
  /// is required.
  final Future<RxUser?> Function(UserId)? getUser;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final Chat chat = rxChat.chat.value;

    final ChatItem? item;
    if (rxChat.messages.isNotEmpty) {
      item = rxChat.messages.last.value;
    } else {
      item = chat.lastItem;
    }

    List<Widget> subtitle = [];

    final Iterable<String> typings = rxChat.typingUsers
        .where((User user) => user.id != me)
        .map((User user) => user.name?.val ?? user.num.val);

    ChatMessage? draft = rxChat.draft.value;

    if (draft != null && !selected) {
      final StringBuffer desc = StringBuffer();

      if (draft.text != null) {
        desc.write(draft.text!.val);
      }

      if (draft.repliesTo.isNotEmpty) {
        if (desc.isNotEmpty) desc.write('space'.l10n);
        desc.write('label_replies'.l10nfmt({'count': draft.repliesTo.length}));
      }

      final List<Widget> images = [];

      if (draft.attachments.isNotEmpty) {
        if (draft.text == null) {
          images.addAll(
            draft.attachments.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: _attachment(e, inverted: inverted),
              );
            }),
          );
        } else {
          images.add(
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _attachment(draft.attachments.first, inverted: inverted),
            ),
          );
        }
      }

      subtitle = [
        Text('${'label_draft'.l10n}${'colon_space'.l10n}'),
        if (desc.isEmpty)
          Flexible(
            child: LayoutBuilder(builder: (_, constraints) {
              return Row(
                children: images
                    .take((constraints.maxWidth / (30 + 4)).floor())
                    .toList(),
              );
            }),
          )
        else
          ...images,
        if (desc.isNotEmpty)
          Flexible(
            child: Text(
              desc.toString(),
              key: const Key('Draft'),
            ),
          ),
      ];
    } else if (typings.isNotEmpty) {
      if (!rxChat.chat.value.isGroup) {
        subtitle = [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'label_typing'.l10n,
                style: TextStyle(
                  color:
                      inverted ? style.colors.onPrimary : style.colors.primary,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: AnimatedTyping(inverted: inverted),
              ),
            ],
          ),
        ];
      } else {
        subtitle = [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    typings.join('comma_space'.l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: inverted
                          ? style.colors.onPrimary
                          : style.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: AnimatedTyping(inverted: inverted),
                ),
              ],
            ),
          )
        ];
      }
    } else if (item != null) {
      if (item is ChatCall) {
        Widget widget = Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 6, 2),
          child: Icon(
            Icons.call,
            size: 16,
            color: inverted
                ? style.colors.onPrimary
                : style.colors.secondaryBackgroundLightest,
          ),
        );

        if (item.finishedAt == null && item.finishReason == null) {
          subtitle = [
            widget,
            Flexible(child: Text('label_call_active'.l10n)),
          ];
        } else {
          final String description =
              item.finishReason?.localizedString(item.authorId == me) ??
                  'label_chat_call_ended'.l10n;
          subtitle = [widget, Flexible(child: Text(description))];
        }
      } else if (item is ChatMessage) {
        final desc = StringBuffer();

        if (item.text != null) {
          desc.write(item.text!.val);
        }

        final List<Widget> images = [];

        if (item.attachments.isNotEmpty) {
          if (item.text == null) {
            images.addAll(
              item.attachments.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: _attachment(
                    e,
                    inverted: inverted,
                    onError: () => rxChat.updateAttachments(item!),
                  ),
                );
              }),
            );
          } else {
            images.add(
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _attachment(
                  item.attachments.first,
                  inverted: inverted,
                  onError: () => rxChat.updateAttachments(item!),
                ),
              ),
            );
          }
        }

        subtitle = [
          if (item.authorId == me)
            Text('${'label_you'.l10n}${'colon_space'.l10n}')
          else if (chat.isGroup)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: FutureBuilder<RxUser?>(
                future: getUser?.call(item.authorId),
                builder: (_, snapshot) => snapshot.data != null
                    ? AvatarWidget.fromRxUser(snapshot.data, radius: 10)
                    : AvatarWidget.fromUser(
                        chat.getUser(item!.authorId),
                        radius: 10,
                      ),
              ),
            ),
          if (desc.isEmpty)
            Flexible(
              child: LayoutBuilder(builder: (_, constraints) {
                return Row(
                  children: images
                      .take((constraints.maxWidth / (30 + 4)).floor())
                      .toList(),
                );
              }),
            )
          else
            ...images,
          if (desc.isNotEmpty) Flexible(child: Text(desc.toString())),
        ];
      } else if (item is ChatForward) {
        subtitle = [
          if (chat.isGroup)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: FutureBuilder<RxUser?>(
                future: getUser?.call(item.authorId),
                builder: (_, snapshot) => snapshot.data != null
                    ? AvatarWidget.fromRxUser(snapshot.data, radius: 10)
                    : AvatarWidget.fromUser(
                        chat.getUser(item!.authorId),
                        radius: 10,
                      ),
              ),
            ),
          Flexible(child: Text('[${'label_forwarded_message'.l10n}]')),
        ];
      } else if (item is ChatInfo) {
        Widget content = Text('${item.action}');

        // Builds a [FutureBuilder] returning a [User] fetched by the provided
        // [id].
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

        switch (item.action.kind) {
          case ChatInfoActionKind.created:
            if (chat.isGroup) {
              content = userBuilder(item.authorId, (context, user) {
                user ??= (item as ChatInfo).author;
                final Map<String, dynamic> args = {
                  'author': user.name?.val ?? user.num.val,
                };

                return Text('label_group_created_by'.l10nfmt(args));
              });
            } else if (chat.isMonolog) {
              content = Text('label_monolog_created'.l10n);
            } else {
              content = Text('label_dialog_created'.l10n);
            }
            break;

          case ChatInfoActionKind.memberAdded:
            final action = item.action as ChatInfoActionMemberAdded;

            if (item.authorId != action.user.id) {
              content = userBuilder(action.user.id, (context, user) {
                final User author = (item as ChatInfo).author;
                user ??= action.user;

                final Map<String, dynamic> args = {
                  'author': author.name?.val ?? author.num.val,
                  'user': user.name?.val ?? user.num.val,
                };

                return Text('label_user_added_user'.l10nfmt(args));
              });
            } else {
              content = Text(
                'label_was_added'.l10nfmt(
                  {'author': '${action.user.name ?? action.user.num}'},
                ),
              );
            }
            break;

          case ChatInfoActionKind.memberRemoved:
            final action = item.action as ChatInfoActionMemberRemoved;

            if (item.authorId != action.user.id) {
              content = userBuilder(action.user.id, (context, user) {
                final User author = (item as ChatInfo).author;
                user ??= action.user;

                final Map<String, dynamic> args = {
                  'author': author.name?.val ?? author.num.val,
                  'user': user.name?.val ?? user.num.val,
                };

                return Text('label_user_removed_user'.l10nfmt(args));
              });
            } else {
              content = Text(
                'label_was_removed'.l10nfmt(
                  {'author': '${action.user.name ?? action.user.num}'},
                ),
              );
            }
            break;

          case ChatInfoActionKind.avatarUpdated:
            final action = item.action as ChatInfoActionAvatarUpdated;

            final Map<String, dynamic> args = {
              'author': item.author.name?.val ?? item.author.num.val,
            };

            if (action.avatar == null) {
              content = Text('label_avatar_removed'.l10nfmt(args));
            } else {
              content = Text('label_avatar_updated'.l10nfmt(args));
            }
            break;

          case ChatInfoActionKind.nameUpdated:
            final action = item.action as ChatInfoActionNameUpdated;

            final Map<String, dynamic> args = {
              'author': item.author.name?.val ?? item.author.num.val,
              if (action.name != null) 'name': action.name?.val
            };

            if (action.name == null) {
              content = Text('label_name_removed'.l10nfmt(args));
            } else {
              content = Text('label_name_updated'.l10nfmt(args));
            }
            break;
        }

        subtitle = [Flexible(child: content)];
      } else {
        subtitle = [Flexible(child: Text('label_empty_message'.l10n))];
      }
    } else {
      subtitle = [Flexible(child: Text('label_no_messages'.l10n))];
    }

    return DefaultTextStyle(
      style: Theme.of(context)
          .textTheme
          .titleSmall!
          .copyWith(color: inverted ? style.colors.onPrimary : null),
      overflow: TextOverflow.ellipsis,
      child: Row(children: subtitle),
    );
  }

  /// Builds an [Attachment] visual representation.
  Widget _attachment(
    Attachment e, {
    bool inverted = false,
    Future<void> Function()? onError,
  }) {
    Widget? content;

    final Style style = Theme.of(router.context!).extension<Style>()!;

    if (e is LocalAttachment) {
      if (e.file.isImage && e.file.bytes.value != null) {
        content = Image.memory(e.file.bytes.value!, fit: BoxFit.cover);
      } else if (e.file.isVideo) {
        // TODO: `video_player` being used doesn't support desktop platforms.
        if ((PlatformUtils.isMobile || PlatformUtils.isWeb) &&
            e.file.bytes.value != null) {
          content = FittedBox(
            fit: BoxFit.cover,
            child: VideoThumbnail.bytes(
              bytes: e.file.bytes.value!,
              key: key,
              height: 300,
            ),
          );
        } else {
          content = Container(
            color: inverted ? style.colors.onPrimary : style.colors.secondary,
            child: Icon(
              Icons.video_file,
              size: 18,
              color: inverted ? style.colors.secondary : style.colors.onPrimary,
            ),
          );
        }
      } else {
        content = Container(
          color: inverted ? style.colors.onPrimary : style.colors.secondary,
          child: SvgImage.asset(
            inverted ? 'assets/icons/file_dark.svg' : 'assets/icons/file.svg',
            width: 30,
            height: 30,
          ),
        );
      }
    }

    if (e is ImageAttachment) {
      content = RetryImage(
        e.medium.url,
        checksum: e.medium.checksum,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        onForbidden: onError,
        displayProgress: false,
      );
    }

    if (e is FileAttachment) {
      if (e.isVideo) {
        if (PlatformUtils.isMobile || PlatformUtils.isWeb) {
          content = FittedBox(
            fit: BoxFit.cover,
            child: VideoThumbnail.url(
              url: e.original.url,
              checksum: e.original.checksum,
              key: key,
              height: 300,
              onError: onError,
            ),
          );
        } else {
          content = Container(
            color: inverted ? style.colors.primary : style.colors.secondary,
            child: Icon(
              Icons.video_file,
              size: 18,
              color: inverted ? style.colors.secondary : style.colors.primary,
            ),
          );
        }
      } else {
        content = Container(
          color: inverted ? style.colors.onPrimary : style.colors.secondary,
          child: SvgImage.asset(
            inverted ? 'assets/icons/file_dark.svg' : 'assets/icons/file.svg',
            width: 30,
            height: 30,
          ),
        );
      }
    }

    if (content != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
          width: 30,
          height: 30,
          child: content,
        ),
      );
    }

    return const SizedBox();
  }
}
