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

import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/fluent/extension.dart';
import '/routes.dart';
import '/ui/page/call/widget/animated_dots.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/animated_fab.dart';
import 'widget/back_button.dart';
import 'widget/chat_item.dart';
import 'widget/swipeable_status.dart';

/// View of the [Routes.chat] page.
class ChatView extends StatefulWidget {
  const ChatView(this.id, {Key? key}) : super(key: key);

  /// ID of this [Chat].
  final ChatId id;

  @override
  State<ChatView> createState() => _ChatViewState();
}

/// State of a [ChatView] used to animate [SwipeableStatus].
class _ChatViewState extends State<ChatView>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] of [SwipeableStatus]es.
  late final AnimationController _animation;

  @override
  void initState() {
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      init: ChatController(
        widget.id,
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      tag: widget.id.val,
      builder: (c) => Obx(
        () {
          if (c.status.value.isSuccess) {
            Chat chat = c.chat!.chat.value;

            // Opens [Routes.chatInfo] or [Routes.user] page basing on the
            // [Chat.isGroup] indicator.
            void onDetailsTap() {
              if (chat.isGroup) {
                router.chatInfo(widget.id);
              } else if (chat.members.isNotEmpty) {
                router.user(
                  chat.members
                          .firstWhereOrNull((e) => e.user.id != c.me)
                          ?.user
                          .id ??
                      chat.members.first.user.id,
                  push: true,
                );
              }
            }

            return DropTarget(
              onDragDone: (details) => c.dropFiles(details),
              onDragEntered: (_) => c.isDraggingFiles.value = true,
              onDragExited: (_) => c.isDraggingFiles.value = false,
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Stack(
                  children: [
                    Scaffold(
                      backgroundColor: const Color(0xFFF6F6F6),
                      resizeToAvoidBottomInset: true,
                      appBar: PreferredSize(
                        preferredSize: const Size(double.infinity, 57),
                        child: Column(
                          children: [
                            AppBar(
                              centerTitle: true,
                              backgroundColor: const Color(0xFFF6F6F6),
                              titleSpacing: 0,
                              elevation: 0,
                              automaticallyImplyLeading: false,
                              leading: const StyledBackButton(),
                              title: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                child: InkWell(
                                  splashFactory: NoSplash.splashFactory,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: onDetailsTap,
                                  child: Column(
                                    children: [
                                      Text(
                                        c.chat!.title.value,
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      _chatSubtitle(c),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                if (!context.isMobile) ...[
                                  IconButton(
                                    onPressed: () => c.call(true),
                                    icon: const Icon(Icons.video_call,
                                        color: Colors.blue),
                                  ),
                                  IconButton(
                                    onPressed: () => c.call(false),
                                    icon: const Icon(Icons.call,
                                        color: Colors.blue),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Material(
                                    elevation: 6,
                                    type: MaterialType.circle,
                                    shadowColor: const Color(0x55000000),
                                    color: Colors.white,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: onDetailsTap,
                                      child: AvatarWidget.fromRxChat(
                                        c.chat,
                                        radius: 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: double.infinity,
                              color: const Color(0xFFE0E0E0),
                              height: 0.5,
                            ),
                          ],
                        ),
                      ),
                      body: Listener(
                        onPointerSignal: (s) {
                          if (s is PointerScrollEvent) {
                            if (s.scrollDelta.dy.abs() < 3 &&
                                (s.scrollDelta.dx.abs() > 3 ||
                                    c.horizontalScrollTimer.value != null)) {
                              double value =
                                  _animation.value + s.scrollDelta.dx / 100;
                              _animation.value = value.clamp(0, 1);

                              if (_animation.value == 0 ||
                                  _animation.value == 1) {
                                _resetHorizontalScroll(c, 100.milliseconds);
                              } else {
                                _resetHorizontalScroll(c);
                              }
                            }
                          }
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragUpdate: (d) {
                            double value = _animation.value - d.delta.dx / 100;
                            _animation.value = value.clamp(0, 1);
                          },
                          onHorizontalDragEnd: (d) {
                            if (_animation.value >= 0.5) {
                              _animation.forward();
                            } else {
                              _animation.reverse();
                            }
                          },
                          child: Stack(
                            children: [
                              // Required for the [Stack] to take [Scaffold]'s size.
                              IgnorePointer(
                                child:
                                    ContextMenuInterceptor(child: Container()),
                              ),
                              SafeArea(
                                child: FlutterListView(
                                  key: const Key('MessagesList'),
                                  controller: c.listController,
                                  physics: c.horizontalScrollTimer.value == null
                                      ? const BouncingScrollPhysics()
                                      : const NeverScrollableScrollPhysics(),
                                  delegate: FlutterListViewDelegate(
                                    (BuildContext context, int i) {
                                      List<Widget> widgets = [];
                                      Rx<ChatItem> e = c.chat!.messages[i];

                                      if (c.lastReadItem.value == e) {
                                        widgets.add(
                                          Container(
                                            color: const Color(0x33000000),
                                            padding: const EdgeInsets.all(4),
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'label_unread_messages'.td(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      Widget widget = Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: FutureBuilder<Rx<User>?>(
                                          future: c.getUser(e.value.authorId),
                                          builder: (_, u) => ChatItemWidget(
                                            key: Key(e.value.id.val),
                                            chat: c.chat!.chat,
                                            item: e,
                                            me: c.me!,
                                            user: u.data,
                                            onJoinCall: c.joinCall,
                                            onHide: () =>
                                                c.hideChatItem(e.value),
                                            onDelete: () =>
                                                c.deleteMessage(e.value),
                                            onReply: () => c
                                                .repliedMessage.value = e.value,
                                            onCopy: (text) => c.copyText(text),
                                            onRepliedTap: (id) =>
                                                c.animateTo(id),
                                            animation: _animation,
                                            onGallery: c.calculateGallery,
                                            onEdit: () =>
                                                c.editMessage(e.value),
                                          ),
                                        ),
                                      );

                                      if (e.value.authorId != c.me &&
                                          !chat.isReadBy(e.value, c.me) &&
                                          c.status.value.isSuccess &&
                                          !c.status.value.isLoadingMore) {
                                        widget = VisibilityDetector(
                                          key:
                                              Key('Detector_${e.value.id.val}'),
                                          onVisibilityChanged: (info) {
                                            if (info.visibleFraction > 0) {
                                              if (c.lastVisibleItem.value?.at
                                                      .isBefore(e.value.at) !=
                                                  false) {
                                                c.lastVisibleItem.value =
                                                    e.value;
                                              }
                                            }
                                          },
                                          child: widget,
                                        );
                                      }

                                      if (i == 0) {
                                        // Display a time over the first message.
                                        widgets.add(_timeLabel(e.value.at.val));
                                      } else {
                                        Rx<ChatItem>? previous =
                                            c.chat?.messages[i - 1];

                                        // Display a time if difference between
                                        // messages is more than 30 minutes.
                                        if (previous != null) {
                                          if (previous.value.at.val
                                                  .difference(e.value.at.val)
                                                  .inMinutes <
                                              -30) {
                                            widgets.add(
                                                _timeLabel(e.value.at.val));
                                          }
                                        }
                                      }

                                      widgets.add(widget);

                                      return Padding(
                                        padding: EdgeInsets.zero,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: widgets,
                                        ),
                                      );
                                    },
                                    childCount: c.chat?.messages.length,
                                    initIndex: c.initIndex,
                                    initOffset: c.initOffset,
                                    initOffsetBasedOnBottom: false,
                                    keepPosition: true,
                                    onItemKey: (i) =>
                                        c.chat!.messages[i].value.id.val,
                                  ),
                                ),
                              ),
                              if ((c.chat!.status.value.isSuccess ||
                                      c.chat!.status.value.isEmpty) &&
                                  c.chat!.messages.isEmpty)
                                const Center(child: Text('No messages')),
                              if (c.chat!.status.value.isLoading)
                                const Center(child: CircularProgressIndicator())
                            ],
                          ),
                        ),
                      ),
                      floatingActionButton: Obx(
                        () => SizedBox(
                          width: 50,
                          height: 50,
                          child: AnimatedSwitcher(
                            duration: 200.milliseconds,
                            child: c.chat!.status.value.isLoadingMore
                                ? const CircularProgressIndicator()
                                : c.canGoBack.isTrue
                                    ? FloatingActionButton(
                                        onPressed: c.animateToBack,
                                        child: const Icon(Icons.arrow_upward),
                                      )
                                    : c.canGoDown.isTrue
                                        ? FloatingActionButton(
                                            onPressed: c.animateToBottom,
                                            child: const Icon(
                                                Icons.arrow_downward),
                                          )
                                        : Container(),
                          ),
                        ),
                      ),
                      bottomNavigationBar: _bottomBar(c, context),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: c.isDraggingFiles.value
                          ? Container(
                              color: Colors.white.withOpacity(0.9),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.upload_file,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'label_drop_here'.td(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          } else if (c.status.value.isEmpty) {
            return Scaffold(
              body: Center(child: Text('label_no_chat_found'.td())),
            );
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }

  /// Returns a header subtitle of the [Chat].
  Widget _chatSubtitle(ChatController c) {
    final TextStyle style = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 13,
    );

    return Obx(
      () {
        var chat = c.chat!.chat;

        if (chat.value.isGroup) {
          var subtitle = chat.value.getSubtitle();
          if (subtitle != null) {
            return Text(
              subtitle,
              style: style,
            );
          }
        } else if (chat.value.isDialog) {
          var partner =
              chat.value.members.firstWhereOrNull((u) => u.user.id != c.me);
          if (partner != null) {
            return FutureBuilder<Rx<User>?>(
              future: c.getUser(partner.user.id),
              builder: (_, snapshot) {
                var subtitle = c.chat!.chat.value.getSubtitle(
                  partner: snapshot.data?.value,
                );

                if (subtitle != null) {
                  return Text(
                    subtitle,
                    style: style,
                  );
                }

                return Container();
              },
            );
          }
        }

        return Container();
      },
    );
  }

  /// Returns a centered [time] label.
  Widget _timeLabel(DateTime time) {
    return Column(
      children: [
        const SizedBox(height: 7),
        SwipeableStatus(
          animation: _animation,
          asStack: true,
          padding: EdgeInsets.zero,
          crossAxisAlignment: CrossAxisAlignment.center,
          swipeable: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(DateFormat('dd.MM.yy').format(time)),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white,
              ),
              child: Text(
                time.toRelative(),
                style: const TextStyle(color: Color(0xFF888888)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
      ],
    );
  }

  /// Returns a bottom bar of this [ChatView] to display under the messages list
  /// containing a send/edit field.
  Widget _bottomBar(ChatController c, BuildContext context) {
    return Theme(
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _typingUsers(c),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: c.editedMessage.value == null
                ? [
                    if (c.repliedMessage.value != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(height: 18, width: 2, color: Colors.blue),
                            const SizedBox(width: 4),
                            Flexible(child: _repliedMessage(c)),
                            IconButton(
                              key: const Key('CancelReplyButton'),
                              onPressed: () => c.repliedMessage.value = null,
                              icon: const Icon(Icons.clear, size: 18),
                            )
                          ],
                        ),
                      ),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 7, right: 4, left: 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: c.attachments
                              .map((e) => _buildAttachment(c, e))
                              .toList(),
                        ),
                      ),
                    ),
                    _sendField(c),
                  ]
                : [
                    _editedMessage(c),
                    _editField(c),
                  ],
          ),
        ],
      ),
    );
  }

  /// Returns a [ReactiveTextField] for sending a message in this [Chat].
  Widget _sendField(ChatController c) {
    return Container(
      color: const Color(0xFFF6F6F6),
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
                    label: 'label_audio_call'.td(),
                    onTap: () => c.call(false),
                    noAnimation: true,
                  ),
                  AnimatedFabAction(
                    icon: const Icon(Icons.video_call, color: Colors.blue),
                    label: 'label_video_call'.td(),
                    onTap: () => c.call(true),
                    noAnimation: true,
                  ),
                  AnimatedFabAction(
                    icon: const Icon(Icons.attachment, color: Colors.blue),
                    label: 'label_file'.td(),
                    onTap: c.send.editable.value ? c.pickFile : null,
                  ),
                  if (PlatformUtils.isMobile && !PlatformUtils.isWeb) ...[
                    AnimatedFabAction(
                      icon: const Icon(Icons.photo, color: Colors.blue),
                      label: 'label_gallery'.td(),
                      onTap: c.send.editable.value ? c.pickMedia : null,
                    ),
                    if (PlatformUtils.isAndroid) ...[
                      AnimatedFabAction(
                        icon: const Icon(
                          Icons.photo_camera,
                          color: Colors.blue,
                        ),
                        label: 'label_photo'.td(),
                        onTap: c.pickImageFromCamera,
                      ),
                      AnimatedFabAction(
                        icon: const Icon(
                          Icons.video_camera_back,
                          color: Colors.blue,
                        ),
                        label: 'label_video'.td(),
                        onTap: c.pickVideoFromCamera,
                      ),
                    ],
                    if (PlatformUtils.isIOS)
                      AnimatedFabAction(
                        icon: const Icon(
                          Icons.camera,
                          color: Colors.blue,
                        ),
                        label: 'label_camera'.td(),
                        onTap: c.pickImageFromCamera,
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
                  onChanged: c.keepTyping,
                  key: const Key('MessageField'),
                  state: c.send,
                  hint: 'label_send_message_hint'.td(),
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
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: (c.send.isEmpty.value && c.attachments.isEmpty)
                    ? const Padding(
                        key: Key('Mic'),
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.mic),
                      )
                    : const Padding(
                        key: Key('Send'),
                        padding: EdgeInsets.only(left: 2, top: 1),
                        child: Icon(Icons.send, size: 24),
                      ),
              ),
              onTap: (c.send.isEmpty.value && c.attachments.isEmpty)
                  ? () {}
                  : c.send.submit,
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a [ReactiveTextField] for editing a [ChatMessage].
  Widget _editField(ChatController c) {
    return Container(
      color: const Color(0xFFF6F6F6),
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
                height: 150,
                actions: [
                  AnimatedFabAction(
                    icon: const Icon(Icons.call, color: Colors.blue),
                    label: 'label_audio_call'.td(),
                    onTap: () => c.call(false),
                    noAnimation: true,
                  ),
                  AnimatedFabAction(
                    icon: const Icon(Icons.video_call, color: Colors.blue),
                    label: 'label_video_call'.td(),
                    onTap: () => c.call(true),
                    noAnimation: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(25),
                child: ReactiveTextField(
                  key: const Key('MessageEditField'),
                  state: c.edit!,
                  hint: 'label_edit_message_hint'.td(),
                  minLines: 1,
                  maxLines: 6,
                  onChanged: c.keepTyping,
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
              icon: Icon(
                Icons.save,
                key: const Key('Save'),
                color: c.edit!.status.value.isEmpty ? null : Colors.grey,
                size: 24,
              ),
              onTap: c.edit!.status.value.isEmpty ? c.edit?.submit : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a visual representation of the provided [AttachmentData].
  Widget _buildAttachment(ChatController c, AttachmentData data) {
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
          data.file.isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: data.file.bytes == null
                      ? data.file.path == null
                          ? const SizedBox(
                              width: 80,
                              height: 80,
                              child: SizedBox(
                                height: 40,
                                width: 40,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : data.file.isSvg
                              ? SvgLoader.file(
                                  File(data.file.path!),
                                  width: 100,
                                  height: 100,
                                )
                              : Image.file(
                                  File(data.file.path!),
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                )
                      : data.file.isSvg
                          ? SvgLoader.bytes(
                              data.file.bytes!,
                              width: 100,
                              height: 100,
                            )
                          : Image.memory(
                              data.file.bytes!,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                )
              : SizedBox(
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
                          data.file.name,
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
                child:
                    data.upload.value != null && c.send.status.value.isLoading
                        ? CircularProgressIndicator(
                            value: data.progress.value,
                          )
                        : data.hasError.value
                            ? Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                ),
                              )
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
                  onTap: () => c.attachments.remove(data),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0x99FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Returns a [Row] of [RxChat.typingUsers].
  Widget _typingUsers(ChatController c) {
    return Obx(() {
      bool isTyping = c.chat?.typingUsers.any((e) => e.id != c.me) == true;
      if (isTyping) {
        Iterable<String> typings = c.chat!.typingUsers
            .where((e) => e.id != c.me)
            .map((e) => e.name?.val ?? e.num.val);
        return Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.edit, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  typings.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Text(typings.length > 1
                  ? 'label_typings'.td()
                  : 'label_typing'.td()),
              const AnimatedDots(color: Colors.black)
            ],
          ),
        );
      } else {
        return Container();
      }
    });
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

  /// Builds a visual representation of a [ChatController.repliedMessage].
  Widget _repliedMessage(ChatController c) {
    var item = c.repliedMessage.value;

    if (item is ChatMessage) {
      var desc = StringBuffer();

      if (item.text != null) {
        desc.write(item.text!.val);
        if (item.attachments.isNotEmpty) {
          desc.write(
              ' [${item.attachments.length} ${'label_attachments'.td()}]');
        }
      } else if (item.attachments.isNotEmpty) {
        desc.write('${item.attachments.length} ${'label_attachments'.td()}]');
      }

      return Text(
        desc.toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else if (item is ChatCall) {
      String title = 'label_chat_call_ended'.td();
      String? time;
      bool fromMe = c.me == item.authorId;
      bool isMissed = false;

      if (item.finishReason == null && item.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.td();
      } else if (item.finishReason != null) {
        title = item.finishReason!.localizedString(fromMe) ?? title;
        isMissed = item.finishReason == ChatCallFinishReason.dropped ||
            item.finishReason == ChatCallFinishReason.unanswered;
        time = item.conversationStartedAt!.val
            .difference(item.finishedAt!.val)
            .localizedString();
      } else {
        title = item.authorId == c.me
            ? 'label_outgoing_call'.td()
            : 'label_incoming_call'.td();
      }

      return Row(
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
          Flexible(child: Text(title)),
          if (time != null) ...[
            const SizedBox(width: 9),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
            ),
          ],
        ],
      );
    } else if (item is ChatForward) {
      // TODO: Implement `ChatForward`.
      return const Text('Forwarded message');
    } else if (item is ChatMemberInfo) {
      // TODO: Implement `ChatMemberInfo`.
      return Text(item.action.toString());
    } else {
      return Text('err_unknown'.td());
    }
  }

  /// Builds a visual representation of a [ChatController.editedMessage].
  Widget _editedMessage(ChatController c) {
    if (c.editedMessage.value != null && c.edit != null) {
      if (c.editedMessage.value is ChatMessage) {
        final msg = c.editedMessage.value as ChatMessage;

        var desc = StringBuffer();

        if (msg.text != null) {
          desc.write(msg.text!.val);
          if (msg.attachments.isNotEmpty) {
            desc.write(
                ' [${msg.attachments.length} ${'label_attachments'.td()}]');
          }
        } else if (msg.attachments.isNotEmpty) {
          desc.write('[${msg.attachments.length} ${'label_attachments'.td()}]');
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(
                Icons.edit_rounded,
                size: 24,
              ),
              Container(
                height: 25,
                width: 2,
                color: Colors.blue,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: InkWell(
                  splashFactory: NoSplash.splashFactory,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () => c.animateTo(msg.id, offsetBasedOnBottom: true),
                  child: RichText(
                    text: TextSpan(
                      text: '${'label_edit_message'.td()}\n',
                      style: const TextStyle(fontSize: 13, color: Colors.blue),
                      children: [
                        TextSpan(
                          text: msg.text?.val,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  c.editedMessage.value = null;
                  c.edit = null;
                },
                splashRadius: 20,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  /// Cancels a [_horizontalScrollTimer] and starts it again with the provided
  /// [duration].
  ///
  /// Defaults to 150 milliseconds if no [duration] is provided.
  void _resetHorizontalScroll(ChatController c, [Duration? duration]) {
    c.horizontalScrollTimer.value?.cancel();
    c.horizontalScrollTimer.value = Timer(duration ?? 150.milliseconds, () {
      if (_animation.value >= 0.5) {
        _animation.forward();
      } else {
        _animation.reverse();
      }
      c.horizontalScrollTimer.value = null;
    });
  }
}

/// Extension adding an ability to get text represented [DateTime] relative to
/// [DateTime.now].
extension DateTimeToRelative on DateTime {
  /// Returns relative to [now] text representation.
  ///
  /// [DateTime.now] is used if [now] is `null`.
  String toRelative([DateTime? now]) {
    DateTime local = isUtc ? toLocal() : this;
    DateTime relative = now ?? DateTime.now();
    int days = relative.julianDayNumber() - local.julianDayNumber();

    String time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    String date = '';

    if (days >= 28) {
      int months =
          relative.month + relative.year * 12 - local.month - local.year * 12;
      if (relative.day < local.day) {
        months--;
      }

      if (months > 0) {
        if (months >= 24) {
          date = '${months ~/ 12} ${'label_ago_years'.td()}';
        } else if (months >= 12) {
          date = 'label_ago_year'.td();
        } else if (months >= 2) {
          date = '$months ${'label_ago_months'.td()}';
        } else {
          date = 'label_ago_month'.td();
        }
      } else {
        date = '${days ~/ 7} ${'label_ago_weeks'.td()}';
      }
    } else if (days >= 14) {
      date = '${days ~/ 7} ${'label_ago_weeks'.td()}';
    } else if (days >= 7) {
      date = 'label_ago_week'.td();
    } else if (days >= 3) {
      date = '$days ${'label_ago_days'.td()}';
    } else if (days >= 2) {
      date = 'label_ago_day_before_yesterday'.td();
    } else if (days >= 1) {
      date = 'label_ago_yesterday'.td();
    }

    return date.isEmpty ? time : '${date.capitalizeFirst!}, $time';
  }

  /// Returns a Julian day number of this [DateTime].
  int julianDayNumber() {
    final int c0 = ((month - 3) / 12).floor();
    final int x4 = year + c0;
    final int x3 = (x4 / 100).floor();
    final int x2 = x4 % 100;
    final int x1 = month - (12 * c0) - 3;
    return ((146097 * x3) / 4).floor() +
        ((36525 * x2) / 100).floor() +
        (((153 * x1) + 2) / 5).floor() +
        day +
        1721119;
  }
}
