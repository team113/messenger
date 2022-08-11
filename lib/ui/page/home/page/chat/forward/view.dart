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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.graphql.dart';
import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/chat/forward/controller.dart';
import '/ui/page/home/page/chat/widget/animated_fab.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';

/// View of the forward messages modal.
class ChatForwardView extends StatelessWidget {
  const ChatForwardView({
    Key? key,
    required this.fromId,
    required this.forwardItem,
  }) : super(key: key);

  /// [ChatId] of the chat from where forward is sending.
  final ChatId fromId;

  /// Quote of the [ChatItem] to be forwarded.
  final ChatItemQuote forwardItem;

  /// Displays a [ChatForwardView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context,
    ChatId fromId,
    ChatItemQuote forwardItem,
  ) {
    return ModalPopup.show(
        context: context,
        desktopConstraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        modalConstraints: const BoxConstraints(maxWidth: 500),
        child: ChatForwardView(fromId: fromId, forwardItem: forwardItem));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: ChatForwardController(
          Get.find(),
          Get.find(),
          fromId,
          forwardItem,
        ),
        builder: (ChatForwardController c) {
          return Material(
            color: const Color(0XFFF0F2F6),
            child: Column(
              children: [
                const SizedBox(
                  height: 25,
                ),
                Expanded(
                  child: Obx(
                    () => ListView(
                      shrinkWrap: true,
                      primary: false,
                      children: [
                        ...c.chats.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 15),
                            child: _chat(
                              context,
                              c,
                              e,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                _forwardMessage(context, c, c.forwardItem.item),
                _sendField(context, c),
                const SizedBox(
                  height: 5,
                )
              ],
            ),
          );
        });
  }
}

/// Returns [ListTile] with [Chat]'s information.
Widget _chat(
  BuildContext context,
  ChatForwardController c,
  RxChat chat,
) {
  TextStyle font17 = context.theme.outlinedButtonTheme.style!.textStyle!
      .resolve({MaterialState.disabled})!.copyWith(color: Colors.black);
  return Container(
    decoration: const BoxDecoration(
        color: Color(0XFFD9D9D9),
        borderRadius: BorderRadius.all(Radius.circular(10))),
    padding: const EdgeInsets.all(5),
    child: ListTile(
        leading: AvatarWidget.fromChat(
          chat.chat.value,
          chat.title.value,
          chat.avatar.value,
          c.me,
        ),
        trailing: SizedBox(
          width: 30,
          height: 30,
          child: AnimatedSwitcher(
              duration: 200.milliseconds,
              child: (c.selectedChats
                          .firstWhereOrNull((e) => e == chat.chat.value.id) !=
                      null)
                  ? const CircleAvatar(
                      backgroundColor: Color(0xBB165084),
                      radius: 12,
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    )
                  : const CircleAvatar(
                      backgroundColor: Color(0XFFF0F2F6),
                      radius: 12,
                      child: SizedBox(
                        width: 14,
                        height: 14,
                      ))),
        ),
        title: Text(chat.title(), style: font17),
        onTap: () {
          if (c.selectedChats
                  .firstWhereOrNull((e) => e == chat.chat.value.id) !=
              null) {
            c.selectedChats.removeWhere((e) => e == chat.chat.value.id);
          } else {
            c.selectedChats.add(chat.chat.value.id);
          }
        }),
  );
}

Widget _forwardMessage(
    BuildContext context, ChatForwardController c, ChatItem item) {
  Style style = Theme.of(context).extension<Style>()!;
  Widget? content;
  List<Widget> additional = [];

  if (item is ChatMessage) {
    var desc = StringBuffer();

    if (item.text != null) {
      desc.write(item.text!.val);
    } else if (item.attachments.isNotEmpty) {}

    if (item.attachments.isNotEmpty) {
      additional = item.attachments.map((a) {
        ImageAttachment? image;

        if (a is ImageAttachment) {
          image = a;
        }

        return Container(
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
              color: const Color(0xFFE2E2E2),
              borderRadius: BorderRadius.circular(4),
              image: image == null
                  ? null
                  : DecorationImage(
                      image:
                          NetworkImage('${Config.url}/files${image.small}'))),
          width: 30,
          height: 30,
          child: image == null ? const Icon(Icons.attach_file, size: 16) : null,
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

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
      decoration: const BoxDecoration(
          color: Color(0xFFE2E2E2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FutureBuilder<RxUser?>(
                future: c.getUser(item.authorId),
                builder: (context, snapshot) {
                  Color color = AvatarWidget.colors[
                      (snapshot.data?.user.value.num.val.sum() ?? 3) %
                          AvatarWidget.colors.length];

                  return Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.reply,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                width: 4,
                                color: color,
                              ),
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
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
                                        Color color = AvatarWidget.colors[
                                            snapshot.data!.user.value.num.val
                                                    .sum() %
                                                AvatarWidget.colors.length];

                                        return Text(
                                            snapshot.data!.user.value.name
                                                    ?.val ??
                                                snapshot
                                                    .data!.user.value.num.val,
                                            style: style.boldBody
                                                .copyWith(color: color));
                                      });
                                    }
                                  }

                                  return Text(
                                    name ?? '...',
                                    style: style.boldBody.copyWith(
                                        color: const Color(0xFF63B4FF)),
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
                        ),
                      ),
                    ],
                  );
                }),
          ),
        ],
      ),
    ),
  );
}

