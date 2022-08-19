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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:intl/intl.dart';
import 'package:messenger/ui/page/call/widget/animated_delayed_scale.dart';
import 'package:messenger/ui/page/home/widget/animated_typing.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/animated_dots.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/widget/app_bar.dart';
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
import 'widget/init_callback.dart';
import 'widget/my_dismissible.dart';
import 'widget/swipeable_status.dart';
import 'widget/tooltip_hint.dart';
import 'widget/video_thumbnail/video_thumbnail.dart';

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
        Get.find(),
      ),
      tag: widget.id.val,
      builder: (c) {
        return Obx(() {
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
                      resizeToAvoidBottomInset: true,
                      appBar: CustomAppBar.from(
                        context: context,
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
                            InkWell(
                              splashFactory: NoSplash.splashFactory,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: onDetailsTap,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.chat!.title.value,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  _chatSubtitle(c),
                                ],
                              ),
                            ),
                          ],
                        ),
                        automaticallyImplyLeading: false,
                        padding: const EdgeInsets.only(left: 4, right: 20),
                        leading: const [StyledBackButton()],
                        actions: [
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
                          // const SizedBox(width: 10),
                        ],
                      ),
                      body: Listener(
                        onPointerSignal: (s) {
                          if (s is PointerScrollEvent) {
                            // TODO: Look into `PointerChange` and seek for
                            //       related for panning events on a new Flutter
                            //       release:
                            // https://github.com/flutter/flutter/issues/23604
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
                        child: RawGestureDetector(
                          behavior: HitTestBehavior.translucent,
                          gestures: c.horizontalScrollTimer.value == null
                              ? {
                                  AllowMultipleHorizontalDragGestureRecognizer:
                                      GestureRecognizerFactoryWithHandlers<
                                          AllowMultipleHorizontalDragGestureRecognizer>(
                                    () =>
                                        AllowMultipleHorizontalDragGestureRecognizer(),
                                    (AllowMultipleHorizontalDragGestureRecognizer
                                        instance) {
                                      instance.onStart = (d) {};

                                      instance.onUpdate = (d) {
                                        if (!c.isItemDragged.value) {
                                          double value = _animation.value -
                                              d.delta.dx / 100;
                                          _animation.value = value.clamp(0, 1);

                                          if (_animation.value == 1 ||
                                              _animation.value == 0) {
                                            if (!c.timelineFeedback.value) {
                                              HapticFeedback.selectionClick();
                                            }
                                            c.timelineFeedback.value = true;
                                          } else {
                                            c.timelineFeedback.value = false;
                                          }
                                        }
                                      };

                                      instance.onEnd = (d) {
                                        c.timelineFeedback.value = false;
                                        if (!c.isItemDragged.value) {
                                          if (_animation.value >= 0.5) {
                                            _animation.forward();
                                          } else {
                                            _animation.reverse();
                                          }
                                        }
                                      };
                                    },
                                  )
                                }
                              : {},
                          // onHorizontalDragUpdate: (d) {
                          // print('onHorizontalDragUpdate');
                          // double value = _animation.value - d.delta.dx / 100;
                          // _animation.value = value.clamp(0, 1);
                          // },
                          // onHorizontalDragEnd: (d) {
                          //   if (_animation.value >= 0.5) {
                          //     _animation.forward();
                          //   } else {
                          //     _animation.reverse();
                          //   }
                          // },
                          child: Stack(
                            children: [
                              // Required for the [Stack] to take [Scaffold]'s size.
                              IgnorePointer(
                                child:
                                    ContextMenuInterceptor(child: Container()),
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
                              FlutterListView(
                                key: const Key('MessagesList'),
                                controller: c.listController,
                                physics: c.horizontalScrollTimer.value == null
                                    ? const BouncingScrollPhysics()
                                    : const NeverScrollableScrollPhysics(),
                                delegate: FlutterListViewDelegate(
                                  (context, j) =>
                                      _chatItemBuilder(c, context, j),
                                  childCount: (c.chat?.messages.length ?? 0),
                                  // childCount: (c.chat?.messages.length ?? 0) + 2,
                                  initIndex: c.initIndex,
                                  initOffset: c.initOffset,
                                  initOffsetBasedOnBottom: false,
                                  keepPosition: true,
                                  onItemKey: (i) {
                                    // if (j == 0) {
                                    //   return '';
                                    // }

                                    // if (j ==
                                    //     (c.chat?.messages.length ?? 0) + 1) {
                                    //   return '';
                                    // }

                                    // int i = j - 1;
                                    return c.chat!.messages[i].value.id.val;
                                  },
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
                                              Icons.arrow_downward,
                                            ),
                                          )
                                        : Container(),
                          ),
                        ),
                      ),
                      bottomNavigationBar: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                        child:
                            NotificationListener<SizeChangedLayoutNotification>(
                          onNotification: (l) {
                            Rect previous = c.bottomBarRect.value ??
                                const Rect.fromLTWH(0, 0, 0, 65);
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              c.bottomBarRect.value =
                                  c.bottomBarKey.globalPaintBounds;
                              if (c.bottomBarRect.value != null &&
                                  c.listController.position.maxScrollExtent >
                                      0 &&
                                  c.listController.position.pixels <
                                      c.listController.position
                                          .maxScrollExtent) {
                                Rect current = c.bottomBarRect.value!;
                                c.listController.jumpTo(
                                    c.listController.position.pixels +
                                        (current.height - previous.height));
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
                                      duration:
                                          const Duration(milliseconds: 300),
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
                    // AnimatedSwitcher(
                    //   duration: const Duration(milliseconds: 200),
                    //   child: c.isDraggingFiles.value
                    //       ? Container(
                    //           color: Colors.white.withOpacity(0.9),
                    //           child: Center(
                    //             child: Column(
                    //               mainAxisAlignment: MainAxisAlignment.center,
                    //               children: [
                    //                 const Icon(
                    //                   Icons.upload_file,
                    //                   size: 30,
                    //                 ),
                    //                 const SizedBox(height: 5),
                    //                 Text(
                    //                   'label_drop_here'.l10n,
                    //                   textAlign: TextAlign.center,
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //         )
                    //       : null,
                    // ),
                  ],
                ),
              ),
            );
          } else if (c.status.value.isEmpty) {
            return Scaffold(
              body: Center(child: Text('label_no_chat_found'.l10n)),
            );
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        });
      },
    );
  }

  Widget _chatItemBuilder(ChatController c, BuildContext context, int i) {
    // if (j == 0) {
    //   return const SizedBox(height: 65);
    // }

    // if (j == (c.chat?.messages.length ?? 0) + 1) {
    //   return Obx(() {
    //     print('height is ${10 + (c.bottomBarRect.value?.height ?? 55)}');
    //     return Container(
    //       color: Colors.red,
    //       height: 10 + (c.bottomBarRect.value?.height ?? 55),
    //     );
    //   });
    // }

    // int i = j - 1;

    List<Widget> widgets = [];
    Rx<ChatItem> e = c.chat!.messages[i];

    if (c.lastReadItem.value == e) {
      widgets.add(
        Container(
          color: const Color(0x33000000),
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: Text(
              'label_unread_messages'.l10n,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    Widget widget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FutureBuilder<RxUser?>(
        future: c.getUser(e.value.authorId),
        builder: (_, u) => ChatItemWidget(
          key: Key(e.value.id.val),
          chat: c.chat!.chat,
          item: e,
          me: c.me!,
          user: u.data,
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
          onRepliedTap: (id) => c.animateTo(id),
          animation: _animation,
          onGallery: c.calculateGallery,
          onResend: () => c.resendItem(e.value),
          onEdit: () => c.editMessage(e.value),
          onDrag: (d) => c.isItemDragged.value = d,
        ),
      ),
    );

    if (e.value.authorId != c.me &&
        !c.chat!.chat.value.isReadBy(e.value, c.me) &&
        c.status.value.isSuccess &&
        !c.status.value.isLoadingMore) {
      widget = VisibilityDetector(
        key: Key('Detector_${e.value.id.val}'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0) {
            if (c.lastVisibleItem.value?.at.isBefore(e.value.at) != false) {
              c.lastVisibleItem.value = e.value;
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
      Rx<ChatItem>? previous = c.chat?.messages[i - 1];

      // Display a time if difference between
      // messages is more than 30 minutes.
      if (previous != null) {
        if (previous.value.at.val.day != e.value.at.val.day) {
          widgets.add(_timeLabel(e.value.at.val));
        }

        // if (previous.value.at.val.difference(e.value.at.val).inMinutes < -30) {
        //   widgets.add(_timeLabel(e.value.at.val));
        // }
        else if (previous.value.at.val.difference(e.value.at.val).inMinutes <
            -2) {
          widgets.add(Container(height: 8, color: Colors.transparent));
        }
      }
    }

    widgets.add(widget);

    return Padding(
      padding: EdgeInsets.only(
        top: i == 0 ? 10 : 0,
        bottom: i == c.chat!.messages.length - 1 ? 10 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      ),
    );
  }

  /// Returns a header subtitle of the [Chat].
  Widget _chatSubtitle(ChatController c) {
    final TextStyle? style = Theme.of(context).textTheme.caption;

    return Obx(() {
      var chat = c.chat!.chat;

      bool isTyping = c.chat?.typingUsers.any((e) => e.id != c.me) == true;
      if (isTyping) {
        Iterable<String> typings = c.chat!.typingUsers
            .where((e) => e.id != c.me)
            .map((e) => e.name?.val ?? e.num.val);

        if (c.chat?.chat.value.isGroup == false) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Печатает'.l10n,
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

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                typings.join(', '),
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
        var subtitle = chat.value.getSubtitle();
        if (subtitle != null) {
          return Text(subtitle, style: style);
        }
      } else if (chat.value.isDialog) {
        var partner =
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
                  ? 'label_typings'.l10n
                  : 'label_typing'.l10n),
              const AnimatedDots(color: Colors.black)
            ],
          ),
        );
      } else {
        return Container();
      }
    });
  }

  /// Returns a centered [time] label.
  Widget _timeLabel(DateTime time) {
    return Column(
      children: [
        const SizedBox(height: 8),
        SwipeableStatus(
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
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                // color: Colors.white,
                color: const Color(0xFFF8F8F8),
              ),
              child: Text(
                time.toRelative(),
                style: const TextStyle(color: Color(0xFF888888)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
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
          // _typingUsers(c),
          // AnimatedSizeAndFade(
          //   fadeDuration: 300.milliseconds,
          //   sizeDuration: 300.milliseconds,
          //   child:
          c.editedMessage.value == null ? _sendField(c) : _editField(c),
          // ),
        ],
      ),
    );
  }

  /// Returns a [ReactiveTextField] for sending a message in this [Chat].
  Widget _sendField(ChatController c) {
    Style style = Theme.of(context).extension<Style>()!;
    const double iconSize = 22;
    return Container(
      key: const Key('SendField'),
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
        children: [
          LayoutBuilder(builder: (context, constraints) {
            bool grab =
                (125 + 2) * c.attachments.length > constraints.maxWidth - 16;
            return Stack(
              children: [
                // ConditionalBackdropFilter(
                //   condition: style.cardBlur > 0,
                //   filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                //   borderRadius: BorderRadius.only(
                //     topLeft: style.cardRadius.topLeft,
                //     topRight: style.cardRadius.topRight,
                //   ),
                //   child: AnimatedContainer(
                //     duration: 400.milliseconds,
                //     curve: Curves.ease,
                //     width: double.infinity,
                //     height:
                //         c.attachments.isEmpty && c.repliedMessage.value == null
                //             ? 0
                //             : 125 + 8 + 8,
                //     decoration: BoxDecoration(
                //       color: const Color(0xFFFFFFFF).withOpacity(0.4),
                //     ),
                //   ),
                // ),
                Obx(() {
                  bool expanded =
                      c.repliedMessages.isNotEmpty || c.attachments.isNotEmpty;
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
                              color: const Color(0xFFFFFFFF).withOpacity(0.4),
                              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (c.repliedMessages.isNotEmpty)
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

                                          final ChatItem item =
                                              c.repliedMessages.removeAt(old);
                                          c.repliedMessages.insert(to, item);

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
                                                initState: HapticFeedback
                                                    .selectionClick,
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
                                        padding: const EdgeInsets.fromLTRB(
                                            1, 0, 1, 0),
                                        children: c.repliedMessages.map((e) {
                                          return ReorderableDragStartListener(
                                            key: Key('Handle_${e.id}'),
                                            enabled: !PlatformUtils.isMobile,
                                            index: c.repliedMessages.indexOf(e),
                                            child: MyDismissible(
                                              key: Key('${e.id}'),
                                              direction:
                                                  MyDismissDirection.horizontal,
                                              onDismissed: (_) {
                                                c.repliedMessages.remove(e);
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 2,
                                                ),
                                                child: _repliedMessage(c, e),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  // if (c.repliedMessage.value != null)
                                  //   MyDismissible(
                                  //     key: Key('${c.repliedMessage.value?.id}'),
                                  //     direction: MyDismissDirection.up,
                                  //     onDismissed: (_) =>
                                  //         c.repliedMessage.value = null,
                                  //     child: _repliedMessage(c),
                                  //   ),
                                  if (c.attachments.isNotEmpty &&
                                      c.repliedMessages.isNotEmpty)
                                    const SizedBox(height: 4),
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
                                                .map((e) => _buildAttachment(
                                                      c,
                                                      e,
                                                      grab,
                                                    ))
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
              topLeft: c.attachments.isEmpty && c.repliedMessages.isEmpty
                  ? style.cardRadius.topLeft
                  : Radius.zero,
              topRight: c.attachments.isEmpty && c.repliedMessages.isEmpty
                  ? style.cardRadius.topRight
                  : Radius.zero,
              bottomLeft: style.cardRadius.bottomLeft,
              bottomRight: style.cardRadius.bottomLeft,
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(
                        child: AnimatedFab(
                          labelStyle: const TextStyle(fontSize: 17),
                          closedIcon: SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: SvgLoader.asset(
                              'assets/icons/attach.svg',
                              height: iconSize,
                            ),
                          ),
                          openedIcon: SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: SvgLoader.asset(
                              'assets/icons/close_primary.svg',
                              width: iconSize - 5,
                              height: iconSize - 5,
                            ),
                          ),
                          height: PlatformUtils.isMobile && !PlatformUtils.isWeb
                              ? PlatformUtils.isIOS
                                  ? 220
                                  : 260
                              : 100,
                          actions: [
                            AnimatedFabAction(
                              icon: const Icon(Icons.attachment,
                                  color: Colors.blue),
                              label: 'label_file'.l10n,
                              onTap: c.send.editable.value ? c.pickFile : null,
                            ),
                            if (PlatformUtils.isMobile &&
                                !PlatformUtils.isWeb) ...[
                              AnimatedFabAction(
                                icon:
                                    const Icon(Icons.photo, color: Colors.blue),
                                label: 'label_gallery'.l10n,
                                onTap:
                                    c.send.editable.value ? c.pickMedia : null,
                              ),
                              if (PlatformUtils.isAndroid) ...[
                                AnimatedFabAction(
                                  icon: const Icon(
                                    Icons.photo_camera,
                                    color: Colors.blue,
                                  ),
                                  label: 'label_photo'.l10n,
                                  onTap: c.pickImageFromCamera,
                                ),
                                AnimatedFabAction(
                                  icon: const Icon(
                                    Icons.video_camera_back,
                                    color: Colors.blue,
                                  ),
                                  label: 'label_video'.l10n,
                                  onTap: c.pickVideoFromCamera,
                                ),
                              ],
                              if (PlatformUtils.isIOS)
                                AnimatedFabAction(
                                  icon: const Icon(
                                    Icons.camera,
                                    color: Colors.blue,
                                  ),
                                  label: 'label_camera'.l10n,
                                  onTap: c.pickImageFromCamera,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  // const SizedBox(width: 20),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 5 + (PlatformUtils.isMobile ? 0 : 8),
                        bottom: 13,
                      ),
                      child: Transform.translate(
                        offset: Offset(0, PlatformUtils.isMobile ? 6 : 1),
                        child: ReactiveTextField(
                          onChanged: c.keepTyping,
                          key: const Key('MessageField'),
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
                  SizedBox(
                    height: 56,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: c.send.isEmpty.value && c.attachments.isEmpty
                            ? SizedBox(
                                width: 56,
                                height: 56,
                                child: Center(
                                  child: TooltipHint(
                                    hint: 'Видео сообщение',
                                    child: _button(
                                      icon: SvgLoader.asset(
                                        'assets/icons/video_message_outline.svg',
                                        width: 23.13,
                                        height: 21,
                                      ),
                                      onTap: () {},
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(height: 18),
                      ),
                    ),
                  ),
                  // const SizedBox(width: 20),
                  WidgetButton(
                    onPressed: c.send.isEmpty.value && c.attachments.isEmpty
                        ? () {}
                        : c.send.submit,
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: SizedBox(
                            key: c.send.isEmpty.value && c.attachments.isEmpty
                                ? const Key('Mic')
                                : const Key('Send'),
                            width: 25.18,
                            height: 22.85,
                            child: c.send.isEmpty.value && c.attachments.isEmpty
                                ? TooltipHint(
                                    hint: 'Голосовое сообщение',
                                    child: SvgLoader.asset(
                                      'assets/icons/audio_message_outline.svg',
                                      height: iconSize,
                                    ),
                                  )
                                : Padding(
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
                  ),
                  // const SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a [ReactiveTextField] for editing a [ChatMessage].
  Widget _editField(ChatController c) {
    Style style = Theme.of(context).extension<Style>()!;
    const double iconSize = 22;

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
                      child: MyDismissible(
                        key: Key('${c.editedMessage.value?.id}'),
                        direction: MyDismissDirection.horizontal,
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
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              decoration: BoxDecoration(color: style.cardColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IgnorePointer(
                    child: WidgetButton(
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
                          onChanged: c.keepTyping,
                          key: const Key('EditField'),
                          state: c.edit!,
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
                  WidgetButton(
                    onPressed: c.edit!.submit,
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: SizedBox(
                            key: const Key('Edit'),
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
                  ),
                  // const SizedBox(width: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );

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
                    label: 'label_audio_call'.l10n,
                    onTap: () => c.call(false),
                    noAnimation: true,
                  ),
                  AnimatedFabAction(
                    icon: const Icon(Icons.video_call, color: Colors.blue),
                    label: 'label_video_call'.l10n,
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
                  hint: 'label_edit_message_hint'.l10n,
                  minLines: 1,
                  maxLines: 6,
                  dense: true,
                  onChanged: c.keepTyping,
                  style: const TextStyle(fontSize: 17),
                  type: PlatformUtils.isDesktop
                      ? TextInputType.text
                      : TextInputType.multiline,
                  textInputAction: PlatformUtils.isDesktop
                      ? TextInputAction.send
                      : TextInputAction.newline,
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

  /// Returns a visual representation of the provided [Attachment].
  Widget _buildAttachment(ChatController c, AttachmentData d,
      [bool grab = false]) {
    Attachment e = d.data;

    bool isImage =
        (e is ImageAttachment || (e is LocalAttachment && e.file.isImage));
    bool isVideo = (e is FileAttachment && e.isVideo) ||
        (e is LocalAttachment && e.file.isVideo);

    const double size = 125;

    Widget _content() {
      if (isImage || isVideo) {
        Widget child;

        if (isImage) {
          if (e is LocalAttachment) {
            if (e.file.bytes == null) {
              if (e.file.path == null) {
                child = const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                if (e.file.isSvg) {
                  child = SvgLoader.file(
                    File(e.file.path!),
                    width: size,
                    height: size,
                  );
                } else {
                  child = Image.file(
                    File(e.file.path!),
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                  );
                }
              }
            } else {
              if (e.file.isSvg) {
                child = SvgLoader.bytes(
                  e.file.bytes!,
                  width: size,
                  height: size,
                );
              } else {
                child = Image.memory(
                  e.file.bytes!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                );
              }
            }
          } else {
            child = Image.network(
              '${Config.url}/files${e.original}',
              fit: BoxFit.cover,
              width: size,
              height: size,
            );
          }
        } else {
          if (e is LocalAttachment) {
            if (e.file.bytes == null) {
              child = const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              child = VideoThumbnail.bytes(bytes: e.file.bytes!);
            }
          } else {
            child =
                VideoThumbnail.path(path: '${Config.url}/files${e.original}');
          }
        }

        return WidgetButton(
          // key: c.attachmentKeys[i],
          onPressed: () {
            List<Attachment> attachments = c.attachments
                .where((d) {
                  Attachment e = d.data;
                  return e is ImageAttachment ||
                      (e is FileAttachment && e.isVideo) ||
                      (e is LocalAttachment &&
                          (e.file.isImage || e.file.isVideo));
                })
                .map((e) => e.data)
                .toList();

            int index = attachments.indexOf(e);
            if (index != -1) {
              GalleryPopup.show(
                context: context,
                gallery: GalleryPopup(
                  initial: attachments.indexOf(e),
                  initialKey: d.key,
                  onTrashPressed: (int i) {
                    Attachment a = attachments[i];
                    c.attachments.removeWhere((o) => o.data == a);
                  },
                  children: attachments.map((o) {
                    var link = '${Config.url}/files${o.original}';
                    if (o is ImageAttachment ||
                        (o is LocalAttachment && o.file.isImage)) {
                      return GalleryItem.image(link);
                    }
                    return GalleryItem.video(link);
                  }).toList(),
                ),
              );
            }
          },
          child: isVideo
              ? IgnorePointer(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      child,
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x80000000),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                )
              : child,
        );
      }

      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                e.filename,
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
                // TODO: Cut the file in way for the extension to be displayed.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                '${e.size ~/ 1024} KB',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    Widget _attachment() {
      Style style = Theme.of(context).extension<Style>()!;
      return MouseRegion(
        key: Key(e.id.val),
        opaque: false,
        onEnter: (_) => c.hoveredAttachment.value = d,
        onExit: (_) => c.hoveredAttachment.value = null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            // color: const Color(0x4D165084),
            // color: const Color(0xFFD8D8D8),
            color: const Color(0xFFF5F5F5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Stack(
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(10), child: _content()),
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
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: Obx(() {
                      return AnimatedSwitcher(
                        duration: 200.milliseconds,
                        child: (c.hoveredAttachment.value == d ||
                                PlatformUtils.isMobile)
                            ? InkWell(
                                key: const Key('RemovePickedFile'),
                                onTap:
                                    true ? () => c.attachments.remove(d) : null,
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  margin:
                                      const EdgeInsets.only(left: 8, bottom: 8),
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
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return MyDismissible(
      key: d.key,
      direction: MyDismissDirection.up,
      onDismissed: (_) => c.attachments.remove(d),
      child: _attachment(),
    );
  }

  /// Returns an [InkWell] circular button with an [icon].
  Widget _button({
    void Function()? onTap,
    required Widget icon,
  }) {
    return WidgetButton(onPressed: onTap, child: icon);
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.5),
      child: Material(
        type: MaterialType.circle,
        // color: Colors.white,
        // elevation: 6,
        // type: MaterialType.transparency,
        elevation: 0, //6,
        color: Colors.transparent,
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
  }

  /// Builds a visual representation of a [ChatController.repliedMessages].
  Widget _repliedMessage(ChatController c, ChatItem item) {
    Style style = Theme.of(context).extension<Style>()!;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      var desc = StringBuffer();

      if (item.text != null) {
        desc.write(item.text!.val);
        // if (item.attachments.isNotEmpty) {
        //   desc.write(
        //       ' [${item.attachments.length} ${'label_attachments'.l10n}]');
        // }
      } else if (item.attachments.isNotEmpty) {
        // desc.write('[${item.attachments.length} ${'label_attachments'.l10n}]');
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
                color: const Color(0xFFE7E7E7),
                // color: Colors.grey,
                borderRadius: BorderRadius.circular(4),
                image: image == null
                    ? null
                    : DecorationImage(
                        image:
                            NetworkImage('${Config.url}/files${image.small}'))),
            width: 30,
            height: 30,
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
                        c.repliedMessages.remove(item);
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

  /// Builds a visual representation of a [ChatController.editedMessage].
  Widget _editedMessage(ChatController c) {
    Style style = Theme.of(context).extension<Style>()!;

    if (c.editedMessage.value != null && c.edit != null) {
      if (c.editedMessage.value is ChatMessage) {
        Widget? content;
        List<Widget> additional = [];

        final item = c.editedMessage.value as ChatMessage;

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
                  color: const Color(0xFFE7E7E7),
                  // color: Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                  image: image == null
                      ? null
                      : DecorationImage(
                          image: NetworkImage(
                              '${Config.url}/files${image.small}'))),
              width: 30,
              height: 30,
              child: image == null
                  ? const Icon(Icons.attach_file, size: 16)
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
                // color: const Color(0xFFD8D8D8),
                // color: Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                // border: Border(left: BorderSide(width: 1, color: Color(0xFF63B4FF))),
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
                                  'Edit'.l10n,
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

    int months = 0;
    if (days >= 28) {
      months =
          relative.month + relative.year * 12 - local.month - local.year * 12;
      if (relative.day < local.day) {
        months--;
      }
    }

    return 'label_ago_date'.l10nfmt({
      'year': year.toString(),
      'month': month.toString().padLeft(2, '0'),
      'day': day.toString().padLeft(2, '0'),
      'weekday': weekday,
      'years': months ~/ 12,
      'months': months,
      'weeks': days ~/ 7,
      'days': days,
    });

    if (days >= 7) {
      date = 'label_ago_date'.l10nfmt({
        'year': year.toString(),
        'month': month.toString().padLeft(2, '0'),
        'day': day.toString().padLeft(2, '0'),
        'weekday': weekday,
        'years': months ~/ 12,
        'months': months,
        'weeks': days ~/ 7,
        'days': days,
      });
    } else {
      switch (weekday) {
        case DateTime.monday:
          date = 'label_date_monday'.l10n;
          break;

        case DateTime.tuesday:
          date = 'label_date_tuesday'.l10n;
          break;

        case DateTime.wednesday:
          date = 'label_date_wednesday'.l10n;
          break;

        case DateTime.thursday:
          date = 'label_date_thursday'.l10n;
          break;

        case DateTime.friday:
          date = 'label_date_friday'.l10n;
          break;

        case DateTime.saturday:
          date = 'label_date_saturday'.l10n;
          break;

        case DateTime.sunday:
          date = 'label_date_sunday'.l10n;
          break;

        default:
          break;
      }

      if (days > 1) {
        date = '$date, ${'label_date'.l10nfmt({
              'day': day.toString().padLeft(2, '0'),
              'month': month.toString().padLeft(2, '0'),
              'year': year.toString(),
            })}';
      }
    }

    return date;
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

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
        // etc.
      };
}

class MyCustomClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const cornerR = 20.0;
    const radius = 10.0;

    final path = Path();

    path.moveTo(cornerR, 0);

    path.lineTo(size.width - cornerR, 0);
    path.arcToPoint(
      Offset(size.width, cornerR),
      radius: const Radius.circular(cornerR),
      clockwise: false,
    );

    path.lineTo(
      size.width,
      size.height - radius,
    );

    path.cubicTo(
      size.width,
      size.height - radius,
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );

    path.lineTo(radius, size.height);

    path.cubicTo(
      radius,
      size.height,
      0,
      size.height,
      0,
      size.height - radius,
    );

    path.lineTo(0, radius);

    path.cubicTo(
      0,
      radius,
      0,
      0,
      radius,
      0,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class AllowMultipleHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}
