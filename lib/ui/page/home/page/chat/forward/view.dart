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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
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
import '/ui/page/home/widget/retry_image.dart';
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
    this.text,
    this.attachments = const [],
  }) : super(key: key);

  /// ID of the [Chat] the [quotes] are forwarded from.
  final ChatId from;

  /// [ChatItemQuote]s to be forwarded.
  final List<ChatItemQuote> quotes;

  /// Initial [String] to put in the send field.
  final String? text;

  /// Initial [Attachment]s to attach to the provided [quotes].
  final List<Attachment> attachments;

  /// Displays a [ChatForwardView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context,
    ChatId from,
    List<ChatItemQuote> quotes, {
    String? text,
    List<Attachment> attachments = const [],
  }) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
      modalConstraints: const BoxConstraints(maxWidth: 500),
      child: ChatForwardView(
        from: from,
        quotes: quotes,
        attachments: attachments,
        text: text,
      ),
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
        text: text,
        attachments: attachments,
      ),
      builder: (ChatForwardController c) {
        return Material(
          type: MaterialType.transparency,
          key: const Key('ChatForwardView'),
          child: Column(
            children: [
              const SizedBox(height: 25),
              Expanded(
                child: Scrollbar(
                  controller: c.scrollController,
                  child: Obx(() {
                    return ListView(
                      controller: c.scrollController,
                      shrinkWrap: true,
                      primary: false,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      children: [
                        ...c.chats.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: _chat(context, c, e),
                          ),
                        )
                      ],
                    );
                  }),
                ),
              ),
              ...c.quotes.map((e) => _forwardedMessage(context, c, e.item)),
              Obx(() {
                return Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.fromLTRB(4, 7, 4, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: c.attachments
                          .map((e) => _buildAttachment(c, e))
                          .toList(),
                    ),
                  ),
                );
              }),
              _sendField(context, c),
              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }

  /// Returns a [ListTile] with the provided [Chat]'s information.
  Widget _chat(
    BuildContext context,
    ChatForwardController c,
    RxChat chat,
  ) {
    TextStyle font17 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(color: Colors.black);
    bool selected = c.selectedChats.contains(chat.chat.value.id);

    return Container(
      key: Key('ChatForwardTile_${chat.chat.value.id}'),
      decoration: const BoxDecoration(
        color: Color(0XFFF0F2F6),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
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
            child: selected
                ? const CircleAvatar(
                    backgroundColor: Color(0xBB165084),
                    radius: 12,
                    child: Icon(Icons.check, color: Colors.white, size: 14),
                  )
                : const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 12,
                    child: SizedBox(width: 14, height: 14),
                  ),
          ),
        ),
        title: Obx(() => Text(chat.title.value, style: font17)),
        onTap: () {
          if (selected) {
            c.selectedChats.removeWhere((e) => e == chat.chat.value.id);
          } else {
            c.selectedChats.add(chat.chat.value.id);
          }
        },
      ),
    );
  }

  /// Returns a visual representation of the provided [item] to be forwarded.
  Widget _forwardedMessage(
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
            ),
            width: 50,
            height: 50,
            child: image == null
                ? const Icon(Icons.attach_file, size: 16)
                : RetryImage(
                    image.medium.url,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(4),
                  ),
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
  Widget _buildAttachment(ChatForwardController c, Attachment e) {
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
                  : RetryImage(
                      e.original.url,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
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

  /// Returns a [ReactiveTextField] for constructing a [ChatMessage] to attach
  /// to the [quotes] to be forwarded.
  Widget _sendField(BuildContext context, ChatForwardController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
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
                  openedIcon:
                      const Icon(Icons.close, color: Colors.blue, size: 30),
                  height: PlatformUtils.isMobile && !PlatformUtils.isWeb
                      ? PlatformUtils.isIOS
                          ? 220
                          : 280
                      : 100,
                  actions: [
                    AnimatedFabAction(
                      icon: const Icon(Icons.attachment, color: Colors.blue),
                      label: 'label_file'.l10n,
                      onTap: c.send.editable.value ? c.pickFile : null,
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
                    key: const Key('ForwardField'),
                    state: c.send,
                    hint: 'label_send_message_hint'.l10n,
                    minLines: 1,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 17),
                    type: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => _button(
                  key: const Key('SendForward'),
                  icon: const AnimatedSwitcher(
                    duration: Duration(milliseconds: 150),
                    child: Padding(
                      padding: EdgeInsets.only(left: 2, top: 1),
                      child: Icon(Icons.send, size: 24),
                    ),
                  ),
                  onTap: c.selectedChats.isEmpty
                      ? null
                      : () {
                          c.send.submit();
                          Navigator.of(context).pop(true);
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
