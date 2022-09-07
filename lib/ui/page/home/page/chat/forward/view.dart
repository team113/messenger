// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'dart:io';
import 'dart:ui';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';
import 'package:messenger/ui/page/call/widget/round_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/init_callback.dart';
import 'package:messenger/ui/page/home/page/chat/widget/my_dismissible.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/chat/forward/controller.dart';
import '/ui/page/home/page/chat/widget/animated_fab.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class ChatForwardView extends StatelessWidget {
  const ChatForwardView({
    Key? key,
    required this.from,
    required this.quotes,
  }) : super(key: key);

  /// ID of the [Chat] the [quotes] are forwarded from.
  final ChatId from;

  /// [ChatItemQuote]s to be forwarded.
  final List<ChatItemQuote> quotes;

  /// Displays a [ChatForwardView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context,
    ChatId from,
    List<ChatItemQuote> quotes,
  ) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      mobilePadding: const EdgeInsets.all(0),
      desktopPadding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: ChatForwardView(from: from, quotes: quotes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ChatForwardController(
        Get.find(),
        Get.find(),
        from: from,
        quotes: quotes,
      ),
      builder: (ChatForwardController c) {
        ThemeData theme = Theme.of(context);
        final TextStyle? thin =
            theme.textTheme.bodyText1?.copyWith(color: Colors.black);

        List<Widget> children = [
          Center(
            child: Text(
              'Forward message(s)'.l10n,
              style: thin?.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Obx(() {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ListView(
                  // shrinkWrap: true,
                  primary: false,
                  children: [
                    ...c.chats.map(
                      (e) {
                        bool selected =
                            c.selectedChats.contains(e.chat.value.id);
                        return _chat(
                          context,
                          chat: e,
                          onTap: () {
                            if (selected) {
                              c.selectedChats
                                  .removeWhere((m) => m == e.chat.value.id);
                            } else {
                              c.selectedChats.add(e.chat.value.id);
                            }
                          },
                          selected: c.selectedChats.contains(e.chat.value.id),
                        );
                      },
                    )
                  ],
                ),
              );
            }),
          ),
          // const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Theme(
              data: Theme.of(context).copyWith(
                shadowColor: const Color(0x55000000),
                iconTheme: const IconThemeData(color: Colors.blue),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  focusColor: Colors.white,
                  fillColor: Colors.white,
                  hoverColor: Colors.transparent,
                  filled: true,
                  isDense: true,
                  contentPadding: EdgeInsets.fromLTRB(
                    15,
                    PlatformUtils.isDesktop ? 30 : 23,
                    15,
                    0,
                  ),
                ),
              ),
              child: _sendField(context, c),
            ),
          ),
        ];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 16),
              ...children,
              // const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Returns a [ListTile] with the provided [Chat]'s information.
  Widget _chat(
    BuildContext context, {
    required RxChat chat,
    void Function()? onTap,
    bool selected = false,
  }) {
    Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 84,
        child: ContextMenuRegion(
          key: Key('ContextMenuRegion_${chat.chat.value.id}'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: style.cardRadius,
              border: style.cardBorder,
              color: Colors.transparent,
            ),
            child: Material(
              type: MaterialType.card,
              borderRadius: style.cardRadius,
              color: selected
                  ? const Color(0xFFD7ECFF).withOpacity(0.8)
                  : style.cardColor.darken(0.05),
              child: InkWell(
                borderRadius: style.cardRadius,
                onTap: onTap,
                hoverColor: selected
                    ? const Color(0x00D7ECFF)
                    : const Color(0xFFD7ECFF).withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                  child: Row(
                    children: [
                      AvatarWidget.fromRxChat(chat, radius: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chat.title.value,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: AnimatedSwitcher(
                          duration: 200.milliseconds,
                          child: selected
                              ? const CircleAvatar(
                                  backgroundColor: Color(0xFF63B4FF),
                                  radius: 12,
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                )
                              : const CircleAvatar(
                                  backgroundColor: Color(0xFFD7D7D7),
                                  radius: 12,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a visual representation of a [ChatController.repliedMessages].
  Widget _forwardedMessage(
    BuildContext context,
    ChatForwardController c,
    ChatItem item,
  ) {
    Style style = Theme.of(context).extension<Style>()!;
    bool fromMe = item.authorId == c.me;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      var desc = StringBuffer();

      if (item.text != null) {
        desc.write(item.text!.val);
      }

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
              image: image == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage('${Config.url}/files${image.small}'),
                    ),
            ),
            width: 30,
            height: 30,
            child: image == null
                ? Icon(
                    Icons.file_copy,
                    color: fromMe ? Colors.white : const Color(0xFFDDDDDD),
                    size: 16,
                  )
                : null,
          );
        }).toList();
      }

      if (desc.isNotEmpty) {
        content = Text(
          desc.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.boldBody,
        );
      }
    } else if (item is ChatCall) {
      String title = 'label_chat_call_ended'.l10n;
      String? time;
      bool fromMe = c.me == item.authorId;
      bool isMissed = false;

      if (item.finishReason == null && item.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.l10n;
      } else if (item.finishReason != null) {
        title = item.finishReason!.localizedString(fromMe) ?? title;
        isMissed = item.finishReason == ChatCallFinishReason.dropped ||
            item.finishReason == ChatCallFinishReason.unanswered;
        time = item.conversationStartedAt!.val
            .difference(item.finishedAt!.val)
            .localizedString();
      } else {
        title = item.authorId == c.me
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
                style: style.boldBody
                    .copyWith(color: const Color(0xFF888888), fontSize: 13),
              ),
            ),
          ],
        ],
      );
    } else if (item is ChatForward) {
      // TODO: Implement `ChatForward`.
      content = Text('Forwarded message', style: style.boldBody);
    } else if (item is ChatMemberInfo) {
      // TODO: Implement `ChatMemberInfo`.
      content = Text(item.action.toString(), style: style.boldBody);
    } else {
      content = Text('err_unknown'.l10n, style: style.boldBody);
    }

    return MouseRegion(
      opaque: false,
      onEnter: (d) => c.hoveredReply.value = item,
      onExit: (d) => c.hoveredReply.value = null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          // color: const Color(0xFFD8D8D8),
          // color: Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          // border: Border(left: BorderSide(width: 1, color: Color(0xFF63B4FF))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<RxUser?>(
                  future: c.getUser(item.authorId),
                  builder: (context, snapshot) {
                    Color color = snapshot.data?.user.value.id == c.me
                        ? const Color(0xFF63B4FF)
                        : AvatarWidget.colors[
                            (snapshot.data?.user.value.num.val.sum() ?? 3) %
                                AvatarWidget.colors.length];

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 2,
                            color: color,
                          ),
                        ),
                      ),
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<RxUser?>(
                            future: c.getUser(item.authorId),
                            builder: (context, snapshot) {
                              String? name;
                              if (snapshot.hasData) {
                                name = snapshot.data?.user.value.name?.val;
                                if (snapshot.data?.user.value != null) {
                                  return Obx(() {
                                    Color color =
                                        snapshot.data?.user.value.id == c.me
                                            ? const Color(0xFF63B4FF)
                                            : AvatarWidget.colors[snapshot
                                                    .data!.user.value.num.val
                                                    .sum() %
                                                AvatarWidget.colors.length];

                                    return Text(
                                        snapshot.data!.user.value.name?.val ??
                                            snapshot.data!.user.value.num.val,
                                        style: style.boldBody
                                            .copyWith(color: color));
                                  });
                                }
                              }

                              return Text(
                                name ?? '...',
                                style: style.boldBody
                                    .copyWith(color: const Color(0xFF63B4FF)),
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
            AnimatedSwitcher(
              duration: 200.milliseconds,
              child: c.hoveredReply.value == item || PlatformUtils.isMobile
                  ? WidgetButton(
                      key: const Key('CancelReplyButton'),
                      onPressed: () {
                        c.quotes.removeWhere((e) => e.item == item);
                        if (c.quotes.isEmpty) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        width: 15,
                        height: 15,
                        margin: const EdgeInsets.only(right: 4, top: 4),
                        child: Container(
                          key: const Key('Close'),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // color: Colors.black.withOpacity(0.05),
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
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a visual representation of the provided [item] to be forwarded.
  Widget _forwardedMessage2(
    BuildContext context,
    ChatForwardController c,
    ChatItem item,
  ) {
    Style style = Theme.of(context).extension<Style>()!;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      var desc = StringBuffer();

      if (item.text != null) {
        desc.write(item.text!.val);
      }

      if (item.attachments.isNotEmpty) {
        additional = item.attachments.map((a) {
          ImageAttachment? image = a is ImageAttachment ? a : null;
          return Container(
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: const Color(0XFFF0F2F6),
              borderRadius: BorderRadius.circular(4),
              image: image == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage('${Config.url}/files${image.small}'),
                    ),
            ),
            width: 50,
            height: 50,
            child:
                image == null ? const Icon(Icons.attach_file, size: 16) : null,
          );
        }).toList();
      }

      if (desc.isNotEmpty) {
        content = Text(
          desc.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.boldBody,
        );
      }
    } else if (item is ChatCall) {
      String title = 'label_chat_call_ended'.l10n;
      String? time;
      bool fromMe = c.me == item.authorId;
      bool isMissed = false;

      if (item.finishReason == null && item.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.l10n;
      } else if (item.finishReason != null) {
        title = item.finishReason!.localizedString(fromMe) ?? title;
        isMissed = item.finishReason == ChatCallFinishReason.dropped ||
            item.finishReason == ChatCallFinishReason.unanswered;
        time = item.conversationStartedAt!.val
            .difference(item.finishedAt!.val)
            .localizedString();
      } else {
        title = item.authorId == c.me
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
                style: style.boldBody
                    .copyWith(color: const Color(0xFF888888), fontSize: 13),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE2E2E2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<RxUser?>(
                key: Key('BuilderRxUser_${item.id}'),
                future: c.getUser(item.authorId),
                builder: (context, snapshot) {
                  Color color = item.authorId == c.me
                      ? const Color(0xFF63B4FF)
                      : AvatarWidget.colors[
                          (snapshot.data?.user.value.num.val.sum() ?? 3) %
                              AvatarWidget.colors.length];

                  return Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.reply, size: 30, color: color),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(width: 4, color: color),
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (snapshot.data != null)
                                Obx(() {
                                  return Text(
                                    snapshot.data!.user.value.name?.val ??
                                        snapshot.data!.user.value.num.val,
                                    style:
                                        style.boldBody.copyWith(color: color),
                                  );
                                })
                              else
                                Text(
                                  '...',
                                  style: style.boldBody.copyWith(color: color),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a visual representation of the provided [Attachment].
  Widget _buildAttachment(ChatForwardController c, Attachment e, bool grab) {
    bool isImage =
        (e is ImageAttachment || (e is LocalAttachment && e.file.isImage));

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFD8D8D8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: e is LocalAttachment
                  ? e.file.bytes == null
                      ? e.file.path == null
                          ? const Center(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : e.file.isSvg
                              ? SvgLoader.file(
                                  File(e.file.path!),
                                  width: 80,
                                  height: 80,
                                )
                              : Image.file(
                                  File(e.file.path!),
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                )
                      : e.file.isSvg
                          ? SvgLoader.bytes(
                              e.file.bytes!,
                              width: 80,
                              height: 80,
                            )
                          : Image.memory(
                              e.file.bytes!,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            )
                  : Image.network(
                      '${Config.url}/files${e.original}',
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 80,
                        height: 80,
                        child:
                            Center(child: Icon(Icons.error, color: Colors.red)),
                      ),
                    ),
            )
          else
            SizedBox(
              width: 80,
              height: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insert_drive_file_sharp),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      e.filename,
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Center(
            child: SizedBox(
              height: 30,
              width: 30,
              child: ElasticAnimatedSwitcher(
                child: e is LocalAttachment
                    ? e.status.value == SendingStatus.error
                        ? Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                          )
                        : const SizedBox()
                    : const SizedBox(),
              ),
            ),
          ),
          if (!c.send.status.value.isLoading)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 2, top: 3),
                child: InkWell(
                  key: const Key('RemovePickedFile'),
                  onTap: () => c.attachments.remove(e),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0x99FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.black, size: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Returns a [ReactiveTextField] for sending a message in this [Chat].
  Widget _sendField(BuildContext context, ChatForwardController c) {
    Style style = Theme.of(context).extension<Style>()!;
    const double iconSize = 22;
    return Container(
      key: const Key('ForwardField'),
      decoration: BoxDecoration(
        borderRadius: style.cardRadius,
        boxShadow: const [
          CustomBoxShadow(blurRadius: 8, color: Color(0x22000000)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            bool grab =
                (125 + 2) * c.attachments.length > constraints.maxWidth - 16;
            return Stack(
              children: [
                Obx(() {
                  bool expanded = c.attachments.isNotEmpty || true;
                  return ConditionalBackdropFilter(
                    condition: style.cardBlur > 0,
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    borderRadius: BorderRadius.only(
                      topLeft: style.cardRadius.topLeft,
                      topRight: style.cardRadius.topRight,
                    ),
                    child: AnimatedSizeAndFade(
                      fadeDuration: 400.milliseconds,
                      sizeDuration: 400.milliseconds,
                      fadeInCurve: Curves.ease,
                      fadeOutCurve: Curves.ease,
                      sizeCurve: Curves.ease,
                      child: !expanded
                          ? const SizedBox(height: 1, width: double.infinity)
                          : Container(
                              key: const Key('Attachments'),
                              width: double.infinity,
                              color: const Color(0xFFFBFBFB),
                              // color: const Color(0xFFFFFFFF).withOpacity(0.7),
                              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height /
                                              3,
                                    ),
                                    child: ReorderableListView(
                                      shrinkWrap: true,
                                      buildDefaultDragHandles:
                                          PlatformUtils.isMobile,
                                      onReorder: (int old, int to) {
                                        if (old < to) {
                                          --to;
                                        }

                                        final ChatItemQuote item =
                                            c.quotes.removeAt(old);
                                        c.quotes.insert(to, item);

                                        HapticFeedback.lightImpact();
                                      },
                                      proxyDecorator: (child, i, animation) {
                                        return AnimatedBuilder(
                                          animation: animation,
                                          builder: (
                                            BuildContext context,
                                            Widget? child,
                                          ) {
                                            final double t = Curves.easeInOut
                                                .transform(animation.value);
                                            final double elevation =
                                                lerpDouble(0, 6, t)!;
                                            final Color color = Color.lerp(
                                              const Color(0x00000000),
                                              const Color(0x33000000),
                                              t,
                                            )!;

                                            return InitCallback(
                                              initState:
                                                  HapticFeedback.selectionClick,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    CustomBoxShadow(
                                                      color: color,
                                                      blurRadius: elevation,
                                                    ),
                                                  ],
                                                ),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: child,
                                        );
                                      },
                                      reverse: true,
                                      padding:
                                          const EdgeInsets.fromLTRB(1, 0, 1, 0),
                                      children: c.quotes.map((e) {
                                        return ReorderableDragStartListener(
                                          key: Key('Handle_${e.item.id}'),
                                          enabled: !PlatformUtils.isMobile,
                                          index: c.quotes.indexOf(e),
                                          child: MyDismissible(
                                            key: Key('${e.item.id}'),
                                            direction:
                                                MyDismissDirection.horizontal,
                                            onDismissed: (_) {
                                              c.quotes.remove(e);
                                              if (c.quotes.isEmpty) {
                                                Navigator.of(context).pop();
                                              }
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 2,
                                              ),
                                              child: _forwardedMessage(
                                                context,
                                                c,
                                                e.item,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: MouseRegion(
                                      cursor: grab
                                          ? SystemMouseCursors.grab
                                          : MouseCursor.defer,
                                      opaque: false,
                                      child: ScrollConfiguration(
                                        behavior: MyCustomScrollBehavior(),
                                        child: SingleChildScrollView(
                                          clipBehavior: Clip.none,
                                          physics: grab
                                              ? null
                                              : const NeverScrollableScrollPhysics(),
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: c.attachments
                                                .map(
                                                  (e) => _buildAttachment(
                                                    c,
                                                    e,
                                                    grab,
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  );
                }),
              ],
            );
          }),
          ConditionalBackdropFilter(
            condition: style.cardBlur > 0,
            filter: ImageFilter.blur(
              sigmaX: style.cardBlur,
              sigmaY: style.cardBlur,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.zero,
              topRight: Radius.zero,
              bottomLeft: style.cardRadius.bottomLeft,
              bottomRight: style.cardRadius.bottomLeft,
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(color: style.cardColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!PlatformUtils.isMobile || PlatformUtils.isWeb)
                    WidgetButton(
                      onPressed: c.pickFile,
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: SvgLoader.asset(
                              'assets/icons/attach.svg',
                              height: iconSize,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    WidgetButton(
                      onPressed: () {
                        ModalPopup.show(
                          context: context,
                          mobileConstraints: const BoxConstraints(),
                          mobilePadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          desktopConstraints:
                              const BoxConstraints(maxWidth: 400),
                          child: _attachmentSelection(c),
                        );
                      },
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: SvgLoader.asset(
                              'assets/icons/attach.svg',
                              height: iconSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 5 + (PlatformUtils.isMobile ? 0 : 8),
                        bottom: 13,
                      ),
                      child: Transform.translate(
                        offset: Offset(0, PlatformUtils.isMobile ? 6 : 1),
                        child: ReactiveTextField(
                          key: const Key('ForwardField'),
                          state: c.send,
                          hint: 'label_send_message_hint'.l10n,
                          minLines: 1,
                          maxLines: 7,
                          filled: false,
                          dense: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          style: style.boldBody.copyWith(fontSize: 17),
                          type: PlatformUtils.isDesktop
                              ? TextInputType.text
                              : TextInputType.multiline,
                          textInputAction: PlatformUtils.isDesktop
                              ? TextInputAction.send
                              : TextInputAction.newline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 0),
                  Obx(() {
                    return WidgetButton(
                      onPressed: c.selectedChats.isEmpty
                          ? () {}
                          : () {
                              c.send.submit();
                              Navigator.of(context).pop();
                            },
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: SizedBox(
                              key: const Key('Send'),
                              width: 25.18,
                              height: 22.85,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: SvgLoader.asset(
                                  'assets/icons/send.svg',
                                  height: 22.85,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentSelection(ChatForwardController c) {
    return Builder(builder: (context) {
      Widget button({
        required String text,
        IconData? icon,
        Widget? child,
        void Function()? onPressed,
      }) {
        // TEXT MUST SCALE HORIZONTALLY!!!!!!!!
        return RoundFloatingButton(
          text: text,
          withBlur: false,
          onPressed: () {
            onPressed?.call();
            Navigator.of(context).pop();
          },
          textStyle: const TextStyle(
            fontSize: 15,
            color: Colors.black,
          ),
          autoSizeText: true,
          color: const Color(0xFF63B4FF),
          child: SizedBox(
            width: 60,
            height: 60,
            child: child ?? Icon(icon, color: Colors.white, size: 30),
          ),
        );
      }

      bool isAndroid = PlatformUtils.isAndroid;

      List<Widget> children = [
        button(
          text: isAndroid ? 'Фото' : 'Камера',
          onPressed: c.pickImageFromCamera,
          child: SvgLoader.asset(
            'assets/icons/make_photo.svg',
            width: 60,
            height: 60,
          ),
        ),
        if (isAndroid)
          button(
            text: 'Видео',
            onPressed: c.pickVideoFromCamera,
            child: SvgLoader.asset(
              'assets/icons/video_on.svg',
              width: 60,
              height: 60,
            ),
          ),
        button(
          text: 'Галерея',
          onPressed: c.pickMedia,
          child: SvgLoader.asset(
            'assets/icons/gallery.svg',
            width: 60,
            height: 60,
          ),
        ),
        button(
          text: 'Файл',
          onPressed: c.pickFile,
          child: SvgLoader.asset(
            'assets/icons/file.svg',
            width: 60,
            height: 60,
          ),
        ),
      ];

      // MAKE SIZE MINIMUM.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
          const SizedBox(height: 40),
          OutlinedRoundedButton(
            key: const Key('CloseButton'),
            title: Text('btn_close'.l10n),
            onPressed: Navigator.of(context).pop,
            color: const Color(0xFFEEEEEE),
          ),
          const SizedBox(height: 10),
        ],
      );
    });
  }

  /// Returns a [ReactiveTextField] for constructing a [ChatMessage] to attach
  /// to the [quotes] to be forwarded.
  // Widget _sendField(BuildContext context, ChatForwardController c) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 8),
  //     child: Container(
  //       decoration: const BoxDecoration(
  //         color: Color(0xFFFFFFFF),
  //         borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
  //       ),
  //       padding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
  //       child: SafeArea(
  //         child: Row(
  //           crossAxisAlignment: CrossAxisAlignment.end,
  //           children: [
  //             Padding(
  //               padding: const EdgeInsets.only(bottom: 0.5),
  //               child: AnimatedFab(
  //                 labelStyle: const TextStyle(fontSize: 17),
  //                 closedIcon: const Icon(
  //                   Icons.more_horiz,
  //                   color: Colors.blue,
  //                   size: 30,
  //                 ),
  //                 openedIcon:
  //                     const Icon(Icons.close, color: Colors.blue, size: 30),
  //                 height: PlatformUtils.isMobile && !PlatformUtils.isWeb
  //                     ? PlatformUtils.isIOS
  //                         ? 220
  //                         : 280
  //                     : 100,
  //                 actions: [
  //                   AnimatedFabAction(
  //                     icon: const Icon(Icons.attachment, color: Colors.blue),
  //                     label: 'label_file'.l10n,
  //                     onTap: c.send.editable.value ? c.pickFile : null,
  //                   ),
  //                   if (PlatformUtils.isMobile && !PlatformUtils.isWeb) ...[
  //                     AnimatedFabAction(
  //                       icon: const Icon(Icons.photo, color: Colors.blue),
  //                       label: 'label_gallery'.l10n,
  //                     ),
  //                     if (PlatformUtils.isAndroid) ...[
  //                       AnimatedFabAction(
  //                         icon: const Icon(
  //                           Icons.photo_camera,
  //                           color: Colors.blue,
  //                         ),
  //                         label: 'label_photo'.l10n,
  //                       ),
  //                       AnimatedFabAction(
  //                         icon: const Icon(
  //                           Icons.video_camera_back,
  //                           color: Colors.blue,
  //                         ),
  //                         label: 'label_video'.l10n,
  //                       ),
  //                     ],
  //                     if (PlatformUtils.isIOS)
  //                       AnimatedFabAction(
  //                         icon: const Icon(
  //                           Icons.camera,
  //                           color: Colors.blue,
  //                         ),
  //                         label: 'label_camera'.l10n,
  //                       ),
  //                   ],
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             Expanded(
  //               child: Material(
  //                 elevation: 6,
  //                 borderRadius: BorderRadius.circular(25),
  //                 child: ReactiveTextField(
  //                   key: const Key('ForwardField'),
  //                   state: c.send,
  //                   hint: 'label_send_message_hint'.l10n,
  //                   minLines: 1,
  //                   maxLines: 6,
  //                   style: const TextStyle(fontSize: 17),
  //                   type: PlatformUtils.isDesktop
  //                       ? TextInputType.text
  //                       : TextInputType.multiline,
  //                   textInputAction: TextInputAction.send,
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             _button(
  //               key: const Key('SendForward'),
  //               icon: const AnimatedSwitcher(
  //                 duration: Duration(milliseconds: 150),
  //                 child: Padding(
  //                   padding: EdgeInsets.only(left: 2, top: 1),
  //                   child: Icon(Icons.send, size: 24),
  //                 ),
  //               ),
  //               onTap: () {
  //                 c.send.submit();
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  /// Returns an [InkWell] circular button with the provided [icon].
  Widget _button({
    Key? key,
    void Function()? onTap,
    required Widget icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.5),
      child: Material(
        type: MaterialType.circle,
        color: Colors.white,
        elevation: 6,
        child: InkWell(
          key: key,
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            width: 42,
            height: 42,
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}
