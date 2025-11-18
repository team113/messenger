// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/animated_delayed_scale.dart';
import '/ui/page/call/widget/fit_view.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/highlighted_container.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/page/home/widget/scroll_keyboard_handler.dart';
import '/ui/page/home/widget/unblock_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/checkbox_button.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/future_or_builder.dart';
import '/ui/widget/obscured_menu_interceptor.dart';
import '/ui/widget/obscured_selection_area.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/safe_area/safe_area.dart';
import '/ui/widget/selected_dot.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/system_info_prompt.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'forward/view.dart';
import 'message_field/controller.dart';
import 'widget/back_button.dart';
import 'widget/chat_forward.dart';
import 'widget/chat_item.dart';
import 'widget/chat_subtitle.dart';
import 'widget/custom_drop_target.dart';
import 'widget/notes_block.dart';
import 'widget/time_label.dart';
import 'widget/unread_label.dart';
import 'widget/with_global_key.dart';

/// View of the [Routes.chats] page.
class ChatView extends StatelessWidget {
  const ChatView(this.id, {super.key, this.itemId});

  /// ID of this [Chat].
  final ChatId id;

  /// ID of a [ChatItem] to scroll to initially in this [ChatView].
  final ChatItemId? itemId;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder<ChatController>(
      key: const Key('ChatView'),
      init: ChatController(
        id,
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        itemId: itemId,
        onContext: () => context,
      ),
      tag: id.val,
      global: !Get.isRegistered<ChatController>(tag: id.val),
      builder: (c) {
        // Opens [Routes.chatInfo] or [Routes.user] page basing on the
        // [Chat.isGroup] indicator.
        void onDetailsTap() {
          final Chat? chat = c.chat?.chat.value;
          if (chat != null) {
            if (chat.isGroup || chat.isMonolog) {
              router.chatInfo(chat.id, push: true);
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
              appBar: const CustomAppBar(
                padding: EdgeInsets.only(left: 4, right: 20),
                leading: [StyledBackButton()],
              ),
              body: Center(
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
                    'label_no_chat_found'.l10n,
                    style: style.systemMessageStyle,
                  ),
                ),
              ),
            );
          } else if (!c.status.value.isSuccess) {
            return Scaffold(
              appBar: const CustomAppBar(
                padding: EdgeInsets.only(left: 4, right: 20),
                leading: [StyledBackButton()],
              ),
              body: const Center(child: CustomProgressIndicator.primary()),
              bottomNavigationBar: _bottomBar(c, context),
            );
          }

          final bool isMonolog = c.chat!.chat.value.isMonolog;

          return CustomDropTarget(
            key: Key('ChatView_$id'),
            onPerformDrop: c.dropFiles,
            builder: (dragging) => GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Stack(
                children: [
                  Scaffold(
                    resizeToAvoidBottomInset: true,
                    appBar: CustomAppBar(
                      title: Obx(() {
                        if (c.searching.value) {
                          return Theme(
                            data: MessageFieldView.theme(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Transform.translate(
                                offset: const Offset(0, 1),
                                child: ReactiveTextField(
                                  key: const Key('SearchItemsField'),
                                  state: c.search,
                                  hint: 'label_search'.l10n,
                                  maxLines: 1,
                                  filled: false,
                                  dense: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  style:
                                      style.fonts.medium.regular.onBackground,
                                  onChanged: () {
                                    c.query.value = c.search.text;
                                    if (c.search.text.isEmpty) {
                                      c.switchToMessages();
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }

                        return Row(
                          children: [
                            WidgetButton(
                              onPressed: onDetailsTap,
                              child: Center(
                                child: AvatarWidget.fromRxChat(
                                  c.chat,
                                  radius: AvatarRadius.big,
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
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Obx(() {
                                              return Text(
                                                c.chat!.title(),
                                                style: style
                                                    .fonts
                                                    .big
                                                    .regular
                                                    .onBackground,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              );
                                            }),
                                          ),
                                          Obx(() {
                                            if (c.chat?.chat.value.muted ==
                                                null) {
                                              return const SizedBox();
                                            }

                                            return const Padding(
                                              padding: EdgeInsets.only(left: 5),
                                              child: SvgIcon(SvgIcons.muted),
                                            );
                                          }),
                                        ],
                                      ),
                                      if (!isMonolog)
                                        ChatSubtitle(c.chat!, c.me),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        );
                      }),
                      padding: const EdgeInsets.only(left: 4),
                      leading: [
                        Obx(() {
                          if (c.searching.value) {
                            return const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: SvgIcon(SvgIcons.search),
                            );
                          }

                          return const StyledBackButton();
                        }),
                      ],
                      actions: [
                        Obx(() {
                          if (c.searching.value) {
                            return WidgetButton(
                              onPressed: () {
                                if (c.searching.value) {
                                  if (c.search.text.isNotEmpty) {
                                    c.search.clear();
                                    c.search.focus.requestFocus();
                                    c.switchToMessages();
                                  } else {
                                    c.toggleSearch();
                                  }
                                } else {
                                  c.toggleSearch();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 21, 8),
                                child: c.search.isEmpty.value
                                    ? const SvgIcon(SvgIcons.closePrimary)
                                    : const SvgIcon(SvgIcons.clearSearch),
                              ),
                            );
                          }

                          final bool blocked = c.chat?.blocked == true;
                          final bool inCall = c.chat?.inCall.value ?? false;
                          final bool isMonolog =
                              c.chat?.chat.value.isMonolog == true;

                          final List<Widget> children;

                          // Display the join/end call button, if [Chat] has an
                          // [OngoingCall] happening in it.
                          if (c.chat!.chat.value.ongoingCall != null) {
                            final Widget child;

                            if (inCall) {
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
                                onPressed: inCall ? c.dropCall : c.joinCall,
                                child: SafeAnimatedSwitcher(
                                  duration: 300.milliseconds,
                                  child: child,
                                ),
                              ),
                            ];
                          } else if (!blocked && !isMonolog) {
                            children = [
                              AnimatedButton(
                                onPressed: () => c.call(true),
                                child: const SvgIcon(SvgIcons.chatVideoCall),
                              ),
                              const SizedBox(width: 28),
                              AnimatedButton(
                                key: const Key('AudioCall'),
                                onPressed: () => c.call(false),
                                child: const SvgIcon(SvgIcons.chatAudioCall),
                              ),
                              const SizedBox(width: 10),
                            ];
                          } else {
                            // [Chat]-dialog is blocked, therefore no call
                            // buttons should be displayed.
                            children = [];
                          }

                          return Row(
                            children: [
                              ...children,
                              Obx(() {
                                // TODO: Uncomment, when contacts are
                                //       implemented.
                                // final bool contact =
                                //     c.user?.user.value.contacts.isNotEmpty ??
                                //         false;

                                final Widget child = ContextMenuRegion(
                                  key: c.moreKey,
                                  selector: c.moreKey,
                                  alignment: Alignment.topRight,
                                  enablePrimaryTap: true,
                                  margin: const EdgeInsets.only(
                                    bottom: 4,
                                    right: 12,
                                  ),
                                  actions: [
                                    ContextMenuButton(
                                      key: const Key('SearchItemsButton'),
                                      label: 'label_search'.l10n,
                                      onPressed: c.toggleSearch,
                                      trailing: const SvgIcon(SvgIcons.search),
                                      inverted: const SvgIcon(
                                        SvgIcons.searchWhite,
                                      ),
                                    ),

                                    if (!c.selecting.value)
                                      ContextMenuButton(
                                        label: 'btn_select_messages'.l10n,
                                        onPressed: c.selecting.toggle,
                                        trailing: const SvgIcon(
                                          SvgIcons.select,
                                        ),
                                        inverted: const SvgIcon(
                                          SvgIcons.selectWhite,
                                        ),
                                      )
                                    else
                                      ContextMenuButton(
                                        label: 'btn_cancel_selection'.l10n,
                                        onPressed: c.selecting.toggle,
                                        trailing: const SvgIcon(
                                          SvgIcons.unselect,
                                        ),
                                        inverted: const SvgIcon(
                                          SvgIcons.unselectWhite,
                                        ),
                                      ),
                                  ],
                                  child: Container(
                                    key: const Key('MoreButton'),
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 21,
                                    ),
                                    height: double.infinity,
                                    child: const SvgIcon(SvgIcons.more),
                                  ),
                                );

                                return AnimatedButton(
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
                        // Required for the [Stack] to take [Scaffold]'s
                        // size.
                        IgnorePointer(
                          child: ObscuredMenuInterceptor(child: Container()),
                        ),
                        Obx(() {
                          Widget child = FlutterListView(
                            key: const Key('MessagesList'),
                            controller: c.listController,
                            physics: c.isDraggingItem.value
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            reverse: true,
                            delegate: FlutterListViewDelegate(
                              (context, i) => _listElement(context, c, i),
                              // ignore: invalid_use_of_protected_member
                              childCount: c.elements.value.length,
                              stickyAtTailer: true,
                              keepPosition: true,
                              keepPositionOffset: c.active.isTrue
                                  ? c.keepPositionOffset.value
                                  : 1,
                              onItemKey: (i) =>
                                  c.elements.values.elementAt(i).id.toString(),
                              onItemSticky: (i) =>
                                  c.elements.values.elementAt(i)
                                      is DateTimeElement,
                              initIndex: c.initIndex,
                              initOffset: c.initOffset,
                              initOffsetBasedOnBottom: true,
                              disableCacheItems: kDebugMode ? true : false,
                            ),
                          );

                          child = ScrollKeyboardHandler(
                            scrollController: c.listController,
                            reversed: true,

                            // Only allow scrolling up when cursor is at the
                            // beginning of the input field.
                            scrollUpEnabled: () =>
                                c.send.field.controller.selection.baseOffset ==
                                    0 ||
                                c.send.field.isFocused.isFalse,

                            // Only allow scrolling up when cursor is at the end
                            // of the input field.
                            scrollDownEnabled: () =>
                                c.send.field.controller.selection.baseOffset ==
                                    c.send.field.controller.text.length ||
                                c.send.field.isFocused.isFalse,

                            child: child,
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

                          return ObscuredSelectionArea(
                            key: Key('${c.selecting.value}'),
                            onSelectionChanged: (a) => c.selection.value = a,
                            contextMenuBuilder: (_, _) => const SizedBox(),
                            selectionControls: EmptyTextSelectionControls(),
                            child: ObscuredMenuInterceptor(child: child),
                          );
                        }),
                        Obx(() {
                          if (c.searching.value) {
                            if (c.status.value.isLoadingMore) {
                              return const Center(
                                child: CustomProgressIndicator(),
                              );
                            }
                            // ignore: invalid_use_of_protected_member
                            else if (c.elements.value.isEmpty) {
                              return Center(
                                child: SystemInfoPrompt(
                                  key: const Key('NoMessages'),
                                  'label_no_messages'.l10n,
                                ),
                              );
                            }
                          }

                          if ((c.chat!.status.value.isSuccess ||
                                  c.chat!.status.value.isEmpty) &&
                              c.chat!.messages.isEmpty) {
                            final Widget? welcome = _welcomeMessage(context, c);

                            if (welcome != null) {
                              return Align(
                                alignment: Alignment.bottomLeft,
                                child: ListView(
                                  reverse: true,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 550,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 48,
                                          ),
                                          child: welcome,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (isMonolog) {
                              return NotesBlock(key: const Key('NoMessages'));
                            }

                            return Center(
                              child: SystemInfoPrompt(
                                key: const Key('NoMessages'),
                                'label_no_messages'.l10n,
                              ),
                            );
                          }

                          if (c.status.value.isLoading) {
                            return const Center(
                              child: CustomProgressIndicator(),
                            );
                          }

                          return const SizedBox();
                        }),
                      ],
                    ),
                    floatingActionButton: Obx(() {
                      return SizedBox(
                        width: 50,
                        height: 50,
                        child: SafeAnimatedSwitcher(
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
                    bottomNavigationBar: _bottomBar(c, context),
                  ),
                  IgnorePointer(
                    child: SafeAnimatedSwitcher(
                      duration: 200.milliseconds,
                      child: dragging
                          ? Container(
                              color: style.colors.onBackgroundOpacity27,
                              child: Center(
                                child: AnimatedDelayedScale(
                                  duration: const Duration(milliseconds: 300),
                                  beginScale: 1,
                                  endScale: 1.06,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: style.colors.onBackgroundOpacity27,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: SvgIcon(SvgIcons.addBigger),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
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

        previousSame =
            (previous is ChatMessageElement &&
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

      return Padding(
        padding: EdgeInsets.only(
          top: previousSame || previous is UnreadMessagesElement ? 0 : 9,
          bottom: isLast ? ChatController.lastItemBottomOffset : 0,
        ),
        child: FutureOrBuilder<RxUser?>(
          key: element.key,
          futureOr: () => c.getUser(e.value.author.id),
          builder: (_, user) => Obx(() {
            return HighlightedContainer(
              highlight:
                  c.highlighted.value == element.id ||
                  c.selected.contains(element),
              padding: const EdgeInsets.fromLTRB(8, 1.5, 8, 1.5),
              child: _selectable(
                context,
                c,
                item: element,
                child: ChatItemWidget(
                  chat: c.chat!.chat,
                  item: e,
                  me: c.me!,
                  withAvatar: !c.selecting.value && !previousSame,
                  withName: !previousSame,
                  appendAvatarPadding: !c.selecting.value,
                  selectable: !c.selecting.value,
                  reads: c.chat!.chat.value.membersCount > 10
                      ? []
                      : c.chat!.reads.where(
                          (m) =>
                              m.at == e.value.at &&
                              m.memberId != c.me &&
                              m.memberId != e.value.author.id,
                        ),
                  user: user,
                  getUser: c.getUser,
                  getItem: c.getItem,
                  onHide: () => c.hideChatItem(e.value),
                  onDelete: () => c.deleteMessage(e.value),
                  onReply: (item) {
                    final field = c.edit.value ?? c.send;

                    if (field.replied.any((i) => i.value.id == item.id)) {
                      field.replied.removeWhere((i) => i.value.id == item.id);
                    } else {
                      final ListElement? element =
                          c.elements[ListElementId(item.at, item.id)];

                      if (element is ChatMessageElement) {
                        field.replied.add(element.item);
                      } else if (element is ChatInfoElement) {
                        field.replied.add(element.item);
                      } else if (element is ChatCallElement) {
                        field.replied.add(element.item);
                      } else if (element is ChatForwardElement) {
                        field.replied.add(
                          element.note.value ?? element.forwards.first,
                        );
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
                  onAnimateTo: (item) async {
                    await c.animateTo(item.id, item: item);
                  },
                  onRepliedTap: (q) async {
                    if (q.original != null) {
                      await c.animateTo(e.value.id, item: e.value, reply: q);
                    }
                  },
                  onGallery: () => c.calculateGallery(e.value),
                  onResend: () => c.resendItem(e.value),
                  onEdit: () => c.editMessage(e.value),
                  onFileTap: (a) => c.downloadFile(e.value, a),
                  onAttachmentError: (item) async {
                    await c.chat?.updateAttachments(item ?? e.value);
                    await Future.delayed(Duration.zero);
                  },
                  onDownload: c.downloadMedia,
                  onDownloadAs: c.downloadMediaAs,
                  onSave: (a) => c.saveToGallery(a, e.value),
                  onSelect: () {
                    c.selecting.toggle();
                    c.selected.add(element);
                  },
                  onSearch: c.toggleSearch,
                  onUserPressed: (user) {
                    ChatId chatId = ChatId.local(user.id);
                    if (user.dialog.isLocalWith(c.me)) {
                      chatId = c.monolog;
                    }

                    router.chat(chatId, mode: RouteAs.push);
                  },
                  onDragging: (e) => c.isDraggingItem.value = e,
                ),
              ),
            );
          }),
        ),
      );
    } else if (element is ChatForwardElement) {
      return Padding(
        padding: EdgeInsets.only(
          top: previousSame || previous is UnreadMessagesElement ? 0 : 9,
          bottom: isLast ? ChatController.lastItemBottomOffset : 0,
        ),
        child: FutureOrBuilder<RxUser?>(
          key: element.key,
          futureOr: () => c.getUser(element.authorId),
          builder: (_, user) => Obx(() {
            return HighlightedContainer(
              highlight:
                  c.highlighted.value == element.id ||
                  c.selected.contains(element),
              padding: const EdgeInsets.fromLTRB(8, 1.5, 8, 1.5),
              child: _selectable(
                context,
                c,
                item: element,
                child: ChatForwardWidget(
                  key: Key('ChatForwardWidget_${element.id}'),
                  chat: c.chat!.chat,
                  forwards: element.forwards,
                  note: element.note,
                  authorId: element.authorId,
                  me: c.me!,
                  withAvatar: !c.selecting.value && !previousSame,
                  withName: !previousSame,
                  appendAvatarPadding: !c.selecting.value,
                  selectable: !c.selecting.value,
                  reads: c.chat!.chat.value.membersCount > 10
                      ? []
                      : c.chat!.reads.where(
                          (m) =>
                              m.at == element.forwards.last.value.at &&
                              m.memberId != c.me &&
                              m.memberId != element.authorId,
                        ),
                  user: user,
                  getUser: c.getUser,
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
                  onReply: (item) {
                    final MessageFieldController field = c.edit.value ?? c.send;

                    if (item != null) {
                      if (field.replied.any((i) => i.value.id == item.id)) {
                        field.replied.removeWhere((i) => i.value.id == item.id);
                      } else {
                        final ListElement? element =
                            c.elements[ListElementId(item.at, item.id)];

                        if (element is ChatMessageElement) {
                          field.replied.add(element.item);
                        } else if (element is ChatInfoElement) {
                          field.replied.add(element.item);
                        } else if (element is ChatCallElement) {
                          field.replied.add(element.item);
                        } else if (element is ChatForwardElement) {
                          field.replied.add(
                            element.note.value ?? element.forwards.first,
                          );
                        }
                      }
                      return;
                    }

                    if (element.forwards.any(
                          (e) => field.replied.any(
                            (i) => i.value.id == e.value.id,
                          ),
                        ) ||
                        field.replied.any(
                          (i) => i.value.id == element.note.value?.value.id,
                        )) {
                      for (Rx<ChatItem> e in element.forwards) {
                        field.replied.removeWhere(
                          (i) => i.value.id == e.value.id,
                        );
                      }

                      if (element.note.value != null) {
                        field.replied.removeWhere(
                          (i) => i.value.id == element.note.value!.value.id,
                        );
                      }
                    } else {
                      if (element.note.value != null) {
                        field.replied.add(element.note.value!);
                      }

                      for (Rx<ChatItem> e in element.forwards) {
                        field.replied.add(e);
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
                  onGallery: (m) => c.calculateGallery(m),
                  onEdit: () => c.editMessage(element.note.value!.value),
                  onForwardedTap: (item) {
                    if (item.quote.original != null) {
                      if (item.quote.original!.chatId == c.id) {
                        c.animateTo(item.id, item: item, forward: item.quote);
                      } else {
                        router.chat(
                          item.quote.original!.chatId,
                          itemId: item.quote.original!.id,
                          mode: RouteAs.push,
                        );
                      }
                    }
                  },
                  onFileTap: c.downloadFile,
                  onAttachmentError: (item) async {
                    if (item != null) {
                      await c.chat?.updateAttachments(item);
                      await Future.delayed(Duration.zero);
                      return;
                    }

                    for (ChatItem item in [
                      element.note.value?.value,
                      ...element.forwards.map((e) => e.value),
                    ].nonNulls) {
                      await c.chat?.updateAttachments(item);
                    }

                    await Future.delayed(Duration.zero);
                  },
                  onSelect: () {
                    c.selecting.toggle();
                    c.selected.add(element);
                  },
                  onDragging: (e) => c.isDraggingItem.value = e,
                  onAnimateTo: (item) async {
                    await c.animateTo(item.id, item: item);
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
                    color: style.colors.almostTransparent,
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
    }

    return const SizedBox();
  }

  /// Returns a bottom bar of this [ChatView] to display under the messages list
  /// containing a send/edit field.
  Widget _bottomBar(ChatController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      if (c.selecting.value) {
        final bool canForward =
            c.selected.isNotEmpty &&
            !c.selected.any(
              (e) => e is ChatCallElement || e is ChatInfoElement,
            );
        final bool canDelete = c.selected.isNotEmpty;

        return Container(
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
            decoration: BoxDecoration(color: style.cardColor),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 57),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20),
                      AnimatedButton(
                        key: const Key('ForwardButton'),
                        enabled: canForward,
                        onPressed: canForward
                            ? () async {
                                final items = c.selected.asItems
                                    .map((e) => ChatItemQuoteInput(item: e))
                                    .toList();

                                items.sort(
                                  (a, b) => b.item.at.compareTo(a.item.at),
                                );

                                final result = await ChatForwardView.show(
                                  context,
                                  c.id,
                                  items,
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
                        key: const Key('DeleteButton'),
                        enabled: canDelete,
                        onPressed: canDelete
                            ? () async {
                                final bool isMonolog =
                                    c.chat?.chat.value.isMonolog ?? false;

                                final bool deletable = c.selected.every((e) {
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

                                bool deleteForAll = false;

                                final bool? pressed = await MessagePopup.alert(
                                  c.selected.length > 1
                                      ? 'label_delete_messages'.l10n
                                      : 'label_delete_message'.l10n,
                                  description: [
                                    if (!deletable && !isMonolog)
                                      TextSpan(
                                        text: c.selected.length > 1
                                            ? 'label_message_will_deleted_for_you'
                                                  .l10n
                                            : 'label_messages_will_deleted_for_you'
                                                  .l10n,
                                      ),
                                  ],
                                  additional: [
                                    if (deletable && !isMonolog)
                                      StatefulBuilder(
                                        builder: (context, setState) {
                                          return RowCheckboxButton(
                                            key: const Key('DeleteForAll'),
                                            label:
                                                'label_also_delete_for_everyone'
                                                    .l10n,
                                            value: deleteForAll,
                                            onPressed: (e) => setState(
                                              () => deleteForAll = e,
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                  button: MessagePopup.deleteButton,
                                );

                                if (pressed ?? false) {
                                  if (deletable &&
                                      (isMonolog || deleteForAll)) {
                                    await Future.wait(
                                      c.selected.asItems.map(c.deleteMessage),
                                    );
                                  } else {
                                    await Future.wait(
                                      c.selected.asItems.map(c.hideChatItem),
                                    );
                                  }

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
                      AnimatedButton(
                        key: const Key('CancelSelecting'),
                        onPressed: c.selecting.toggle,
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 21, 0),
                          child: SvgIcon(SvgIcons.closePrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: max(CustomNavigationBar.height - 56, 0)),
              ],
            ),
          ),
        );
      }

      if (c.chat?.blocked == true) {
        return CustomSafeArea(child: UnblockButton(c.unblock));
      }

      if (c.edit.value != null) {
        return MessageFieldView(
          key: const Key('EditField'),
          controller: c.edit.value,
          onChanged: c.chat?.chat.value.isMonolog == true
              ? null
              : c.updateTyping,
          onItemPressed: (item) =>
              c.animateTo(item.id, item: item, addToHistory: false),
          onAttachmentError: c.chat?.updateAttachments,
          applySafeArea: true,
        );
      }

      return MessageFieldView(
        key: const Key('SendField'),
        controller: c.send,
        onChanged: c.chat?.chat.value.isMonolog == true ? null : c.updateTyping,
        onItemPressed: (item) =>
            c.animateTo(item.id, item: item, addToHistory: false),
        canForward: true,
        onAttachmentError: c.chat?.updateAttachments,
        applySafeArea: true,
      );
    });
  }

  /// Builds a selectable clickable overlay over the provided [child].
  Widget _selectable(
    BuildContext context,
    ChatController c, {
    required ListElement item,
    required Widget child,
  }) {
    return Obx(() {
      final bool selected = c.selected.contains(item);

      return WidgetButton(
        onPressed: c.searching.value
            ? () async {
                c.toggleSearch(true);

                // So that `onDone` is invoked for the fragment.
                await Future.delayed(Duration.zero);

                c.status.value = RxStatus.loading();
                await c.animateTo(
                  item.id.id,
                  ignoreElements: true,
                  addToHistory: false,
                );
                c.status.value = RxStatus.success();
              }
            : c.selecting.value
            ? selected
                  ? () => c.selected.remove(item)
                  : () => c.selected.add(item)
            : null,
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: 150.milliseconds,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.horizontal,
                  axisAlignment: 0,

                  child: ScaleTransition(
                    scale: animation,
                    alignment: Alignment.centerLeft,
                    child: AnimatedSwitcher.defaultTransitionBuilder(
                      child,
                      animation,
                    ),
                  ),
                );
              },
              child: c.selecting.value
                  ? SizedBox(
                      key: Key('Expanded'),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: SelectedDot(
                          inverted: true,
                          selected: selected,
                          size: SelectedDotSize.big,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
            Expanded(
              child: IgnorePointer(ignoring: c.selecting.value, child: child),
            ),
          ],
        ),
      );
    });
  }

  /// Builds a visual representation of the [WelcomeMessage] of this [Chat].
  Widget? _welcomeMessage(BuildContext context, ChatController c) {
    final welcome = c.welcomeMessage;
    if (welcome == null) {
      return null;
    }

    final style = Theme.of(context).style;

    final Iterable<Attachment> media = welcome.attachments.where(
      (e) => e is ImageAttachment || e is FileAttachment && e.isVideo,
    );

    final Iterable<Attachment> files = welcome.attachments.where(
      (e) => e is FileAttachment && !e.isVideo,
    );

    // Construct a dummy [ChatMessage] to pass to a [SingleItemPaginated].
    final ChatMessage item = ChatMessage(
      const ChatItemId('dummy'),
      const ChatId('dummy'),
      User(const UserId('dummy'), UserNum('1234123412341234')),
      PreciseDateTime.now(),
      attachments: media.toList(),
    );

    // Returns a [SingleItemPaginated] to display in a [PlayerView].
    Paginated<ChatItemId, Rx<ChatItem>> onGallery() {
      return SingleItemPaginated(const ChatItemId('dummy'), Rx(item))..around();
    }

    return Container(
      decoration: BoxDecoration(
        color: style.messageColor,
        borderRadius: style.cardRadius,
      ),
      margin: const EdgeInsets.all(8),
      child: IntrinsicWidth(
        child: ClipRRect(
          borderRadius: style.cardRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (media.isNotEmpty) ...[
                if (media.length == 1)
                  WithGlobalKey((_, key) {
                    return ChatItemWidget.mediaAttachment(
                      context,
                      attachment: media.first,
                      filled: false,
                      item: item,
                      onGallery: onGallery,
                      key: key,
                    );
                  })
                else
                  SizedBox(
                    width: 550,
                    height: max(media.length * 60, 300),
                    child: FitView(
                      dividerColor: style.colors.transparent,
                      children: media.mapIndexed((i, e) {
                        return WithGlobalKey((_, key) {
                          return ChatItemWidget.mediaAttachment(
                            context,
                            attachment: e,
                            item: item,
                            onGallery: onGallery,
                            key: key,
                          );
                        });
                      }).toList(),
                    ),
                  ),
              ],
              ...files.expand(
                (e) => [
                  const SizedBox(height: 6),
                  ChatItemWidget.fileAttachment(e),
                ],
              ),
              if (welcome.text != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: Text(
                    '${welcome.text}',
                    style: style.fonts.medium.regular.onBackground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
