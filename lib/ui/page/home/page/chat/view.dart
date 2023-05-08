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
import 'dart:math';
import 'dart:ui';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/chat_item_quote.dart';
import 'package:messenger/ui/page/home/widget/animated_slider.dart';
import 'package:messenger/ui/page/home/widget/retry_image.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
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
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'message_field/view.dart';
import 'widget/back_button.dart';
import 'widget/chat_forward.dart';
import 'widget/chat_item.dart';
import 'widget/custom_drop_target.dart';
import 'widget/paid_notification.dart';
import 'widget/swipeable_status.dart';

/// View of the [Routes.chats] page.
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
    return GetBuilder<ChatController>(
      key: const Key('ChatView'),
      init: ChatController(
        widget.id,
        Get.find(),
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
            if (chat.isGroup) {
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
                  // Obx(() {
                  //   final Widget child;

                  //   if (c.paidDisclaimer.value) {
                  //     child = Column(
                  //       key: const Key('Column'),
                  //       children: [
                  //         Container(
                  //           width: double.infinity,
                  //           height: CustomAppBar.height,
                  //           color: Theme.of(context)
                  //               .extension<Style>()!
                  //               .barrierColor,
                  //         ),
                  //         const Spacer(),
                  //         Container(
                  //           width: double.infinity,
                  //           height: CustomNavigationBar.height + 4,
                  //           color: Theme.of(context)
                  //               .extension<Style>()!
                  //               .barrierColor,
                  //         ),
                  //       ],
                  //     );
                  //   } else {
                  //     child = const SizedBox();
                  //   }

                  //   return AnimatedSwitcher(
                  //     duration: 150.milliseconds,
                  //     child: child,
                  //   );
                  // }),
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
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    if (!isMonolog) _chatSubtitle(c),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                      // background: c.paid
                      //     ? const Color.fromARGB(255, 241, 250, 244)
                      //     : null,
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
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
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
                    body: Stack(
                      children: [
                        Listener(
                          onPointerSignal:
                              c.settings.value?.timelineEnabled == true
                                  ? (s) {
                                      if (s is PointerScrollEvent) {
                                        if ((s.scrollDelta.dy.abs() < 3 &&
                                                s.scrollDelta.dx.abs() > 3) ||
                                            c.isHorizontalScroll.value) {
                                          double value = _animation.value +
                                              s.scrollDelta.dx / 100;
                                          _animation.value = value.clamp(0, 1);

                                          if (_animation.value == 0 ||
                                              _animation.value == 1) {
                                            _resetHorizontalScroll(
                                                c, 10.milliseconds);
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
                              if (c.isSelecting.isFalse)
                                AllowMultipleHorizontalDragGestureRecognizer:
                                    GestureRecognizerFactoryWithHandlers<
                                        AllowMultipleHorizontalDragGestureRecognizer>(
                                  () =>
                                      AllowMultipleHorizontalDragGestureRecognizer(),
                                  (AllowMultipleHorizontalDragGestureRecognizer
                                      instance) {
                                    if (c.settings.value?.timelineEnabled ==
                                        true) {
                                      instance.onUpdate = (d) {
                                        if (!c.isItemDragged.value &&
                                            c.scrollOffset.dy.abs() < 7 &&
                                            c.scrollOffset.dx.abs() > 7 &&
                                            c.isSelecting.isFalse) {
                                          double value = (_animation.value -
                                                  d.delta.dx / 100)
                                              .clamp(0, 1);

                                          if (_animation.value != 1 &&
                                                  value == 1 ||
                                              _animation.value != 0 &&
                                                  value == 0) {
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
                                    }
                                  },
                                )
                            },
                            child: Column(
                              children: [
                                Obx(() {
                                  final Style style =
                                      Theme.of(context).extension<Style>()!;

                                  void onPressed() {
                                    c.paidDisclaimerDismissed.value = false;
                                    c.paidDisclaimer.value = true;
                                  }

                                  bool dummy = c.paidDisclaimerDismissed.value;

                                  return AnimatedSizeAndFade.showHide(
                                    fadeDuration: 250.milliseconds,
                                    sizeDuration: 250.milliseconds,
                                    show: (c.paidDisclaimerDismissed.value &&
                                            c.paid) ||
                                        c.pinned.isNotEmpty,
                                    child: Row(
                                      children: [
                                        if (c.pinned.isNotEmpty)
                                          Expanded(
                                            child: ContextMenuRegion(
                                              actions: [
                                                ContextMenuButton(
                                                  key: const Key('Unpin'),
                                                  label: PlatformUtils.isMobile
                                                      ? 'btn_unpin'.l10n
                                                      : 'btn_unpin_message'
                                                          .l10n,
                                                  trailing: SvgImage.asset(
                                                    'assets/icons/send_small.svg',
                                                    width: 18.37,
                                                    height: 16,
                                                  ),
                                                  onPressed: c.unpin,
                                                ),
                                              ],
                                              child: WidgetButton(
                                                onPressed: () {
                                                  double? offset = c.visible[c
                                                      .pinned[
                                                          c.displayPinned.value]
                                                      .id];

                                                  if (offset != null) {
                                                    bool next = offset < 50 ||
                                                        c
                                                                .listController
                                                                .position
                                                                .pixels ==
                                                            c
                                                                .listController
                                                                .position
                                                                .maxScrollExtent;

                                                    print(
                                                        '$next ${c.listController.position.pixels} < ${c.listController.position.maxScrollExtent}');

                                                    if (next) {
                                                      c.displayPinned.value +=
                                                          1;
                                                      if (c.displayPinned
                                                              .value >=
                                                          c.pinned.length) {
                                                        c.displayPinned.value =
                                                            0;
                                                      }
                                                    }
                                                  }

                                                  c.animateTo(
                                                    c
                                                        .pinned[c.displayPinned
                                                            .value]
                                                        .id,
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 6,
                                                    right: 6,
                                                    top: 6,
                                                  ),
                                                  child: MouseRegion(
                                                    onEnter: (_) => c
                                                        .hoveredPinned
                                                        .value = true,
                                                    onExit: (_) => c
                                                        .hoveredPinned
                                                        .value = false,
                                                    opaque: false,
                                                    child: Container(
                                                      width: double.infinity,
                                                      height: 60,
                                                      padding: const EdgeInsets
                                                          .fromLTRB(
                                                        8,
                                                        0,
                                                        0,
                                                        8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        boxShadow: const [
                                                          CustomBoxShadow(
                                                            blurRadius: 8,
                                                            color: Color(
                                                              0x22000000,
                                                            ),
                                                          ),
                                                        ],
                                                        borderRadius:
                                                            style.cardRadius,
                                                        border: style
                                                            .systemMessageBorder,
                                                        color: Colors.white,
                                                      ),
                                                      child: LayoutBuilder(
                                                        builder: (context,
                                                            constraints) {
                                                          return _pinned(
                                                            c,
                                                            constraints,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        AnimatedSize(
                                          duration: 200.milliseconds,
                                          child: WidgetButton(
                                            onPressed: onPressed,
                                            child: c.paidDisclaimerDismissed
                                                        .value &&
                                                    c.paid
                                                ? Container(
                                                    width: 40,
                                                    height: 40,
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                      12,
                                                      8,
                                                      12,
                                                      8,
                                                    ),
                                                    margin:
                                                        const EdgeInsets.only(
                                                      left: 0,
                                                      right: 6,
                                                      top: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: style
                                                          .systemMessageBorder,
                                                      color: Colors.white,
                                                      boxShadow: const [
                                                        CustomBoxShadow(
                                                          blurRadius: 8,
                                                          color: Color(
                                                            0x22000000,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child:
                                                          Transform.translate(
                                                        offset: const Offset(
                                                          -1,
                                                          -4,
                                                        ),
                                                        child: Text(
                                                          '¤',
                                                          style: style
                                                              .systemMessageStyle
                                                              .copyWith(
                                                            fontFamily:
                                                                'Gapopa',
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color: const Color(
                                                              0xFFffcf78,
                                                            ),
                                                            fontSize: 21,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  return AnimatedSizeAndFade.showHide(
                                    show: c.paidDisclaimerDismissed.value &&
                                        c.paid,
                                    child: WidgetButton(
                                      onPressed: onPressed,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        margin: const EdgeInsets.only(
                                          left: 6,
                                          right: 6,
                                          top: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: style.cardRadius,
                                          border: style.systemMessageBorder,
                                          color: style.systemMessageColor,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Платный чат',
                                            style: style.systemMessageStyle
                                                .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      // Required for the [Stack] to take [Scaffold]'s
                                      // size.
                                      IgnorePointer(
                                        child: ContextMenuInterceptor(
                                            child: Container()),
                                      ),
                                      Obx(() {
                                        final Style style = Theme.of(context)
                                            .extension<Style>()!;

                                        final Widget child = Scrollbar(
                                          controller: c.listController,
                                          child: FlutterListView(
                                            key: const Key('MessagesList'),
                                            controller: c.listController,
                                            physics: c.isHorizontalScroll
                                                        .isTrue ||
                                                    (PlatformUtils.isDesktop &&
                                                        c.isItemDragged.isTrue)
                                                ? const NeverScrollableScrollPhysics()
                                                : const BouncingScrollPhysics(),
                                            delegate: FlutterListViewDelegate(
                                              (context, i) =>
                                                  _listElement(context, c, i),
                                              childCount:
                                                  // ignore: invalid_use_of_protected_member
                                                  c.elements.value.length,
                                              keepPosition: true,
                                              onItemKey: (i) => c
                                                  .elements.values
                                                  .elementAt(i)
                                                  .id
                                                  .toString(),
                                              onItemSticky: (i) =>
                                                  c.elements.values.elementAt(i)
                                                      is DateTimeElement,
                                              initIndex: c.initIndex,
                                              initOffset: c.initOffset,
                                              initOffsetBasedOnBottom: false,
                                            ),
                                          ),
                                        );

                                        if (PlatformUtils.isMobile) {
                                          return child;
                                        }

                                        return SelectionArea(
                                          onSelectionChanged: (a) =>
                                              c.selection.value = a,
                                          contextMenuBuilder: (_, __) =>
                                              const SizedBox(),
                                          selectionControls:
                                              EmptyTextSelectionControls(),
                                          child: ContextMenuInterceptor(
                                            child: child,
                                          ),
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
                              ],
                            ),
                          ),
                        ),
                      ],
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
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
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
                          child: _bottomBar(c),
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

      final Style style = Theme.of(context).extension<Style>()!;

      return FutureBuilder<RxUser?>(
        future: c.getUser(e.value.authorId),
        builder: (_, u) => Obx(
          () => AnimatedContainer(
            margin: EdgeInsets.only(
              top: previousSame ? 1.5 : 6,
              bottom: nextSame ? 1.5 : 6,
            ),
            padding: EdgeInsets.fromLTRB(8, 0, 8, isLast ? 8 : 0),
            duration: 400.milliseconds,
            curve: Curves.ease,
            color: c.highlight.value == i
                // ? Colors.white
                //     .darken(0.03)
                ? style.unreadMessageColor.withOpacity(0.9)
                : const Color(0x00FFFFFF),
            child: ChatItemWidget(
              chat: c.chat!.chat,
              item: e,
              me: c.me!,
              // paid: c.chat?.messageCost != 0,
              paid: c.paid,
              avatar: !previousSame,
              margin: EdgeInsets.zero,
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
              pinned: c.pinned.contains(e.value),
              onPin: () {
                c.pinned.contains(e.value)
                    ? c.unpin(c.pinned.indexOf(e.value))
                    : c.pin(e.value);
              },
            ),
          ),
        ),
      );
    } else if (element is ChatForwardElement) {
      final Style style = Theme.of(context).extension<Style>()!;

      return FutureBuilder<RxUser?>(
        future: c.getUser(element.authorId),
        builder: (_, u) => Obx(
          () => AnimatedContainer(
            padding: EdgeInsets.fromLTRB(8, 0, 8, isLast ? 8 : 0),
            duration: 400.milliseconds,
            curve: Curves.ease,
            color: c.highlight.value == i
                // ? Colors.white
                //     .darken(0.03)
                ? style.unreadMessageColor.withOpacity(0.9)
                : const Color(0x00FFFFFF),
            child: ChatForwardWidget(
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
                    c.send.replied.removeWhere(
                        (i) => i.id == element.note.value!.value.id);
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
              pinned: c.pinned.contains(element.forwards.first.value),
              onPin: () {
                c.pinned.contains(element.forwards.first.value)
                    ? c.unpin(c.pinned.indexOf(element.forwards.first.value))
                    : c.pin(element.forwards.first.value);
              },
            ),
          ),
        ),
      );
    } else if (element is DateTimeElement) {
      return SelectionContainer.disabled(
        child: _timeLabel(element.id.at.val, c, i),
      );
    } else if (element is UnreadMessagesElement) {
      return SelectionContainer.disabled(child: _unreadLabel(context, c));
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
                child: const Center(
                  child: ColoredBox(
                    color: Colors.transparent,
                    child: CustomProgressIndicator(),
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
    } else if (element is PaidElement) {
      return _paidElement(c, element.messages, element.calls);
    } else if (element is FeeElement) {
      if (!element.fromMe) {
        return const SizedBox(height: 100);
      }

      final bool fromMe = element.fromMe;
      final Style style = Theme.of(context).extension<Style>()!;

      const String? text = 'dqwdqw';
      final String fee =
          fromMe ? 'Вы установили плату за:' : 'kirey установил плату за:';

      final BoxBorder border =
          fromMe ? style.secondaryBorder : style.primaryBorder;
      final Color background =
          fromMe ? style.readMessageColor : style.messageColor;

      return Row(
        // crossAxisAlignment:
        //     fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        // mainAxisAlignment:
        //     fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: LayoutBuilder(builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  // maxWidth: min(550, constraints.maxWidth),
                  maxWidth: 300,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
                        // child: IntrinsicWidth(
                        child: Container(
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(15),
                            // border: border,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: style.systemMessageColor,
                                  border: style.systemMessageBorder,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15),
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: DefaultTextStyle(
                                  style: style.systemMessageStyle,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(fee),
                                      Row(
                                        children: const [
                                          Text('- сообщения'),
                                          Spacer(),
                                          Text('\$5'),
                                        ],
                                      ),
                                      Row(
                                        children: const [
                                          Text('- звонки'),
                                          Spacer(),
                                          Text('\$5/min'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (text != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    12,
                                    10,
                                  ),
                                  child: Text(text!, style: style.boldBody),
                                ),
                            ],
                          ),
                        ),
                        // ),
                      )
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  /// Returns a header subtitle of the [Chat].
  Widget _chatSubtitle(ChatController c) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;

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
          return Row(
            children: [
              if (c.chat?.chat.value.muted != null) ...[
                SvgImage.asset(
                  'assets/icons/muted_darken.svg',
                  width: 19.99 * 0.6,
                  height: 15 * 0.6,
                ),
                const SizedBox(width: 5),
              ],
              Flexible(child: Text(subtitle, style: style)),
            ],
          );
        }
      } else if (chat.value.isDialog) {
        final ChatMember? partner =
            chat.value.members.firstWhereOrNull((u) => u.user.id != c.me);
        if (partner != null) {
          return Row(
            children: [
              if (c.chat?.chat.value.muted != null) ...[
                SvgImage.asset(
                  'assets/icons/muted_dark.svg',
                  width: 19.99 * 0.6,
                  height: 15 * 0.6,
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: FutureBuilder<RxUser?>(
                  future: c.getUser(partner.user.id),
                  builder: (_, snapshot) {
                    if (snapshot.data != null) {
                      return Obx(() {
                        final String? subtitle = c.chat!.chat.value
                            .getSubtitle(partner: snapshot.data!.user.value);

                        final UserTextStatus? status =
                            snapshot.data!.user.value.status;

                        if (status != null || subtitle != null) {
                          final StringBuffer buffer =
                              StringBuffer(status ?? '');

                          if (status != null && subtitle != null) {
                            buffer.write('space_vertical_space'.l10n);
                          }

                          buffer.write(subtitle ?? '');

                          return Text(buffer.toString(), style: style);
                        }

                        return const SizedBox();
                      });
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
    });
  }

  /// Returns a centered [time] label.
  Widget _timeLabel(DateTime time, ChatController c, int i) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SwipeableStatus(
        animation: _animation,
        padding: const EdgeInsets.only(right: 8),
        crossAxisAlignment: CrossAxisAlignment.center,
        design: SwipeableStyle.system,
        swipeable: Padding(
          padding: const EdgeInsets.only(right: 0),
          child: Text(DateFormat('dd.MM.yy').format(time)),
        ),
        child: Obx(() {
          return AnimatedOpacity(
            key: Key('$i$time'),
            opacity: c.stickyIndex.value == i
                ? c.showSticky.isTrue
                    ? 1
                    : 0
                : 1,
            duration: const Duration(milliseconds: 250),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: style.systemMessageBorder,
                  color: style.systemMessageColor,
                ),
                child: Text(
                  time.toRelative(),
                  style: style.systemMessageStyle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _paidElement(
    ChatController c,
    double messageCost,
    double callCost, {
    User? user,
  }) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(
          left: 4,
          right: 4,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            width: 0.5,
            color: const Color(0xFFD1FFCB),
          ),
          color: const Color(0xFFF8FFF6),
        ),
        child: RichText(
          textAlign: TextAlign.start,
          text: TextSpan(
            children: [
              if (user != null) ...[
                TextSpan(
                  text: user.name?.val ?? user.num.val,
                  style: style.systemMessageStyle.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => router.user(user.id, push: true),
                ),
                const TextSpan(text: ' has set a fee of '),
              ] else ...[
                const TextSpan(text: 'You have set a fee of '),
              ],
              TextSpan(
                text: '\$1.25',
                style: style.systemMessageStyle.copyWith(color: Colors.black),
              ),
              const TextSpan(text: ' per incoming message and '),
              TextSpan(
                text: '\$1.25',
                style: style.systemMessageStyle.copyWith(color: Colors.black),
              ),
              const TextSpan(text: ' for incoming calls.'),
            ],
            style: style.systemMessageStyle,
          ),
        ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             RichText(
//               textAlign: TextAlign.center,
//               text: TextSpan(
//                 children: [
//                   TextSpan(
//                     text: '${user?.name?.val ?? user?.num.val}',
//                     style: style.systemMessageStyle.copyWith(
//                       color: Theme.of(context).colorScheme.secondary,
//                     ),
//                     recognizer: TapGestureRecognizer()
//                       ..onTap = () => router.user(user!.id, push: true),
//                   ),
//                   const TextSpan(text: ' has set a fee for:'),
//                 ],
//                 style: style.systemMessageStyle,
//               ),
//             ),
//             const SizedBox(height: 5),
//             Text(
//               '''- incoming message - \$$messageCost
// - incoming call - \$$callCost/min''',
//               style: style.systemMessageStyle,
//             ),
//           ],
//         ),
      ),
    );
  }

//   Widget _paidElement(ChatController c, double messageCost, double callCost) {
//     final Style style = Theme.of(context).extension<Style>()!;
//     final User? user = c.chat!.members.values
//         .firstWhereOrNull((e) => e.id != c.me)
//         ?.user
//         .value;

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Center(
//         child: Container(
//           padding: const EdgeInsets.symmetric(
//             horizontal: 12,
//             vertical: 8,
//           ),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(15),
//             border: style.systemMessageBorder,
//             color: style.systemMessageColor,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               RichText(
//                 textAlign: TextAlign.center,
//                 text: TextSpan(
//                   children: [
//                     TextSpan(
//                       text: '${user?.name?.val ?? user?.num.val}',
//                       style: style.systemMessageStyle.copyWith(
//                         color: Theme.of(context).colorScheme.secondary,
//                       ),
//                       recognizer: TapGestureRecognizer()
//                         ..onTap = () => router.user(user!.id, push: true),
//                     ),
//                     const TextSpan(text: ' has set a fee for:'),
//                   ],
//                   style: style.systemMessageStyle,
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 '''- incoming message - \$$messageCost
// - incoming call - \$$callCost/min''',
//                 style: style.systemMessageStyle,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

  Widget _pinned(ChatController c, BoxConstraints constraints) {
    final Style style = Theme.of(context).extension<Style>()!;

    Widget preview(Attachment attachment) {
      if (attachment is ImageAttachment) {
        return Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(right: 5),
          child: RetryImage(
            attachment.medium.url,
            borderRadius: BorderRadius.circular(5),
            fit: BoxFit.cover,
            width: 40,
            height: 40,
          ),
        );
      } else {
        return Container(
          width: 40,
          height: 40,
          color: Colors.grey,
        );
      }
    }

    return Obx(() {
      if (c.pinned.isEmpty) {
        return const SizedBox();
      }

      final ChatItem item =
          c.pinned.elementAt(min(c.pinned.length - 1, c.displayPinned.value));
      List<Widget> children = [];

      if (item is ChatMessage) {
        Widget? leading;

        if (item.text == null) {
          leading = Row(
            children: item.attachments
                .take(constraints.maxWidth ~/ 50)
                .map(preview)
                .toList(),
          );
        } else if (item.attachments.isNotEmpty) {
          leading = preview(item.attachments.first);
        }

        children = [
          if (leading != null) leading,
          if (item.text != null)
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: item.text!.val),
                    // const WidgetSpan(child: SizedBox(width: 5)),
                    // WidgetSpan(child: Opacity(opacity: 1, child: pin)),
                  ],
                ),
                style: style.boldBody,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
        ];
      } else if (item is ChatCall) {
        children = [
          Expanded(
            child: Text(
              'Call',
              style: style.boldBody,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ];
      } else if (item is ChatForward) {
        final quote = item.quote;

        if (quote is ChatMessageQuote) {
          Widget? leading;

          if (quote.text == null) {
            leading = Row(
              children: quote.attachments
                  .take(constraints.maxWidth ~/ 50)
                  .map(preview)
                  .toList(),
            );
          } else if (quote.attachments.isNotEmpty) {
            leading = preview(quote.attachments.first);
          }

          children = [
            if (leading != null) leading,
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'label_forwarded_message'.l10n,
                      style: style.boldBody.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (quote.text != null)
                      TextSpan(text: 'semicolon_space'.l10n),
                    if (quote.text != null) TextSpan(text: quote.text!.val),
                  ],
                ),
                style: style.boldBody,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ];
        } else {
          children = [
            Expanded(
              child: Text(
                'Forwarded message',
                style: style.boldBody,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ];
        }
      }

      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(children: children),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 4),
              // SvgImage.asset(
              //   'assets/icons/close_primary.svg',
              //   width: 10,
              //   height: 10,
              // ),
              Obx(() {
                final bool visible =
                    c.visible[c.pinned[c.displayPinned.value].id] != null;

                return AnimatedOpacity(
                  duration: 200.milliseconds,
                  opacity: visible &&
                          (c.hoveredPinned.value || PlatformUtils.isMobile)
                      ? 1
                      : 0,
                  child: InkWell(
                    key: const Key('RemovePickedFile'),
                    onTap: visible
                        ? () {
                            c.unpin();

                            if (c.pinned.isNotEmpty) {
                              c.animateTo(c.pinned[c.displayPinned.value].id);
                            }
                          }
                        : null,
                    child: Container(
                      // width: 10,
                      // height: 10,
                      key: const Key('Close'),
                      // decoration: BoxDecoration(
                      //   shape: BoxShape.circle,
                      //   color: style.cardColor,
                      // ),
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      // color: Colors.red,
                      margin: const EdgeInsets.only(left: 4),
                      alignment: Alignment.center,
                      child: SvgImage.asset(
                        'assets/icons/close_primary.svg',
                        width: 8,
                        height: 8,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 17 - 8),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // const SizedBox(width: 6),
                    // Transform.rotate(
                    //   angle: pi / 5,
                    //   child: const Icon(
                    //     Icons.push_pin,
                    //     // color: Theme.of(context).colorScheme.secondary,
                    //     color: Color(0xFF888888),
                    //     size: 12,
                    //   ),
                    // ),
                    // if (c.pinned.length > 1) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${c.displayPinned.value + 1}/${c.pinned.length}',
                      style: style.systemMessageStyle.copyWith(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                  // ],
                ),
              ),
            ],
          ),
          // Align(alignment: Alignment.bottomRight, child: pin),
          const SizedBox(width: 4),
        ],
      );
      // Positioned(right: 0, bottom: 0, child: pin),

      return Center(
        child: Text(
          'Закреплено сообщений: 1/3',
          style: style.systemMessageStyle.copyWith(
            fontSize: 15,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );
    });
  }

  /// Returns a bottom bar of this [ChatView] to display under the messages list
  /// containing a send/edit field.
  Widget _bottomBar(ChatController c) {
    if (c.chat?.blacklisted == true) {
      return _blockedField(c);
    }

    return Obx(() {
      if (c.edit.value != null) {
        return Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: MessageFieldView(
            key: const Key('EditField'),
            controller: c.edit.value,
            onItemPressed: (id) => c.animateTo(id, offsetBasedOnBottom: true),
            canAttach: false,
            background: const Color(0xFFfff7ea),
          ),
        );
      }

      final Style style = Theme.of(context).extension<Style>()!;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            return AnimatedSizeAndFade.showHide(
              show: c.paidDisclaimer.value,
              child: PaidNotification(
                border: c.paidBorder.value
                    ? Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.transparent,
                        width: 2,
                      ),
                onPressed: () {
                  c.paidDisclaimer.value = false;
                  c.paidDisclaimerDismissed.value = true;
                  c.paidBorder.value = false;
                },
              ),
            );

            return AnimatedSizeAndFade.showHide(
              show: c.paidDisclaimer.value,
              child: Container(
                margin:
                    const EdgeInsets.only(top: 0, bottom: 8, left: 8, right: 8),
                decoration: BoxDecoration(
                  borderRadius: style.cardRadius,
                  boxShadow: const [
                    CustomBoxShadow(
                      blurRadius: 8,
                      color: Color(0x22000000),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Container(
                    //   margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    //   padding:
                    //       const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    //   decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.only(
                    //       topLeft: style.cardRadius.topLeft,
                    //       topRight: style.cardRadius.topRight,
                    //     ),
                    //     color: style.readMessageColor,
                    //   ),
                    //   child: Text(
                    //     'Платный чат. Вы установили \$5 за входящие сообщения и \$5/мин за входящие звонки.',
                    //     // style: style.boldBody,
                    //     style: style.systemMessageStyle,
                    //   ),
                    // ),
                    // Container(
                    //   margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    //   padding:
                    //       const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    //   decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.only(
                    //       topLeft: style.cardRadius.topLeft,
                    //       topRight: style.cardRadius.topRight,
                    //     ),
                    //     color: Colors.white,
                    //   ),
                    //   child: Text(
                    //     'Askldjskldjsqkdjqw',
                    //     style: style.boldBody,
                    //   ),
                    // ),
                    WidgetButton(
                      onPressed: () {
                        c.paidDisclaimer.value = false;
                        c.paidDisclaimerDismissed.value = true;
                        c.paidBorder.value = false;

                        // final theirFee = FeeElement(false);
                        // c.elements[theirFee.id] = theirFee;

                        // SchedulerBinding.instance
                        //     .addPostFrameCallback((_) {
                        //   c.listController.animateTo(
                        //     c.listController.offset + 150,
                        //     duration: 200.milliseconds,
                        //     curve: Curves.ease,
                        //   );
                        // });

                        // if (c.feeElement != null) {
                        //   c.elements.remove(c.feeElement!.id);
                        //   c.feeElement = null;
                        // }

                        // switch (c.confirmAction) {
                        //   case ConfirmAction.audioCall:
                        //     c.call(false);
                        //     break;

                        //   case ConfirmAction.videoCall:
                        //     c.call(true);
                        //     break;

                        //   case ConfirmAction.sendMessage:
                        //     c.send.onSubmit?.call();
                        //     break;

                        //   case null:
                        //     // No-op.
                        //     break;
                        // }

                        c.confirmAction = null;
                      },
                      child: AnimatedContainer(
                        duration: 250.milliseconds,
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          18,
                          18,
                          18,
                        ),
                        decoration: BoxDecoration(
                          border: c.paidBorder.value
                              ? Border.all(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  width: 2,
                                )
                              : Border.all(
                                  color: Colors.transparent,
                                  width: 2,
                                ),
                          borderRadius: style.cardRadius,
                          // borderRadius: BorderRadius.only(
                          //   bottomLeft: style.cardRadius.bottomLeft,
                          //   bottomRight:
                          //       style.cardRadius.bottomRight,
                          // ),
                          // border: style.systemMessageBorder,
                          color: style.systemMessageColor,
                        ),
                        child: Column(
                          children: [
                            // Text(
                            //   'Платный чат',
                            //   style: style.systemMessageStyle,
                            // ),
                            // const SizedBox(height: 8),
                            Text(
                              'Kirey установил \$5 за отправку сообщения и \$5/мин за совершение звонка.',
                              style: style.systemMessageStyle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Принять и продолжить',
                              style: style.systemMessageStyle.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            return AnimatedSizeAndFade.showHide(
              show: c.paidDisclaimer.value,
              child: Container(
                margin: const EdgeInsets.only(
                  top: 8,
                  bottom: 8,
                  left: 8,
                  right: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: style.cardRadius,
                  boxShadow: const [
                    CustomBoxShadow(
                      blurRadius: 8,
                      color: Color(0x22000000),
                    ),
                  ],
                ),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: style.cardRadius.topLeft,
                            topRight: style.cardRadius.topRight,
                          ),
                          color: Colors.white,
                        ),
                        child: Text(
                          'Askldjskldjsqkdjqw',
                          style: style.boldBody,
                        ),
                      ),
                      WidgetButton(
                        onPressed: () {
                          c.paidDisclaimer.value = false;
                          c.paidDisclaimerDismissed.value = true;

                          // if (c.feeElement != null) {
                          //   c.elements.remove(c.feeElement!.id);
                          //   c.feeElement = null;
                          // }

                          switch (c.confirmAction) {
                            case ConfirmAction.audioCall:
                              c.call(false);
                              break;

                            case ConfirmAction.videoCall:
                              c.call(true);
                              break;

                            case ConfirmAction.sendMessage:
                              c.send.onSubmit?.call();
                              break;

                            case null:
                              // No-op.
                              break;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: style.cardRadius.bottomLeft,
                              bottomRight: style.cardRadius.bottomRight,
                            ),
                            border: style.systemMessageBorder,
                            color: style.systemMessageColor,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'kirey установил плату за сообщения (\$5) и звонки (\$5/min)',
                                style: style.systemMessageStyle,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Принять и продолжить',
                                style: style.systemMessageStyle.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: MessageFieldView(
              key: const Key('SendField'),
              controller: c.send,
              onChanged: c.keepTyping,
              onItemPressed: (id) => c.animateTo(id, offsetBasedOnBottom: true),
              canForward: true,
              // background:
              //     c.paid ? const Color.fromARGB(255, 241, 250, 244) : null,
              // background: const Color(0xFFfff7ea),
              // canSend: !disabled,
              // canAttach: !disabled,
              // disabled: disabled,
            ),
          ),
          // LayoutBuilder(
          //   builder: (context, constraints) {
          //     return Obx(() {
          //       return AnimatedSizeAndFade.showHide(
          //         show: c.paidDisclaimer.value,
          //         child: Container(
          //           margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          //           padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          //           decoration: BoxDecoration(
          //             borderRadius: style.cardRadius,
          //             boxShadow: const [
          //               CustomBoxShadow(
          //                 blurRadius: 8,
          //                 color: Color(0x22000000),
          //               ),
          //             ],
          //             color: Colors.white,
          //           ),
          //           child: Row(
          //             children: [
          //               Expanded(
          //                 child: RichText(
          //                   text: TextSpan(
          //                     children: [
          //                       TextSpan(
          //                         text:
          //                             'kirey взимает плату в размере \$5 за сообщение. ',
          //                       ),
          //                       // TextSpan(
          //                       //   text: 'Принять.',
          //                       //   style: thin?.copyWith(
          //                       //     fontSize: 18,
          //                       //     color:
          //                       //         Theme.of(context).colorScheme.secondary,
          //                       //   ),
          //                       // ),
          //                     ],
          //                     style: thin?.copyWith(fontSize: 18),
          //                   ),
          //                 ),
          //                 // child: Text(
          //                 //   'kirey взимает плату в размере \$5 за сообщение.',
          //                 //   style: thin?.copyWith(fontSize: 18),
          //                 // ),
          //               ),
          //               const SizedBox(width: 12),
          //               WidgetButton(
          //                 onPressed: () {
          //                   c.paidDisclaimer.value = false;
          //                   c.paidDisclaimerDismissed = true;

          //                   switch (c.confirmAction) {
          //                     case ConfirmAction.audioCall:
          //                       c.call(false);
          //                       break;

          //                     case ConfirmAction.videoCall:
          //                       c.call(true);
          //                       break;

          //                     case ConfirmAction.sendMessage:
          //                       c.send.onSubmit?.call();
          //                       break;

          //                     case null:
          //                       // No-op.
          //                       break;
          //                   }
          //                 },
          //                 child: Text(
          //                   'Принять',
          //                   style: thin?.copyWith(
          //                     fontSize: 18,
          //                     color: Theme.of(context).colorScheme.secondary,
          //                   ),
          //                 ),
          //               ),
          //               Center(
          //                 child: ConstrainedBox(
          //                   constraints: BoxConstraints(maxWidth: 150),
          //                   child: Row(
          //                     mainAxisSize: MainAxisSize.min,
          //                     children: [
          //                       // Expanded(
          //                       //   child: OutlinedRoundedButton(
          //                       //     maxWidth: double.infinity,
          //                       //     onPressed: () {
          //                       //       c.paidDisclaimer.value = false;
          //                       //     },
          //                       //     title: Text(
          //                       //       'Закрыть',
          //                       //       style:
          //                       //           thin?.copyWith(color: Colors.black),
          //                       //     ),
          //                       //     color: const Color(0xFFEEEEEE),
          //                       //   ),
          //                       // ),
          //                       // const SizedBox(width: 12),
          //                       // Expanded(
          //                       //   child: OutlinedRoundedButton(
          //                       //     maxWidth: double.infinity,
          //                       //     onPressed: () {
          //                       //       c.paidDisclaimer.value = false;
          //                       //       c.paidDisclaimerDismissed = true;

          //                       //       switch (c.confirmAction) {
          //                       //         case ConfirmAction.audioCall:
          //                       //           c.call(false);
          //                       //           break;

          //                       //         case ConfirmAction.videoCall:
          //                       //           c.call(true);
          //                       //           break;

          //                       //         case ConfirmAction.sendMessage:
          //                       //           c.send.onSubmit?.call();
          //                       //           break;

          //                       //         case null:
          //                       //           // No-op.
          //                       //           break;
          //                       //       }
          //                       //     },
          //                       //     title: Text(
          //                       //       'Принять',
          //                       //       style:
          //                       //           thin?.copyWith(color: Colors.white),
          //                       //     ),
          //                       //     color:
          //                       //         Theme.of(context).colorScheme.secondary,
          //                       //   ),
          //                       // ),
          //                     ],
          //                   ),
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       );
          //     });
          //   },
          // ),
        ],
      );
    });
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

  /// Returns a [WidgetButton] removing this [Chat] from the blacklist.
  Widget _blockedField(ChatController c) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Theme(
      data: MessageFieldView.theme(context),
      child: SafeArea(
        child: Container(
          key: const Key('BlockedField'),
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            boxShadow: const [
              CustomBoxShadow(blurRadius: 8, color: Color(0x22000000)),
            ],
          ),
          child: ConditionalBackdropFilter(
            condition: style.cardBlur > 0,
            filter: ImageFilter.blur(
              sigmaX: style.cardBlur,
              sigmaY: style.cardBlur,
            ),
            borderRadius: style.cardRadius,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(color: style.cardColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 5 + (PlatformUtils.isMobile ? 0 : 8),
                        bottom: 13,
                      ),
                      child: Transform.translate(
                        offset: Offset(0, PlatformUtils.isMobile ? 6 : 1),
                        child: WidgetButton(
                          onPressed: c.unblacklist,
                          child: IgnorePointer(
                            child: ReactiveTextField(
                              enabled: false,
                              state: TextFieldState(text: 'btn_unblock'.l10n),
                              filled: false,
                              dense: true,
                              textAlign: TextAlign.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              style: style.boldBody.copyWith(
                                fontSize: 17,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
