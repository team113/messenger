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
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/application_settings.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/chat_item_quote.dart';
import 'package:messenger/domain/model/chat_item_quote_input.dart';
import 'package:messenger/ui/page/home/widget/confirm_dialog.dart';
import 'package:messenger/ui/page/home/widget/retry_image.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/selected_dot.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/animated_delayed_scale.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/highlighted_container.dart';
import '/ui/page/home/widget/unblock_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'forward/view.dart';
import 'get_paid/controller.dart';
import 'get_paid/view.dart';
import 'message_field/controller.dart';
import 'widget/back_button.dart';
import 'widget/chat_forward.dart';
import 'widget/chat_item.dart';
import 'widget/chat_subtitle.dart';
import 'widget/custom_drop_target.dart';
import 'widget/paid_notification.dart';
import 'widget/square_button.dart';
import 'widget/swipeable_status.dart';
import 'widget/time_label.dart';
import 'widget/unread_label.dart';

/// View of the [Routes.chats] page.
class ChatView extends StatefulWidget {
  const ChatView(this.id, {super.key, this.itemId, this.welcome});

  /// ID of this [Chat].
  final ChatId id;

  /// ID of a [ChatItem] to scroll to initially in this [ChatView].
  final ChatItemId? itemId;

  // TODO: Remove when backend supports it out of the box.
  /// [ChatMessageText] serving as a welcome message to display in this [Chat].
  final ChatMessageText? welcome;

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
    final style = Theme.of(context).style;

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
        Get.find(),
        itemId: widget.itemId,
        welcome: widget.welcome,
      ),
      tag: widget.id.val,
      global: !Get.isRegistered<ChatController>(tag: widget.id.val),
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
              appBar: const CustomAppBar(
                padding: EdgeInsets.only(left: 4, right: 20),
                leading: [StyledBackButton()],
              ),
              body: const Center(child: CustomProgressIndicator.primary()),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _bottomBar(c),
              ),
            );
          }

          final bool isMonolog = c.chat?.chat.value.isMonolog == true;
          final bool hasCall = c.chat?.chat.value.ongoingCall != null;

          return CustomDropTarget(
            key: Key('ChatView_${widget.id}'),
            onDragDone: (details) => c.dropFiles(details),
            onDragEntered: (_) => c.isDraggingFiles.value = true,
            onDragExited: (_) => c.isDraggingFiles.value = false,
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Stack(
                children: [
                  LayoutBuilder(builder: (context, constraints) {
                    return Scaffold(
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
                                    radius: AvatarRadius.medium,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Obx(() {
                                        return Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                c.chat!.title.value,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            Obx(() {
                                              if (c.chat?.chat.value.muted ==
                                                  null) {
                                                return const SizedBox();
                                              }

                                              return const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 5),
                                                child: SvgIcon(SvgIcons.muted),
                                              );
                                            }),
                                          ],
                                        );
                                      }),
                                      if (!isMonolog && c.chat != null)
                                        ChatSubtitle(c.chat!, c.me),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                        padding: const EdgeInsets.only(left: 4, right: 0),
                        leading: const [StyledBackButton()],
                        actions: [
                          Obx(() {
                            if (c.chat?.blacklisted == true) {
                              return const SizedBox.shrink();
                            }

                            final List<Widget> children;

                            if (c.chat!.chat.value.ongoingCall == null) {
                              children = [
                                if (c.mediaButtons == null ||
                                    c.mediaButtons ==
                                        MediaButtonsPosition.appBar) ...[
                                  AnimatedButton(
                                    onPressed: () => c.call(true),
                                    child:
                                        const SvgIcon(SvgIcons.chatVideoCall),
                                  ),
                                  const SizedBox(width: 28),
                                  AnimatedButton(
                                    key: const Key('AudioCall'),
                                    onPressed: () => c.call(false),
                                    child:
                                        const SvgIcon(SvgIcons.chatAudioCall),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ];
                            } else {
                              final Widget child;

                              if (c.inCall) {
                                child = Container(
                                  key: const Key('Drop'),
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    color: style.colors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SvgIcon(SvgIcons.callEnd),
                                  ),
                                );
                              } else {
                                child = Container(
                                  key: const Key('Join'),
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    color: style.colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SvgIcon(SvgIcons.callStart),
                                  ),
                                );
                              }

                              children = [
                                AnimatedButton(
                                  key: const Key('ActiveCallButton'),
                                  onPressed: c.inCall ? c.dropCall : c.joinCall,
                                  child: SafeAnimatedSwitcher(
                                    duration: 300.milliseconds,
                                    child: child,
                                  ),
                                ),
                              ];
                            }

                            return Row(
                              children: [
                                if (c.paid) ...[
                                  AnimatedOpacity(
                                    opacity:
                                        c.paidDisclaimerDismissed.value ? 1 : 0,
                                    duration: 300.milliseconds,
                                    child: WidgetButton(
                                      onPressed: () {
                                        c.paidDisclaimerDismissed.value = false;
                                        c.paidDisclaimer.value = true;
                                      },
                                      child: const SvgIcon(SvgIcons.paidChat),
                                    ),
                                  ),
                                  if (children.isNotEmpty)
                                    const SizedBox(width: 25),
                                ],
                                ...children,
                                // const SizedBox(width: 28 - 8),
                                Obx(() {
                                  final bool muted =
                                      c.chat?.chat.value.muted != null;
                                  final bool dialog =
                                      c.chat?.chat.value.isDialog == true;
                                  final bool monolog =
                                      c.chat?.chat.value.isMonolog == true;

                                  final bool favorite =
                                      c.chat?.chat.value.favoritePosition !=
                                          null;

                                  final bool contact = c.inContacts.value;

                                  final Widget child;

                                  if (c.selecting.value) {
                                    child = Container(
                                      padding: const EdgeInsets.only(
                                        left: 10,
                                        right: 0,
                                      ),
                                      key: c.moreKey,
                                      height: double.infinity,
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(10, 0, 21, 0),
                                        child: SvgIcon(SvgIcons.closePrimary),
                                      ),
                                    );
                                  } else {
                                    child = ContextMenuRegion(
                                      key: c.moreKey,
                                      selector: c.moreKey,
                                      alignment: Alignment.topRight,
                                      enablePrimaryTap: true,
                                      margin: const EdgeInsets.only(
                                        bottom: 4,
                                        right: 10,
                                      ),
                                      actions: [
                                        if (c.mediaButtons ==
                                            MediaButtonsPosition
                                                .contextMenu) ...[
                                          ContextMenuButton(
                                            label: 'btn_audio_call'.l10n,
                                            onPressed: hasCall
                                                ? null
                                                : () => c.call(false),
                                            trailing: SvgIcon(
                                              hasCall
                                                  ? SvgIcons
                                                      .makeAudioCallDisabled
                                                  : SvgIcons.makeAudioCall,
                                            ),
                                          ),
                                          ContextMenuButton(
                                            label: 'btn_video_call'.l10n,
                                            onPressed: hasCall
                                                ? null
                                                : () => c.call(true),
                                            trailing: Transform.translate(
                                              offset: const Offset(2, 0),
                                              child: SvgIcon(
                                                hasCall
                                                    ? SvgIcons
                                                        .makeVideoCallDisabled
                                                    : SvgIcons.makeVideoCall,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (dialog) ...[
                                          ContextMenuButton(
                                            label: 'btn_set_price'.l10n,
                                            onPressed: () => GetPaidView.show(
                                              context,
                                              mode: GetPaidMode.user,
                                              user: c.chat!.members.values
                                                  .firstWhere(
                                                (e) => e.id != c.me,
                                              ),
                                            ),
                                            trailing:
                                                const SvgIcon(SvgIcons.coin),
                                            inverted: const SvgIcon(
                                                SvgIcons.coinWhite),
                                          ),
                                          ContextMenuButton(
                                            label: contact
                                                ? 'btn_delete_from_contacts'
                                                    .l10n
                                                : 'btn_add_to_contacts'.l10n,
                                            onPressed: contact
                                                ? c.removeFromContacts
                                                : c.addToContacts,
                                            trailing: SvgIcon(
                                              contact
                                                  ? SvgIcons.deleteContact
                                                  : SvgIcons.addContact,
                                            ),
                                            inverted: SvgIcon(
                                              contact
                                                  ? SvgIcons.deleteContactWhite
                                                  : SvgIcons.addContactWhite,
                                            ),
                                          ),
                                        ],
                                        ContextMenuButton(
                                          label: favorite
                                              ? 'btn_delete_from_favorites'.l10n
                                              : 'btn_add_to_favorites'.l10n,
                                          onPressed: favorite
                                              ? c.unfavoriteChat
                                              : c.favoriteChat,
                                          trailing: SvgIcon(
                                            favorite
                                                ? SvgIcons.favoriteSmall
                                                : SvgIcons.unfavoriteSmall,
                                          ),
                                          inverted: SvgIcon(
                                            favorite
                                                ? SvgIcons.favoriteSmallWhite
                                                : SvgIcons.unfavoriteSmallWhite,
                                          ),
                                        ),
                                        if (!monolog)
                                          ContextMenuButton(
                                            label: muted
                                                ? PlatformUtils.isMobile
                                                    ? 'btn_unmute'.l10n
                                                    : 'btn_unmute_chat'.l10n
                                                : PlatformUtils.isMobile
                                                    ? 'btn_mute'.l10n
                                                    : 'btn_mute_chat'.l10n,
                                            onPressed: muted
                                                ? c.unmuteChat
                                                : c.muteChat,
                                            trailing: SvgIcon(
                                              muted
                                                  ? SvgIcons.unmuteSmall
                                                  : SvgIcons.muteSmall,
                                            ),
                                            inverted: SvgIcon(
                                              muted
                                                  ? SvgIcons.unmuteSmallWhite
                                                  : SvgIcons.muteSmallWhite,
                                            ),
                                          ),
                                        ContextMenuButton(
                                          label: 'btn_clear_history'.l10n,
                                          trailing: const SvgIcon(
                                            SvgIcons.cleanHistory,
                                          ),
                                          inverted: const SvgIcon(
                                            SvgIcons.cleanHistoryWhite,
                                          ),
                                          onPressed: () {},
                                        ),
                                        if (!monolog && !dialog)
                                          ContextMenuButton(
                                            onPressed: () {},
                                            label: 'btn_leave_group'.l10n,
                                            trailing: const SvgIcon(
                                              SvgIcons.leaveGroup,
                                            ),
                                            inverted: const SvgIcon(
                                              SvgIcons.leaveGroupWhite,
                                            ),
                                          ),
                                        ContextMenuButton(
                                          label: 'btn_delete_chat'.l10n,
                                          trailing:
                                              const SvgIcon(SvgIcons.delete19),
                                          inverted: const SvgIcon(
                                            SvgIcons.delete19White,
                                          ),
                                          onPressed: () {},
                                        ),
                                        if (!monolog) ...[
                                          ContextMenuButton(
                                            label: 'btn_block'.l10n,
                                            trailing:
                                                const SvgIcon(SvgIcons.block),
                                            inverted: const SvgIcon(
                                              SvgIcons.blockWhite,
                                            ),
                                            onPressed: () {},
                                          ),
                                          // ContextMenuButton(
                                          //   onPressed: () {},
                                          //   label: 'btn_report'.l10n,
                                          //   trailing: const SvgIcon(
                                          //     SvgIcons.report,
                                          //   ),
                                          // ),
                                        ],
                                        ContextMenuButton(
                                          label: 'btn_select_messages'.l10n,
                                          onPressed: c.selecting.toggle,
                                          trailing: const SvgIcon(
                                            SvgIcons.select,
                                          ),
                                          inverted: const SvgIcon(
                                            SvgIcons.selectWhite,
                                          ),
                                        ),
                                      ],
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 0,
                                        ),
                                        height: double.infinity,
                                        child: const Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(10, 0, 21, 0),
                                          child: SvgIcon(SvgIcons.more),
                                        ),
                                      ),
                                    );
                                  }

                                  return AnimatedButton(
                                    onPressed: c.selecting.value
                                        ? c.selecting.toggle
                                        : null,
                                    child: SafeAnimatedSwitcher(
                                      duration: 250.milliseconds,
                                      child: child,
                                    ),
                                  );
                                }),
                              ],
                            );
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
                                            _animation.value =
                                                value.clamp(0, 1);

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
                            onPointerCancel: (_) =>
                                c.scrollOffset = Offset.zero,
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

                                            _animation.value =
                                                value.clamp(0, 1);
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
                                    return AnimatedSizeAndFade.showHide(
                                      fadeDuration: 250.milliseconds,
                                      sizeDuration: 250.milliseconds,
                                      show: c.pinned.isNotEmpty,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: ContextMenuRegion(
                                              actions: [
                                                ContextMenuButton(
                                                  key: const Key('Unpin'),
                                                  label: PlatformUtils.isMobile
                                                      ? 'btn_unpin'.l10n
                                                      : 'btn_unpin_message'
                                                          .l10n,
                                                  trailing: const SvgIcon(
                                                    SvgIcons.unpinOutlined,
                                                  ),
                                                  inverted: const SvgIcon(
                                                    SvgIcons.unpinOutlinedWhite,
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
                                        ],
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
                                          final Widget child = FlutterListView(
                                            key: const Key('MessagesList'),
                                            controller: c.listController,
                                            physics: c.isHorizontalScroll
                                                        .isTrue ||
                                                    (PlatformUtils.isDesktop &&
                                                        c.isItemDragged.isTrue)
                                                ? const NeverScrollableScrollPhysics()
                                                : const BouncingScrollPhysics(),
                                            reverse: true,
                                            delegate: FlutterListViewDelegate(
                                              (context, i) =>
                                                  _listElement(context, c, i),
                                              childCount:
                                                  // ignore: invalid_use_of_protected_member
                                                  c.elements.value.length,
                                              stickyAtTailer: true,
                                              keepPosition: true,
                                              keepPositionOffset: c
                                                      .active.isTrue
                                                  ? c.keepPositionOffset.value
                                                  : 1,
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
                                              disableCacheItems:
                                                  kDebugMode ? true : false,
                                            ),
                                          );

                                          if (PlatformUtils.isMobile) {
                                            if (!PlatformUtils.isWeb) {
                                              return Scrollbar(
                                                controller: c.listController,
                                                child: child,
                                              );
                                            } else {
                                              return child;
                                            }
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
                                          if ((c.chat?.status.value.isSuccess ==
                                                      true ||
                                                  c.chat?.status.value
                                                          .isEmpty ==
                                                      true) &&
                                              c.chat?.messages.isEmpty ==
                                                  true) {
                                            return Center(
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  border:
                                                      style.systemMessageBorder,
                                                  color:
                                                      style.systemMessageColor,
                                                ),
                                                child: Text(
                                                  key: const Key('NoMessages'),
                                                  isMonolog
                                                      ? 'label_chat_monolog_description'
                                                          .l10n
                                                      : 'label_no_messages'
                                                          .l10n,
                                                  textAlign: TextAlign.center,
                                                  style: style.fonts.small
                                                      .regular.onBackground,
                                                ),
                                              ),
                                            );
                                          }

                                          if (c.chat?.status.value.isLoading !=
                                              false) {
                                            return const Center(
                                              child: CustomProgressIndicator
                                                  .primary(),
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
                          if (c.mediaButtons == MediaButtonsPosition.top ||
                              c.mediaButtons == MediaButtonsPosition.bottom)
                            Positioned(
                              top: c.mediaButtons == MediaButtonsPosition.top
                                  ? 8
                                  : null,
                              bottom:
                                  c.mediaButtons == MediaButtonsPosition.bottom
                                      ? 8
                                      : null,
                              right: 12,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  SquareButton(
                                    hasCall
                                        ? SvgIcons.chatAudioCallDisabled
                                        : SvgIcons.chatAudioCall,
                                    onPressed:
                                        hasCall ? null : () => c.call(false),
                                  ),
                                  const SizedBox(height: 8),
                                  SquareButton(
                                    hasCall
                                        ? SvgIcons.chatVideoCallDisabled
                                        : SvgIcons.chatVideoCall,
                                    onPressed:
                                        hasCall ? null : () => c.call(true),
                                  ),
                                  const SizedBox(height: 8),
                                ],
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
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _bottomBar(c),
                      ),
                    );
                  }),
                  IgnorePointer(
                    child: Obx(() {
                      return SafeAnimatedSwitcher(
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
                                        child: const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: SvgIcon(SvgIcons.addBigger),
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

  Widget _selectable(
    BuildContext context,
    ChatController c, {
    required ListElement item,
    required bool overlay,
    required Widget child,
  }) {
    return Obx(() {
      // if (!c.selecting.value) {
      //   return child;
      // }

      final bool selected = c.selected.contains(item);

      return WidgetButton(
        onPressed: c.selecting.value
            ? selected
                ? () => c.selected.remove(item)
                : () => c.selected.add(item)
            : null,
        child: Stack(
          children: [
            // Container(color: Colors.red, width: 75, height: 36),
            Row(
              children: [
                Expanded(
                  child:
                      IgnorePointer(ignoring: c.selecting.value, child: child),
                ),
                if (!overlay)
                  AnimatedSize(
                    duration: 150.milliseconds,
                    child: c.selecting.value
                        ? const SizedBox(key: Key('Expanded'), width: 32)
                        : const SizedBox(),
                  ),
              ],
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: c.selecting.value
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SelectedDot(selected: selected),
                      )
                    : const SizedBox(),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Builds a visual representation of a [ListElement] identified by the
  /// provided index.
  Widget _listElement(BuildContext context, ChatController c, int i) {
    final style = Theme.of(context).style;

    ListElement element = c.elements.values.elementAt(i);
    bool isLast = i == 0;

    ListElement? previous;
    bool previousSame = false;

    if (element is ChatMessageElement ||
        element is ChatCallElement ||
        element is ChatInfoElement ||
        element is ChatForwardElement) {
      if (i < c.elements.length - 1) {
        previous = c.elements.values.elementAt(i + 1);
        if (previous is LoaderElement && i < c.elements.length - 2) {
          previous = c.elements.values.elementAt(i + 2);
        }
      }

      if (previous != null) {
        UserId author;

        if (element is ChatMessageElement) {
          author = element.item.value.author.id;
        } else if (element is ChatCallElement) {
          author = element.item.value.author.id;
        } else if (element is ChatInfoElement) {
          author = element.item.value.author.id;
        } else if (element is ChatForwardElement) {
          author = element.authorId;
        } else {
          throw Exception('Unreachable');
        }

        previousSame = (previous is ChatMessageElement &&
                previous.item.value.author.id == author &&
                element.id.at.val
                        .difference(previous.item.value.at.val)
                        .abs() <=
                    const Duration(minutes: 5)) ||
            (previous is ChatCallElement &&
                previous.item.value.author.id == author &&
                element.id.at.val
                        .difference(previous.item.value.at.val)
                        .abs() <=
                    const Duration(minutes: 5)) ||
            (previous is ChatForwardElement &&
                previous.authorId == author &&
                element.id.at.val.difference(previous.id.at.val).abs() <=
                    const Duration(minutes: 5));
      }
    }

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

      final FutureOr<RxUser?> user = c.getUser(e.value.author.id);

      return Padding(
        padding: EdgeInsets.only(
          top: previousSame || previous is UnreadMessagesElement ? 0 : 9,
          bottom: isLast ? ChatController.lastItemBottomOffset : 0,
        ),
        child: FutureBuilder<RxUser?>(
          future: user is Future<RxUser?> ? user : null,
          builder: (_, snapshot) => Obx(() {
            return HighlightedContainer(
              highlight:
                  c.highlightIndex.value == i || c.selected.contains(element),
              padding: const EdgeInsets.fromLTRB(8, 1.5, 8, 1.5),
              child: _selectable(
                context,
                c,
                item: element,
                overlay:
                    e.value.author.id != c.me || element is ChatInfoElement,
                child: ChatItemWidget(
                  chat: c.chat!.chat,
                  item: e,
                  me: c.me!,
                  paid: c.paid,
                  avatar: !previousSame,
                  loadImages: c.settings.value?.loadImages != false,
                  reads: c.chat!.members.length > 10
                      ? []
                      : c.chat!.reads.where((m) =>
                          m.at == e.value.at &&
                          m.memberId != c.me &&
                          m.memberId != e.value.author.id),
                  user: snapshot.data ?? (user is RxUser? ? user : null),
                  getUser: c.getUser,
                  animation: _animation,
                  timestamp: c.settings.value?.timelineEnabled != true,
                  onHide: () => c.hideChatItem(e.value),
                  onDelete: () => c.deleteMessage(e.value),
                  onReply: c.edit.value?.edited.value?.id != e.value.id
                      ? () {
                          final field = c.edit.value ?? c.send;

                          if (field.replied.any((i) => i.id == e.value.id)) {
                            field.replied
                                .removeWhere((i) => i.id == e.value.id);
                          } else {
                            field.replied.insert(0, e.value);
                          }
                        }
                      : null,
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
                  onSelect: c.selecting.toggle,
                  pinned: c.pinned.contains(e.value),
                  onPin: () {
                    c.pinned.contains(e.value)
                        ? c.unpin(c.pinned.indexOf(e.value))
                        : c.pin(e.value);
                  },
                ),
              ),
            );
          }),
        ),
      );
    } else if (element is ChatForwardElement) {
      final FutureOr<RxUser?> user = c.getUser(element.authorId);

      return Padding(
        padding: EdgeInsets.only(
          top: previousSame || previous is UnreadMessagesElement ? 0 : 9,
          bottom: isLast ? ChatController.lastItemBottomOffset : 0,
        ),
        child: FutureBuilder<RxUser?>(
          future: user is Future<RxUser?> ? user : null,
          builder: (_, snapshot) => Obx(() {
            return HighlightedContainer(
              highlight:
                  c.highlightIndex.value == i || c.selected.contains(element),
              padding: const EdgeInsets.fromLTRB(8, 1.5, 8, 1.5),
              child: _selectable(
                context,
                c,
                item: element,
                overlay: element.authorId != c.me,
                child: ChatForwardWidget(
                  key: Key('ChatForwardWidget_${element.id}'),
                  chat: c.chat!.chat,
                  forwards: element.forwards,
                  note: element.note,
                  authorId: element.authorId,
                  me: c.me!,
                  paid: c.paid,
                  loadImages: c.settings.value?.loadImages != false,
                  reads: c.chat!.members.length > 10
                      ? []
                      : c.chat!.reads.where((m) =>
                          m.at == element.forwards.last.value.at &&
                          m.memberId != c.me &&
                          m.memberId != element.authorId),
                  user: snapshot.data ?? (user is RxUser? ? user : null),
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
                    if (element.forwards.any((e) =>
                            c.send.replied.any((i) => i.id == e.value.id)) ||
                        c.send.replied
                            .any((i) => i.id == element.note.value?.value.id)) {
                      for (Rx<ChatItem> e in element.forwards) {
                        c.send.replied.removeWhere((i) => i.id == e.value.id);
                      }

                      if (element.note.value != null) {
                        c.send.replied.removeWhere(
                          (i) => i.id == element.note.value!.value.id,
                        );
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
                  onSelect: c.selecting.toggle,
                  pinned: c.pinned.contains(element.forwards.first.value),
                  onPin: () {
                    c.pinned.contains(element.forwards.first.value)
                        ? c.unpin(
                            c.pinned.indexOf(element.forwards.first.value))
                        : c.pin(element.forwards.first.value);
                  },
                ),
              ),
            );
          }),
        ),
      );
    } else if (element is DateTimeElement) {
      return SelectionContainer.disabled(
        child: Obx(() {
          return TimeLabelWidget(
            element.id.at.val,
            animation: _animation,
            opacity: c.stickyIndex.value == i && c.showSticky.isFalse ? 0 : 1,
          );
        }),
      );
    } else if (element is UnreadMessagesElement) {
      return SelectionContainer.disabled(child: UnreadLabel(c.unreadMessages));
    } else if (element is LoaderElement) {
      return Obx(() {
        final Widget child;

        if (c.showLoaders.value) {
          child = SizedBox.square(
            dimension: ChatController.loaderHeight,
            child: Center(
              key: const ValueKey(1),
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
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
            height: c.listController.position.pixels == 0
                ? isLast
                    ? ChatController.lastItemBottomOffset
                    : null
                : ChatController.loaderHeight,
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
      final style = Theme.of(context).style;

      const String text = 'dqwdqw';
      final String fee =
          fromMe ? 'Вы установили плату за:' : 'kirey установил плату за:';

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
                constraints: const BoxConstraints(
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
                                      const Row(
                                        children: [
                                          Text('- сообщения'),
                                          Spacer(),
                                          Text('\$5'),
                                        ],
                                      ),
                                      const Row(
                                        children: [
                                          Text('- звонки'),
                                          Spacer(),
                                          Text('\$5/min'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  10,
                                ),
                                child: Text(text,
                                    style: style
                                        .fonts.medium.regular.onBackground),
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
    } else if (element is InfoElement) {
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
            'Lorem ipsum dolor sit ame',
            style: style.systemMessageStyle,
          ),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _paidElement(
    ChatController c,
    double messageCost,
    double callCost, {
    User? user,
  }) {
    final style = Theme.of(context).style;

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
                    color: Theme.of(context).colorScheme.primary,
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
//                       color: Theme.of(context).colorScheme.primary,
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
//     final style = Theme.of(context).style;
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
//                         color: Theme.of(context).colorScheme.primary,
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
    final style = Theme.of(context).style;

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
                style: style.fonts.medium.regular.onBackground,
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
              style: style.fonts.medium.regular.onBackground,
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
                      style: style.fonts.medium.regular.onBackground.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    if (quote.text != null)
                      TextSpan(text: 'semicolon_space'.l10n),
                    if (quote.text != null) TextSpan(text: quote.text!.val),
                  ],
                ),
                style: style.fonts.medium.regular.onBackground,
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
                style: style.fonts.medium.regular.onBackground,
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
              const SizedBox(height: 0),
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
                      child: const SvgIcon(SvgIcons.closeSmallPrimary),
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
                    //     // color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  // ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      );
    });
  }

  /// Returns a bottom bar of this [ChatView] to display under the messages list
  /// containing a send/edit field.
  Widget _bottomBar(ChatController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      if (c.selecting.value) {
        final bool canForward = c.selected.isNotEmpty &&
            !c.selected
                .any((e) => e is ChatCallElement || e is ChatInfoElement);
        final bool canDelete = c.selected.isNotEmpty;

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(
              borderRadius: style.cardRadius,
              boxShadow: [
                CustomBoxShadow(
                  blurRadius: 8,
                  color: style.colors.onBackgroundOpacity13,
                ),
              ],
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 57),
              decoration: BoxDecoration(
                borderRadius: style.cardRadius,
                color: style.cardColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 20),
                  AnimatedButton(
                    enabled: canForward,
                    onPressed: canForward
                        ? () async {
                            final result = await ChatForwardView.show(
                              router.context!,
                              c.id,
                              c.selectedAsItems
                                  .map((e) => ChatItemQuoteInput(item: e))
                                  .toList(),
                            );

                            if (result == true) {
                              c.selecting.value = false;
                            }
                          }
                        : null,
                    child: SafeAnimatedSwitcher(
                      duration: 150.milliseconds,
                      child: SvgIcon(
                        key: Key(canForward ? '0' : '1'),
                        canForward
                            ? SvgIcons.forward
                            : SvgIcons.forwardDisabled,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    enabled: canDelete,
                    onPressed: canDelete
                        ? () async {
                            final bool deletable =
                                c.chat?.chat.value.isMonolog == true ||
                                    c.selected.every((e) {
                                      if (e is ChatMessageElement) {
                                        return e.item.value.author.id == c.me &&
                                            c.chat?.chat.value.isRead(
                                                  e.item.value,
                                                  c.me,
                                                ) ==
                                                false;
                                      } else if (e is ChatForwardElement) {
                                        return e.authorId == c.me &&
                                            c.chat?.chat.value.isRead(
                                                  e.forwards.first.value,
                                                  c.me,
                                                ) ==
                                                false;
                                      } else if (e is ChatInfoElement) {
                                        return false;
                                      } else if (e is ChatCallElement) {
                                        return false;
                                      }

                                      return false;
                                    });

                            final result = await ConfirmDialog.show(
                              context,
                              title: 'label_delete_message'.l10n,
                              description: deletable
                                  ? null
                                  : 'label_message_will_deleted_for_you'.l10n,
                              initial: 1,
                              variants: [
                                ConfirmDialogVariant(
                                  key: const Key('HideForMe'),
                                  label: 'label_delete_for_me'.l10n,
                                  onProceed: () async {
                                    return await Future.wait(
                                      c.selectedAsItems.map(c.hideChatItem),
                                    );
                                  },
                                ),
                                if (deletable)
                                  ConfirmDialogVariant(
                                    key: const Key('DeleteForAll'),
                                    label: 'label_delete_for_everyone'.l10n,
                                    onProceed: () async {
                                      return await Future.wait(
                                        c.selectedAsItems.map(c.deleteMessage),
                                      );
                                    },
                                  )
                              ],
                            );

                            if (result != null) {
                              c.selecting.value = false;
                            }
                          }
                        : null,
                    child: SafeAnimatedSwitcher(
                      duration: 150.milliseconds,
                      child: SvgIcon(
                        key: Key(canDelete ? '0' : '1'),
                        canDelete
                            ? SvgIcons.deleteBig
                            : SvgIcons.deleteBigDisabled,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 24),
                  if (c.elements.isEmpty)
                    const SelectedDot(
                      selected: false,
                      inverted: false,
                      outlined: true,
                      size: 21,
                    )
                  else
                    Obx(() {
                      final bool selected = c.elements.values.every((e) {
                        if (e is ChatMessageElement ||
                            e is ChatInfoElement ||
                            e is ChatCallElement ||
                            e is ChatForwardElement) {
                          return c.selected.contains(e);
                        }

                        return true;
                      });

                      return AnimatedButton(
                        onPressed: () {
                          if (selected) {
                            c.selected.clear();
                          } else {
                            for (var e in c.elements.values) {
                              if (e is ChatMessageElement ||
                                  e is ChatInfoElement ||
                                  e is ChatCallElement ||
                                  e is ChatForwardElement) {
                                if (!c.selected.contains(e)) {
                                  c.selected.add(e);
                                }
                              }
                            }
                          }
                        },
                        child: SelectedDot(
                          selected: selected,
                          inverted: false,
                          outlined: !selected,
                          size: 21,
                        ),
                      );
                    }),
                  // AnimatedButton(
                  //   onPressed: c.selecting.toggle,
                  //   child: const SvgIcon(SvgIcons.closePrimary),
                  // ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        );
      }

      if (c.chat?.blacklisted == true) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: UnblockButton(c.unblacklist),
          ),
        );
      }

      if (c.edit.value != null) {
        return Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: SafeArea(
            child: MessageFieldView(
              key: const Key('EditField'),
              controller: c.edit.value,
              onItemPressed: (id) =>
                  c.animateTo(id, offsetBasedOnBottom: false),
            ),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final Widget child;

            if (c.paidDisclaimer.value) {
              child = PaidNotification(
                accepted: c.paidAccepted.value,
                border: c.paidBorder.value
                    ? Border.all(color: style.colors.primary, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
                onPressed: () {
                  c.paidDisclaimer.value = false;
                  c.paidDisclaimerDismissed.value = true;
                  c.paidBorder.value = false;
                  c.paidAccepted.value = true;
                },
              );
            } else if (c.emailNotValidated.value) {
              final RxUser? user = c.chat?.members.values
                  .firstWhereOrNull((e) => e.user.value.id != c.me);

              child = PaidNotification(
                description:
                    'Чат с пользователем ${user?.user.value.name?.val ?? user?.user.value.num.val} недоступен, т.к. Ваш E-mail не верифицирован.',
                action: 'label_verify_email'.l10n,
                border: c.paidBorder.value
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.transparent,
                        width: 2,
                      ),
                onPressed: () {
                  router.profileSection.value = ProfileTab.signing;
                  router.me(push: true);
                },
              );
            } else {
              child = const SizedBox(width: double.infinity);
            }

            return AnimatedSizeAndFade(child: child);
          }),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: SafeArea(
              child: MessageFieldView(
                key: const Key('SendField'),
                controller: c.send,
                onChanged:
                    c.chat?.chat.value.isMonolog == true ? null : c.keepTyping,
                onItemPressed: (id) =>
                    c.animateTo(id, offsetBasedOnBottom: false),
                canForward: true,
              ),
            ),
          ),
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
