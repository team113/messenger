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
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/animated_delayed_scale.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/page/home/widget/init_callback.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'component/attachment_selector.dart';
import 'controller.dart';
import 'forward/view.dart';
import 'widget/back_button.dart';
import 'widget/chat_forward.dart';
import 'widget/chat_item.dart';
import 'widget/send_message_field.dart';
import 'widget/swipeable_status.dart';
import 'widget/video_thumbnail/video_thumbnail.dart';

/// View of the [Routes.chat] page.
class ChatView extends StatefulWidget {
  const ChatView(this.id, {Key? key, this.itemId}) : super(key: key);

  /// ID of this [Chat].
  final ChatId id;

  /// ID of a [ChatItem] to scroll to initially in this [ChatView].
  final ChatItemId? itemId;

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
      key: const Key('ChatView'),
      init: ChatController(
        widget.id,
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        itemId: widget.itemId,
      ),
      tag: widget.id.val,
      builder: (c) {
        // Opens [Routes.chatInfo] or [Routes.user] page basing on the
        // [Chat.isGroup] indicator.
        void onDetailsTap() {
          Chat? chat = c.chat?.chat.value;
          if (chat != null) {
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
        }

        return Obx(() {
          if (c.status.value.isEmpty) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text('label_no_chat_found'.l10n)),
            );
          } else if (!c.status.value.isSuccess) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return DropTarget(
            enable: !c.isForwardPopupOpen.value,
            onDragDone: (details) => c.dropFiles(details),
            onDragEntered: (_) => c.isDraggingFiles.value = true,
            onDragExited: (_) => c.isDraggingFiles.value = false,
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Stack(
                children: [
                  Scaffold(
                    resizeToAvoidBottomInset: true,
                    appBar: CustomAppBar(
                      title: Row(
                        children: [
                          Material(
                            elevation: 6,
                            type: MaterialType.circle,
                            shadowColor: const Color(0x55000000),
                            color: Colors.white,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onDetailsTap,
                              child: Center(
                                child: AvatarWidget.fromRxChat(
                                  c.chat,
                                  radius: 17,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: InkWell(
                              splashFactory: NoSplash.splashFactory,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: onDetailsTap,
                              child: DefaultTextStyle.merge(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.chat!.title.value,
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    _chatSubtitle(c),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                      padding: const EdgeInsets.only(left: 4, right: 20),
                      leading: const [StyledBackButton()],
                      actions: [
                        if (c.chat!.chat.value.ongoingCall == null) ...[
                          WidgetButton(
                            onPressed: () => c.call(true),
                            child: SvgLoader.asset(
                              'assets/icons/chat_video_call.svg',
                              height: 17,
                            ),
                          ),
                          const SizedBox(width: 28),
                          WidgetButton(
                            onPressed: () => c.call(false),
                            child: SvgLoader.asset(
                              'assets/icons/chat_audio_call.svg',
                              height: 19,
                            ),
                          ),
                        ] else ...[
                          AnimatedSwitcher(
                            key: const Key('ActiveCallButton'),
                            duration: 300.milliseconds,
                            child: c.inCall
                                ? WidgetButton(
                                    key: const Key('Drop'),
                                    onPressed: c.dropCall,
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: SvgLoader.asset(
                                          'assets/icons/call_end.svg',
                                          width: 32,
                                          height: 32,
                                        ),
                                      ),
                                    ),
                                  )
                                : WidgetButton(
                                    key: const Key('Join'),
                                    onPressed: c.joinCall,
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: SvgLoader.asset(
                                          'assets/icons/audio_call_start.svg',
                                          width: 15,
                                          height: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                    body: Listener(
                      onPointerSignal: (s) {
                        if (s is PointerScrollEvent) {
                          // TODO: Use [PointerPanZoomUpdateEvent] here.
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
                            // Required for the [Stack] to take [Scaffold]'s
                            // size.
                            IgnorePointer(
                              child: ContextMenuInterceptor(child: Container()),
                            ),
                            GestureDetector(
                              onHorizontalDragUpdate: PlatformUtils.isDesktop
                                  ? (d) {
                                      double value =
                                          _animation.value - d.delta.dx / 100;
                                      _animation.value = value.clamp(0, 1);
                                    }
                                  : null,
                              onHorizontalDragEnd: PlatformUtils.isDesktop
                                  ? (d) {
                                      if (_animation.value >= 0.5) {
                                        _animation.forward();
                                      } else {
                                        _animation.reverse();
                                      }
                                    }
                                  : null,
                            ),
                            Obx(() {
                              return FlutterListView(
                                key: const Key('MessagesList'),
                                controller: c.listController,
                                physics: c.horizontalScrollTimer.value == null
                                    ? const BouncingScrollPhysics()
                                    : const NeverScrollableScrollPhysics(),
                                delegate: FlutterListViewDelegate(
                                  (context, i) => _listElement(context, c, i),
                                  // ignore: invalid_use_of_protected_member
                                  childCount: c.elements.value.length,
                                  keepPosition: true,
                                  onItemKey: (i) => c.elements.values
                                      .elementAt(i)
                                      .id
                                      .toString(),
                                  initIndex: c.initIndex,
                                  initOffset: c.initOffset,
                                  initOffsetBasedOnBottom: false,
                                ),
                              );
                            }),
                            Obx(() {
                              if ((c.chat!.status.value.isSuccess ||
                                      c.chat!.status.value.isEmpty) &&
                                  c.chat!.messages.isEmpty) {
                                return Center(
                                  child: Text('label_no_messages'.l10n),
                                );
                              }
                              if (c.chat!.status.value.isLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              return const SizedBox();
                            }),
                          ],
                        ),
                      ),
                    ),
                    floatingActionButton: Obx(() {
                      return SizedBox(
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
                                          child:
                                              const Icon(Icons.arrow_downward),
                                        )
                                      : const SizedBox(),
                        ),
                      );
                    }),
                    bottomNavigationBar: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                      child:
                          NotificationListener<SizeChangedLayoutNotification>(
                        onNotification: (l) {
                          Rect previous = c.bottomBarRect.value ??
                              const Rect.fromLTWH(0, 0, 0, 55);
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            c.bottomBarRect.value =
                                c.bottomBarKey.globalPaintBounds;
                            if (c.bottomBarRect.value != null &&
                                c.listController.position.maxScrollExtent > 0 &&
                                c.listController.position.pixels <
                                    c.listController.position.maxScrollExtent) {
                              Rect current = c.bottomBarRect.value!;
                              c.listController.jumpTo(
                                c.listController.position.pixels +
                                    (current.height - previous.height),
                              );
                            }
                          });

                          return true;
                        },
                        child: SizeChangedLayoutNotifier(
                          key: c.bottomBarKey,
                          child: _bottomBar(c, context),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Obx(() {
                      return AnimatedSwitcher(
                        duration: 200.milliseconds,
                        child: c.isDraggingFiles.value
                            ? Container(
                                color: const Color(0x40000000),
                                child: Center(
                                  child: AnimatedDelayedScale(
                                    duration: const Duration(milliseconds: 300),
                                    beginScale: 1,
                                    endScale: 1.06,
                                    child: ConditionalBackdropFilter(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          color: const Color(0x40000000),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 50,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /// Builds a visual representation of a [ListElement] identified by the
  /// provided index.
  Widget _listElement(BuildContext context, ChatController c, int i) {
    ListElement element = c.elements.values.elementAt(i);
    bool isLast = i == c.elements.length - 1;

    if (element is ChatMessageElement ||
        element is ChatCallElement ||
        element is ChatMemberInfoElement) {
      Rx<ChatItem> e;

      if (element is ChatMessageElement) {
        e = element.item;
      } else if (element is ChatCallElement) {
        e = element.item;
      } else if (element is ChatMemberInfoElement) {
        e = element.item;
      } else {
        throw Exception('Unreachable');
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, isLast ? 8 : 0),
        child: FutureBuilder<RxUser?>(
          future: c.getUser(e.value.authorId),
          builder: (_, u) => ChatItemWidget(
            chat: c.chat!.chat,
            item: e,
            me: c.me!,
            user: u.data,
            getUser: c.getUser,
            animation: _animation,
            onJoinCall: c.joinCall,
            onHide: () => c.hideChatItem(e.value),
            onDelete: () => c.deleteMessage(e.value),
            onReply: () {
              if (c.repliedMessages.contains(e.value)) {
                c.repliedMessages.remove(e.value);
              } else {
                c.repliedMessages.insert(0, e.value);
              }
            },
            onCopy: c.copyText,
            onRepliedTap: c.animateTo,
            onGallery: c.calculateGallery,
            onResend: () => c.resendItem(e.value),
            onEdit: () => c.editMessage(e.value),
            onFileTap: (a) => c.download(e.value, a),
            onAttachmentError: () async {
              await c.chat?.updateAttachments(e.value);
              await Future.delayed(Duration.zero);
            },
            onForwardPopupToggle: (v) => c.isForwardPopupOpen.value = v,
          ),
        ),
      );
    } else if (element is ChatForwardElement) {
      return Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, isLast ? 8 : 0),
        child: FutureBuilder<RxUser?>(
          future: c.getUser(element.authorId),
          builder: (_, u) => ChatForwardWidget(
            key: Key('ChatForwardWidget_${element.id}'),
            chat: c.chat!.chat,
            forwards: element.forwards,
            note: element.note,
            authorId: element.authorId,
            me: c.me!,
            user: u.data,
            getUser: c.getUser,
            animation: _animation,
            onHide: () async {
              final List<Future> futures = [];

              for (Rx<ChatItem> f in element.forwards) {
                futures.add(c.hideChatItem(f.value));
              }

              if (element.note.value != null) {
                futures.add(c.hideChatItem(element.note.value!.value));
              }

              await Future.wait(futures);
            },
            onDelete: () async {
              final List<Future> futures = [];

              for (Rx<ChatItem> f in element.forwards) {
                futures.add(c.deleteMessage(f.value));
              }

              if (element.note.value != null) {
                futures.add(c.deleteMessage(element.note.value!.value));
              }

              await Future.wait(futures);
            },
            onReply: () {
              if (element.forwards
                      .any((e) => c.repliedMessages.contains(e.value)) ||
                  c.repliedMessages.contains(element.note.value?.value)) {
                for (Rx<ChatItem> e in element.forwards) {
                  c.repliedMessages.remove(e.value);
                }

                if (element.note.value != null) {
                  c.repliedMessages.remove(element.note.value!.value);
                }
              } else {
                for (Rx<ChatItem> e in element.forwards.reversed) {
                  c.repliedMessages.insert(0, e.value);
                }

                if (element.note.value != null) {
                  c.repliedMessages.insert(0, element.note.value!.value);
                }
              }
            },
            onCopy: c.copyText,
            onGallery: c.calculateGallery,
            onEdit: () => c.editMessage(element.note.value!.value),
            onForwardedTap: (id, chatId) {
              if (chatId == c.id) {
                c.animateTo(id);
              } else {
                router.chat(chatId, itemId: id, push: true);
              }
            },
            onFileTap: c.download,
            onAttachmentError: () async {
              for (ChatItem item in [
                element.note.value?.value,
                ...element.forwards.map((e) => e.value),
              ].whereNotNull()) {
                await c.chat?.updateAttachments(item);
              }

              await Future.delayed(Duration.zero);
            },
            onForwardPopupToggle: (v) => c.isForwardPopupOpen.value = v,
          ),
        ),
      );
    } else if (element is DateTimeElement) {
      return _timeLabel(element.id.at.val);
    } else if (element is UnreadMessagesElement) {
      return _unreadLabel(context, c);
    }

    return const SizedBox();
  }

  /// Returns a header subtitle of the [Chat].
  Widget _chatSubtitle(ChatController c) {
    final TextStyle? style = Theme.of(context).textTheme.caption;

    return Obx(() {
      Rx<Chat> chat = c.chat!.chat;

      if (chat.value.ongoingCall != null) {
        final subtitle = StringBuffer();
        if (!context.isMobile) {
          subtitle.write(
              '${'label_call_active'.l10n}${'space_vertical_space'.l10n}');
        }

        final Set<UserId> actualMembers =
            chat.value.ongoingCall!.members.map((k) => k.user.id).toSet();
        subtitle.write(
          'label_a_of_b'.l10nfmt(
            {'a': actualMembers.length, 'b': c.chat!.members.length},
          ),
        );

        if (c.duration.value != null) {
          subtitle.write(
            '${'space_vertical_space'.l10n}${c.duration.value?.hhMmSs()}',
          );
        }

        return Text(subtitle.toString(), style: style);
      }

      bool isTyping = c.chat?.typingUsers.any((e) => e.id != c.me) == true;
      if (isTyping) {
        if (c.chat?.chat.value.isGroup == false) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'label_typing'.l10n,
                style: style?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
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

        Iterable<String> typings = c.chat!.typingUsers
            .where((e) => e.id != c.me)
            .map((e) => e.name?.val ?? e.num.val);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                typings.join('comma_space'.l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
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

      if (chat.value.isGroup) {
        final String? subtitle = chat.value.getSubtitle();
        if (subtitle != null) {
          return Text(subtitle, style: style);
        }
      } else if (chat.value.isDialog) {
        final ChatMember? partner =
            chat.value.members.firstWhereOrNull((u) => u.user.id != c.me);
        if (partner != null) {
          return FutureBuilder<RxUser?>(
            future: c.getUser(partner.user.id),
            builder: (_, snapshot) {
              if (snapshot.data != null) {
                return Obx(() {
                  var subtitle = c.chat!.chat.value
                      .getSubtitle(partner: snapshot.data!.user.value);

                  return Text(subtitle ?? '', style: style);
                });
              }

              return Container();
            },
          );
        }
      }

      return Container();
    });
  }

  /// Returns a centered [time] label.
  Widget _timeLabel(DateTime time) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SwipeableStatus(
        animation: _animation,
        asStack: true,
        padding: const EdgeInsets.only(right: 8),
        crossAxisAlignment: CrossAxisAlignment.center,
        swipeable: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(DateFormat('dd.MM.yy').format(time)),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: style.systemMessageBorder,
              color: style.systemMessageColor,
            ),
            child: Text(time.toRelative(), style: style.systemMessageStyle),
          ),
        ),
      ),
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
      child: c.editedMessage.value == null
          ? SendMessageField(
              onPickFile: c.pickFile,
              onPickImageFromCamera: c.pickImageFromCamera,
              onPickMedia: c.pickMedia,
              onVideoImageFromCamera: c.pickVideoFromCamera,
              forwarding: c.forwarding,
              repliedMessages: c.repliedMessages,
              onSend: () async {
                if (c.forwarding.value) {
                  if (c.repliedMessages.isNotEmpty) {
                    bool? result = await ChatForwardView.show(
                      context,
                      c.id,
                      c.repliedMessages
                          .map((e) => ChatItemQuote(item: e))
                          .toList(),
                      text: c.send.text,
                      attachments: c.attachments.map((e) => e.value).toList(),
                    );

                    if (result == true) {
                      c.repliedMessages.clear();
                      c.forwarding.value = false;
                      c.attachments.clear();
                      c.send.clear();
                    }
                  }
                } else {
                  c.send.submit();
                }
              },
              textFieldState: c.send,
              onReorder: (int old, int to) {
                if (old < to) {
                  --to;
                }

                final ChatItem item = c.repliedMessages.removeAt(old);
                c.repliedMessages.insert(to, item);

                HapticFeedback.lightImpact();
              },
              me: c.me,
              attachments: c.attachments,
            )
          : SendMessageField(
              onSend: () {
                c.edit!.submit();
              },
              textFieldState: c.edit!,
              me: c.me,
            ),
    );
  }

  /// Returns a [ReactiveTextField] for editing a [ChatMessage].
  Widget _editField(ChatController c) {
    Style style = Theme.of(context).extension<Style>()!;

    return Container(
      key: const Key('EditField'),
      decoration: BoxDecoration(
        borderRadius: style.cardRadius,
        color: const Color(0xFFFFFFFF).withOpacity(0.4),
        boxShadow: const [
          CustomBoxShadow(blurRadius: 8, color: Color(0x22000000)),
        ],
      ),
      child: ConditionalBackdropFilter(
        condition: style.cardBlur > 0,
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        borderRadius: style.cardRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height / 3,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      child: Dismissible(
                        key: Key('${c.editedMessage.value?.id}'),
                        direction: DismissDirection.horizontal,
                        onDismissed: (_) => c.editedMessage.value = null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                          ),
                          child: _editedMessage(c),
                        ),
                      ),
                    ),
                  )
                ],
              );
            }),
            SendMessageField(
              onSend: c.edit!.submit,
              textFieldState: c.edit!,
              me: c.me,
              attachments: c.attachments,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a visual representation of a [ChatController.editedMessage].
  Widget _editedMessage(ChatController c) {
    final Style style = Theme.of(context).extension<Style>()!;
    final bool fromMe = c.editedMessage.value?.authorId == c.me;

    if (c.editedMessage.value != null && c.edit != null) {
      if (c.editedMessage.value is ChatMessage) {
        Widget? content;
        List<Widget> additional = [];

        final ChatMessage item = c.editedMessage.value as ChatMessage;

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
                    : DecorationImage(image: NetworkImage(image.small.url)),
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

        if (item.text != null) {
          content = Text(
            item.text!.val,
            style: style.boldBody,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return WidgetButton(
          onPressed: () => c.animateTo(item.id, offsetBasedOnBottom: true),
          child: MouseRegion(
            opaque: false,
            onEnter: (d) => c.hoveredReply.value = item,
            onExit: (d) => c.hoveredReply.value = null,
            child: Container(
              margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                                    color: const Color(0xFF63B4FF),
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
                  ),
                  Obx(() {
                    return AnimatedSwitcher(
                      duration: 200.milliseconds,
                      child: c.hoveredReply.value == item ||
                              PlatformUtils.isMobile
                          ? WidgetButton(
                              key: const Key('CancelEditButton'),
                              onPressed: () => c.editedMessage.value = null,
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
                            )
                          : const SizedBox(),
                    );
                  }),
                ],
              ),
            ),
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

  /// Builds a visual representation of an [UnreadMessagesElement].
  Widget _unreadLabel(BuildContext context, ChatController c) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: style.systemMessageBorder,
        color: style.systemMessageColor,
      ),
      child: Center(
        child: Text(
          'label_unread_messages'.l10nfmt({'quantity': c.unreadMessages}),
          style: style.systemMessageStyle,
        ),
      ),
    );
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

    int months = 0;
    if (days >= 28) {
      months =
          relative.month + relative.year * 12 - local.month - local.year * 12;
      if (relative.day < local.day) {
        months--;
      }
    }

    return 'label_ago_date'.l10nfmt({
      'years': months ~/ 12,
      'months': months,
      'weeks': days ~/ 7,
      'days': days,
    });
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