/// Returns a [ReactiveTextField] for sending a message in this [Chat].
Widget _sendField(BuildContext context, ChatForwardController c) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
      decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))),
      padding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 0.5),
              child: AnimatedFab(
                labelStyle: const TextStyle(fontSize: 17),
                closedIcon: const Icon(
                  Icons.more_horiz,
                  color: Colors.blue,
                  size: 30,
                ),
                openedIcon: const Icon(
                  Icons.close,
                  color: Colors.blue,
                  size: 30,
                ),
                height: PlatformUtils.isMobile && !PlatformUtils.isWeb
                    ? PlatformUtils.isIOS
                        ? 340
                        : 380
                    : 220,
                actions: [
                  AnimatedFabAction(
                    icon: const Icon(Icons.call, color: Colors.blue),
                    label: 'label_audio_call'.l10n,
                    noAnimation: true,
                  ),
                  AnimatedFabAction(
                    icon: const Icon(Icons.video_call, color: Colors.blue),
                    label: 'label_video_call'.l10n,
                    noAnimation: true,
                  ),
                  AnimatedFabAction(
                    icon: const Icon(Icons.attachment, color: Colors.blue),
                    label: 'label_file'.l10n,
                  ),
                  if (PlatformUtils.isMobile && !PlatformUtils.isWeb) ...[
                    AnimatedFabAction(
                      icon: const Icon(Icons.photo, color: Colors.blue),
                      label: 'label_gallery'.l10n,
                    ),
                    if (PlatformUtils.isAndroid) ...[
                      AnimatedFabAction(
                        icon: const Icon(
                          Icons.photo_camera,
                          color: Colors.blue,
                        ),
                        label: 'label_photo'.l10n,
                      ),
                      AnimatedFabAction(
                        icon: const Icon(
                          Icons.video_camera_back,
                          color: Colors.blue,
                        ),
                        label: 'label_video'.l10n,
                      ),
                    ],
                    if (PlatformUtils.isIOS)
                      AnimatedFabAction(
                        icon: const Icon(
                          Icons.camera,
                          color: Colors.blue,
                        ),
                        label: 'label_camera'.l10n,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(25),
                child: ReactiveTextField(
                  key: const Key('MessageField'),
                  state: c.sendForward,
                  hint: 'label_send_message_hint'.l10n,
                  minLines: 1,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 17),
                  type: PlatformUtils.isDesktop
                      ? TextInputType.text
                      : TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _button(
              icon: const AnimatedSwitcher(
                duration: Duration(milliseconds: 150),
                child: Padding(
                  key: Key('Send'),
                  padding: EdgeInsets.only(left: 2, top: 1),
                  child: Icon(Icons.send, size: 24),
                ),
              ),
              onTap: () {
                c.sendForward.submit();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Returns an [InkWell] circular button with an [icon].
Widget _button({
  void Function()? onTap,
  required Widget icon,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 0.5),
      child: Material(
        type: MaterialType.circle,
        color: Colors.white,
        elevation: 6,
        child: InkWell(
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
