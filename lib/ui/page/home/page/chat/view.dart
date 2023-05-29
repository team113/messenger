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
import 'dart:ui';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/animated_delayed_scale.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/back_button.dart';
import 'widget/chat_bottom_panel.dart';
import 'widget/chat_forward.dart';
import 'widget/chat_item.dart';
import 'widget/chat_subtitle.dart';
import 'widget/custom_drop_target.dart';
import 'widget/swipeable_status.dart';
import 'widget/time_label.dart';
import 'widget/unread_label.dart';

/// View of the [Routes.chats] page.
class ChatView extends StatefulWidget {
  const ChatView(this.id, {super.key, this.itemId});

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
      debugLabel: '$runtimeType (${widget.id})',
    );

    super.initState();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

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
          final Chat? chat = c.chat?.chat.value;
          if (chat != null) {
            if (chat.isGroup || chat.isMonolog) {
              router.chatInfo(widget.id, push: true);
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
              body: const Center(child: CustomProgressIndicator()),
            );
          }

          final bool isMonolog = c.chat!.chat.value.isMonolog;

          return CustomDropTarget(
            key: Key('ChatView_${widget.id}'),
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
                            shadowColor: style.colors.onBackgroundOpacity27,
                            color: style.colors.onPrimary,
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
                              hoverColor: style.colors.transparent,
                              highlightColor: style.colors.transparent,
                              onTap: onDetailsTap,
                              child: DefaultTextStyle.merge(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Obx(() {
                                      return Text(
                                        c.chat!.title.value,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      );
                                    }),
                                    if (!isMonolog)
                                      ChatSubtitle(
                                        chat: c.chat,
                                        me: c.me,
                                        duration: c.duration.value,
                                        getUser: c.getUser,
                                      ),
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
                        Obx(() {
                          if (c.chat?.blacklisted == true) {
                            return const SizedBox.shrink();
                          }

                          final List<Widget> children;

                          if (c.chat!.chat.value.ongoingCall == null) {
                            children = [
                              WidgetButton(
                                onPressed: () => c.call(true),
                                child: SvgImage.asset(
                                  'assets/icons/chat_video_call.svg',
                                  height: 17,
                                ),
                              ),
                              const SizedBox(width: 28),
                              WidgetButton(
                                key: const Key('AudioCall'),
                                onPressed: () => c.call(false),
                                child: SvgImage.asset(
                                  'assets/icons/chat_audio_call.svg',
                                  height: 19,
                                ),
                              ),
                            ];
                          } else {
                            children = [
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
                                          decoration: BoxDecoration(
                                            color: style.colors.dangerColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: SvgImage.asset(
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
                                            color: style.colors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: SvgImage.asset(
                                              'assets/icons/audio_call_start.svg',
                                              width: 15,
                                              height: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ];
                          }

                          return Row(children: children);
                        }),
                      ],
                    ),
                    body: Listener(
                      onPointerSignal: c.settings.value?.timelineEnabled == true
                          ? (s) {
                              if (s is PointerScrollEvent) {
                                if ((s.scrollDelta.dy.abs() < 3 &&
                                        s.scrollDelta.dx.abs() > 3) ||
                                    c.isHorizontalScroll.value) {
                                  double value =
                                      _animation.value + s.scrollDelta.dx / 100;
                                  _animation.value = value.clamp(0, 1);

                                  if (_animation.value == 0 ||
                                      _animation.value == 1) {
                                    _resetHorizontalScroll(c, 10.milliseconds);
                                  } else {
                                    _resetHorizontalScroll(c);
                                  }
                                }
                              }
                            }
                          : null,
                      onPointerPanZoomUpdate: (s) {
                        if (c.scrollOffset.dx.abs() < 7 &&
                            c.scrollOffset.dy.abs() < 7) {
                          c.scrollOffset = c.scrollOffset.translate(
                            s.panDelta.dx.abs(),
                            s.panDelta.dy.abs(),
                          );
                        }
                      },
                      onPointerMove: (d) {
                        if (c.scrollOffset.dx.abs() < 7 &&
                            c.scrollOffset.dy.abs() < 7) {
                          c.scrollOffset = c.scrollOffset.translate(
                            d.delta.dx.abs(),
                            d.delta.dy.abs(),
                          );
                        }
                      },
                      onPointerUp: (_) => c.scrollOffset = Offset.zero,
                      onPointerCancel: (_) => c.scrollOffset = Offset.zero,
                      child: RawGestureDetector(
                        behavior: HitTestBehavior.translucent,
                        gestures: {
                          if (c.settings.value?.timelineEnabled == true &&
                              c.isSelecting.isFalse)
                            AllowMultipleHorizontalDragGestureRecognizer:
                                GestureRecognizerFactoryWithHandlers<
                                    AllowMultipleHorizontalDragGestureRecognizer>(
                              () =>
                                  AllowMultipleHorizontalDragGestureRecognizer(),
                              (AllowMultipleHorizontalDragGestureRecognizer
                                  instance) {
                                instance.onUpdate = (d) {
                                  if (!c.isItemDragged.value &&
                                      c.scrollOffset.dy.abs() < 7 &&
                                      c.scrollOffset.dx.abs() > 7 &&
                                      c.isSelecting.isFalse) {
                                    double value =
                                        (_animation.value - d.delta.dx / 100)
                                            .clamp(0, 1);

                                    if (_animation.value != 1 && value == 1 ||
                                        _animation.value != 0 && value == 0) {
                                      HapticFeedback.selectionClick();
                                    }

                                    _animation.value = value.clamp(0, 1);
                                  }
                                };

                                instance.onEnd = (d) async {
                                  c.scrollOffset = Offset.zero;
                                  if (!c.isItemDragged.value &&
                                      _animation.value != 1 &&
                                      _animation.value != 0) {
                                    if (_animation.value >= 0.5) {
                                      await _animation.forward();
                                      HapticFeedback.selectionClick();
                                    } else {
                                      await _animation.reverse();
                                      HapticFeedback.selectionClick();
                                    }
                                  }
                                };
                              },
                            )
                        },
                        child: Stack(
                          children: [
                            // Required for the [Stack] to take [Scaffold]'s
                            // size.
                            IgnorePointer(
                              child: ContextMenuInterceptor(child: Container()),
                            ),
                            Obx(() {
                              final Widget child = Scrollbar(
                                controller: c.listController,
                                child: FlutterListView(
                                  key: const Key('MessagesList'),
                                  controller: c.listController,
                                  physics: c.isHorizontalScroll.isTrue ||
                                          (PlatformUtils.isDesktop &&
                                              c.isItemDragged.isTrue)
                                      ? const NeverScrollableScrollPhysics()
                                      : const BouncingScrollPhysics(),
                                  delegate: FlutterListViewDelegate(
                                    (context, i) => _listElement(context, c, i),
                                    // ignore: invalid_use_of_protected_member
                                    childCount: c.elements.value.length,
                                    keepPosition: true,
                                    onItemKey: (i) => c.elements.values
                                        .elementAt(i)
                                        .id
                                        .toString(),
                                    onItemSticky: (i) => c.elements.values
                                        .elementAt(i) is DateTimeElement,
                                    initIndex: c.initIndex,
                                    initOffset: c.initOffset,
                                    initOffsetBasedOnBottom: false,
                                    disableCacheItems: true,
                                  ),
                                ),
                              );

                              if (PlatformUtils.isMobile) {
                                return child;
                              }

                              return SelectionArea(
                                onSelectionChanged: (a) =>
                                    c.selection.value = a,
                                contextMenuBuilder: (_, __) => const SizedBox(),
                                selectionControls: EmptyTextSelectionControls(),
                                child: ContextMenuInterceptor(child: child),
                              );
                            }),
                            Obx(() {
                              if ((c.chat!.status.value.isSuccess ||
                                      c.chat!.status.value.isEmpty) &&
                                  c.chat!.messages.isEmpty) {
                                return Center(
                                  child: Text(
                                    key: const Key('NoMessages'),
                                    'label_no_messages'.l10n,
                                  ),
                                );
                              }
                              if (c.chat!.status.value.isLoading) {
                                return const Center(
                                  child: CustomProgressIndicator(),
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
                          child: c.canGoBack.isTrue
                              ? FloatingActionButton.small(
                                  onPressed: c.animateToBack,
                                  child: const Icon(Icons.arrow_upward),
                                )
                              : c.canGoDown.isTrue
                                  ? FloatingActionButton.small(
                                      onPressed: c.animateToBottom,
                                      child: const Icon(Icons.arrow_downward),
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
                          child: ChatBottomPanel(
                            chat: c.chat,
                            edit: c.edit.value,
                            send: c.send,
                            unblacklist: () => c.unblacklist(),
                            keepTyping: () => c.keepTyping(),
                            onEdit: (id) =>
                                c.animateTo(id, offsetBasedOnBottom: true),
                            onSend: (id) =>
                                c.animateTo(id, offsetBasedOnBottom: true),
                          ),
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
                                color: style.colors.onBackgroundOpacity27,
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
                                          color: style
                                              .colors.onBackgroundOpacity27,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 50,
                                            color: style.colors.onPrimary,
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
    final Style style = Theme.of(context).extension<Style>()!;

    ListElement element = c.elements.values.elementAt(i);
    bool isLast = i == c.elements.length - 1;

    if (element is ChatMessageElement ||
        element is ChatCallElement ||
        element is ChatInfoElement) {
      Rx<ChatItem> e;

      if (element is ChatMessageElement) {
        e = element.item;
      } else if (element is ChatCallElement) {
        e = element.item;
      } else if (element is ChatInfoElement) {
        e = element.item;
      } else {
        throw Exception('Unreachable');
      }

      ListElement? previous;
      if (i > 0) {
        previous = c.elements.values.elementAt(i - 1);
      }

      ListElement? next;
      if (i < c.elements.length - 1) {
        next = c.elements.values.elementAt(i + 1);
      }

      bool previousSame = false;
      if (previous != null) {
        previousSame = (previous is ChatMessageElement &&
                previous.item.value.authorId == e.value.authorId &&
                e.value.at.val.difference(previous.item.value.at.val) <=
                    const Duration(minutes: 5)) ||
            (previous is ChatCallElement &&
                previous.item.value.authorId == e.value.authorId &&
                e.value.at.val.difference(previous.item.value.at.val) <=
                    const Duration(minutes: 5));
      }

      bool nextSame = false;
      if (next != null) {
        nextSame = (next is ChatMessageElement &&
                next.item.value.authorId == e.value.authorId &&
                e.value.at.val.difference(next.item.value.at.val) <=
                    const Duration(minutes: 5)) ||
            (next is ChatCallElement &&
                next.item.value.authorId == e.value.authorId &&
                e.value.at.val.difference(next.item.value.at.val) <=
                    const Duration(minutes: 5));
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, isLast ? 8 : 0),
        child: FutureBuilder<RxUser?>(
          future: c.getUser(e.value.authorId),
          builder: (_, u) => ChatItemWidget(
            chat: c.chat!.chat,
            item: e,
            me: c.me!,
            avatar: !previousSame,
            margin: EdgeInsets.only(
              top: previousSame ? 1.5 : 6,
              bottom: nextSame ? 1.5 : 6,
            ),
            loadImages: c.settings.value?.loadImages != false,
            reads: c.chat!.members.length > 10
                ? []
                : c.chat!.reads.where((m) =>
                    m.at == e.value.at &&
                    m.memberId != c.me &&
                    m.memberId != e.value.authorId),
            user: u.data,
            getUser: c.getUser,
            animation: _animation,
            timestamp: c.settings.value?.timelineEnabled != true,
            onHide: () => c.hideChatItem(e.value),
            onDelete: () => c.deleteMessage(e.value),
            onReply: () {
              if (c.send.replied.any((i) => i.id == e.value.id)) {
                c.send.replied.removeWhere((i) => i.id == e.value.id);
              } else {
                c.send.replied.insert(0, e.value);
              }
            },
            onCopy: (text) {
              if (c.selection.value?.plainText.isNotEmpty == true) {
                c.copyText(c.selection.value!.plainText);
              } else {
                c.copyText(text);
              }
            },
            onRepliedTap: (q) async {
              if (q.original != null) {
                await c.animateTo(q.original!.id);
              }
            },
            onGallery: c.calculateGallery,
            onResend: () => c.resendItem(e.value),
            onEdit: () => c.editMessage(e.value),
            onDrag: (d) => c.isItemDragged.value = d,
            onFileTap: (a) => c.download(e.value, a),
            onAttachmentError: () async {
              await c.chat?.updateAttachments(e.value);
              await Future.delayed(Duration.zero);
            },
            onSelecting: (s) => c.isSelecting.value = s,
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
            loadImages: c.settings.value?.loadImages != false,
            reads: c.chat!.members.length > 10
                ? []
                : c.chat!.reads.where((m) =>
                    m.at == element.forwards.last.value.at &&
                    m.memberId != c.me &&
                    m.memberId != element.authorId),
            user: u.data,
            getUser: c.getUser,
            animation: _animation,
            timestamp: c.settings.value?.timelineEnabled != true,
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
              if (element.forwards.any(
                      (e) => c.send.replied.any((i) => i.id == e.value.id)) ||
                  c.send.replied
                      .any((i) => i.id == element.note.value?.value.id)) {
                for (Rx<ChatItem> e in element.forwards) {
                  c.send.replied.removeWhere((i) => i.id == e.value.id);
                }

                if (element.note.value != null) {
                  c.send.replied
                      .removeWhere((i) => i.id == element.note.value!.value.id);
                }
              } else {
                if (element.note.value != null) {
                  c.send.replied.insert(0, element.note.value!.value);
                }

                for (Rx<ChatItem> e in element.forwards) {
                  c.send.replied.insert(0, e.value);
                }
              }
            },
            onCopy: (text) {
              if (c.selection.value?.plainText.isNotEmpty == true) {
                c.copyText(c.selection.value!.plainText);
              } else {
                c.copyText(text);
              }
            },
            onGallery: c.calculateGallery,
            onEdit: () => c.editMessage(element.note.value!.value),
            onDrag: (d) => c.isItemDragged.value = d,
            onForwardedTap: (quote) {
              if (quote.original != null) {
                if (quote.original!.chatId == c.id) {
                  c.animateTo(quote.original!.id);
                } else {
                  router.chat(
                    quote.original!.chatId,
                    itemId: quote.original!.id,
                    push: true,
                  );
                }
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
            onSelecting: (s) => c.isSelecting.value = s,
          ),
        ),
      );
    } else if (element is DateTimeElement) {
      return SelectionContainer.disabled(
        child: TimeLabelWidget(
          time: element.id.at.val,
          animation: _animation,
          opacity: c.stickyIndex.value == i
              ? c.showSticky.isTrue
                  ? 1
                  : 0
              : 1,
        ),
      );
    } else if (element is UnreadMessagesElement) {
      return SelectionContainer.disabled(child: UnreadLabel(c.unreadMessages));
    } else if (element is LoaderElement) {
      return Obx(() {
        final Widget child;

        if (c.bottomLoader.value) {
          child = Center(
            key: const ValueKey(1),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
              child: ConstrainedBox(
                constraints: BoxConstraints.tight(const Size.square(40)),
                child: Center(
                  child: ColoredBox(
                    color: style.colors.transparent,
                    child: const CustomProgressIndicator(),
                  ),
                ),
              ),
            ),
          );
        } else {
          child = SizedBox(
            key: const ValueKey(2),
            height: c.listController.position.pixels > 0 ? null : 64,
          );
        }

        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 200),
          sizeDuration: const Duration(milliseconds: 200),
          child: child,
        );
      });
    }

    return const SizedBox();
  }

  /// Cancels a [ChatController.horizontalScrollTimer] and starts it again with
  /// the provided [duration].
  ///
  /// Defaults to 50 milliseconds if no [duration] is provided.
  void _resetHorizontalScroll(ChatController c, [Duration? duration]) {
    c.isHorizontalScroll.value = true;
    c.horizontalScrollTimer.value?.cancel();
    c.horizontalScrollTimer.value = Timer(duration ?? 50.milliseconds, () {
      if (_animation.value >= 0.5) {
        _animation.forward();
      } else {
        _animation.reverse();
      }
      c.isHorizontalScroll.value = false;
      c.horizontalScrollTimer.value = null;
    });
  }
}

/// [ScrollBehavior] for scrolling with every available [PointerDeviceKind]s.
class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}

/// [GestureRecognizer] recognizing and allowing multiple horizontal drags.
class AllowMultipleHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) => acceptGesture(pointer);
}
