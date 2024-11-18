// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/application_settings.dart';
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
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/call/widget/fit_view.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/page/home/widget/highlighted_container.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/page/home/widget/unblock_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
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
import 'widget/circle_button.dart';
import 'widget/custom_drop_target.dart';
import 'widget/time_label.dart';
import 'widget/unread_label.dart';
import 'widget/with_global_key.dart';

/// View of the [Routes.chats] page.
class ChatView extends StatelessWidget {
  const ChatView(this.id, {super.key, this.itemId, this.welcome});

  /// ID of this [Chat].
  final ChatId id;

  /// ID of a [ChatItem] to scroll to initially in this [ChatView].
  final ChatItemId? itemId;

  // TODO: Remove when backend supports it out of the box.
  /// [ChatMessageText] serving as a welcome message to display in this [Chat].
  final ChatMessageText? welcome;

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
        itemId: itemId,
        welcome: welcome,
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
                padding: Insets.dense.copyWith(top: 0),
                child: _bottomBar(c, context),
              ),
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
                                  key: const Key('SearchField'),
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
                                  radius: AvatarRadius.medium,
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
                                                c.chat!.title,
                                                style: style.fonts.big.regular
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
                      border: (c.searching.value ||
                              c.search.isFocused.value == true ||
                              c.query.value?.isNotEmpty == true)
                          ? Border.all(color: style.colors.primary, width: 2)
                          : null,
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
                          } else if (!blocked) {
                            children = [
                              if (c.callPosition == null ||
                                  c.callPosition ==
                                      CallButtonsPosition.appBar) ...[
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
                              ],
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
                                final bool muted =
                                    c.chat?.chat.value.muted != null;

                                final bool dialog =
                                    c.chat?.chat.value.isDialog == true;

                                final bool isLocal =
                                    c.chat?.chat.value.id.isLocal == true;

                                final bool monolog =
                                    c.chat?.chat.value.isMonolog == true;

                                final bool favorite =
                                    c.chat?.chat.value.favoritePosition != null;

                                // TODO: Uncomment, when contacts are
                                //       implemented.
                                // final bool contact =
                                //     c.user?.user.value.contacts.isNotEmpty ??
                                //         false;

                                final Widget child;

                                if (c.selecting.value) {
                                  child = AnimatedButton(
                                    key: const Key('CancelSelecting'),
                                    onPressed: c.selecting.toggle,
                                    child: Container(
                                      padding: const EdgeInsets.only(left: 10),
                                      height: double.infinity,
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(10, 0, 21, 0),
                                        child: SvgIcon(SvgIcons.closePrimary),
                                      ),
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
                                      if (c.callPosition ==
                                          CallButtonsPosition.contextMenu) ...[
                                        ContextMenuButton(
                                          label: 'btn_audio_call'.l10n,
                                          onPressed: blocked || inCall
                                              ? null
                                              : () => c.call(false),
                                          trailing: SvgIcon(
                                            blocked || inCall
                                                ? SvgIcons.makeAudioCallDisabled
                                                : SvgIcons.makeAudioCall,
                                          ),
                                          inverted: const SvgIcon(
                                            SvgIcons.makeAudioCallWhite,
                                          ),
                                        ),
                                        ContextMenuButton(
                                          label: 'btn_video_call'.l10n,
                                          onPressed: blocked || inCall
                                              ? null
                                              : () => c.call(true),
                                          trailing: SvgIcon(
                                            blocked || inCall
                                                ? SvgIcons.makeVideoCallDisabled
                                                : SvgIcons.makeVideoCall,
                                          ),
                                          inverted: const SvgIcon(
                                            SvgIcons.makeVideoCallWhite,
                                          ),
                                        ),
                                      ],
                                      ContextMenuButton(
                                        key: const Key('SearchItemsButton'),
                                        label: 'label_search'.l10n,
                                        onPressed: c.toggleSearch,
                                        trailing:
                                            const SvgIcon(SvgIcons.search),
                                        inverted:
                                            const SvgIcon(SvgIcons.searchWhite),
                                      ),
                                      // TODO: Uncomment, when contacts are implemented.
                                      // if (dialog)
                                      //   ContextMenuButton(
                                      //     key: Key(
                                      //       contact
                                      //           ? 'DeleteFromContactsButton'
                                      //           : 'AddToContactsButton',
                                      //     ),
                                      //     label: contact
                                      //         ? 'btn_delete_from_contacts'.l10n
                                      //         : 'btn_add_to_contacts'.l10n,
                                      //     trailing: SvgIcon(
                                      //       contact
                                      //           ? SvgIcons.deleteContact
                                      //           : SvgIcons.addContact,
                                      //     ),
                                      //     inverted: SvgIcon(
                                      //       contact
                                      //           ? SvgIcons.deleteContactWhite
                                      //           : SvgIcons.addContactWhite,
                                      //     ),
                                      //     onPressed: contact
                                      //         ? () => _removeFromContacts(
                                      //               c,
                                      //               context,
                                      //             )
                                      //         : c.addToContacts,
                                      //   ),
                                      ContextMenuButton(
                                        key: Key(
                                          favorite
                                              ? 'UnfavoriteChatButton'
                                              : 'FavoriteChatButton',
                                        ),
                                        label: favorite
                                            ? 'btn_delete_from_favorites'.l10n
                                            : 'btn_add_to_favorites'.l10n,
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
                                        onPressed: favorite
                                            ? c.unfavoriteChat
                                            : c.favoriteChat,
                                      ),
                                      if (!isLocal) ...[
                                        if (!monolog)
                                          ContextMenuButton(
                                            key: Key(
                                              muted
                                                  ? 'UnmuteChatButton'
                                                  : 'MuteChatButton',
                                            ),
                                            label: muted
                                                ? PlatformUtils.isMobile
                                                    ? 'btn_unmute'.l10n
                                                    : 'btn_unmute_chat'.l10n
                                                : PlatformUtils.isMobile
                                                    ? 'btn_mute'.l10n
                                                    : 'btn_mute_chat'.l10n,
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
                                            onPressed: muted
                                                ? c.unmuteChat
                                                : c.muteChat,
                                          ),
                                        ContextMenuButton(
                                          key: const Key('ClearHistoryButton'),
                                          label: 'btn_clear_history'.l10n,
                                          trailing: const SvgIcon(
                                            SvgIcons.cleanHistory,
                                          ),
                                          inverted: const SvgIcon(
                                            SvgIcons.cleanHistoryWhite,
                                          ),
                                          onPressed: () =>
                                              _clearChat(c, context),
                                        ),
                                      ],
                                      if (!monolog && !dialog)
                                        ContextMenuButton(
                                          key: const Key('LeaveGroupButton'),
                                          label: 'btn_leave_group'.l10n,
                                          trailing: const SvgIcon(
                                            SvgIcons.leaveGroup,
                                          ),
                                          inverted: const SvgIcon(
                                            SvgIcons.leaveGroupWhite,
                                          ),
                                          onPressed: () =>
                                              _leaveGroup(c, context),
                                        ),
                                      if (!isLocal || monolog)
                                        ContextMenuButton(
                                          key: const Key('HideChatButton'),
                                          label: 'btn_delete_chat'.l10n,
                                          trailing:
                                              const SvgIcon(SvgIcons.delete19),
                                          inverted: const SvgIcon(
                                            SvgIcons.delete19White,
                                          ),
                                          onPressed: () =>
                                              _hideChat(c, context),
                                        ),
                                      if (dialog)
                                        ContextMenuButton(
                                          key: Key(
                                            blocked ? 'Unblock' : 'Block',
                                          ),
                                          label: blocked
                                              ? 'btn_unblock'.l10n
                                              : 'btn_block'.l10n,
                                          trailing:
                                              const SvgIcon(SvgIcons.block),
                                          inverted: const SvgIcon(
                                            SvgIcons.blockWhite,
                                          ),
                                          onPressed: blocked
                                              ? c.unblock
                                              : () => _blockUser(c, context),
                                        ),
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
                                      key: const Key('MoreButton'),
                                      padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 21,
                                      ),
                                      height: double.infinity,
                                      child: const SvgIcon(SvgIcons.more),
                                    ),
                                  );
                                }

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
                          child: ContextMenuInterceptor(child: Container()),
                        ),
                        Obx(() {
                          final Widget child = FlutterListView(
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
                              onItemSticky: (i) => c.elements.values
                                  .elementAt(i) is DateTimeElement,
                              initIndex: c.initIndex,
                              initOffset: c.initOffset,
                              initOffsetBasedOnBottom: true,
                              disableCacheItems: kDebugMode ? true : false,
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
                            onSelectionChanged: (a) => c.selection.value = a,
                            contextMenuBuilder: (_, __) => const SizedBox(),
                            selectionControls: EmptyTextSelectionControls(),
                            child: ContextMenuInterceptor(child: child),
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
                              return Center(
                                child: ListView(
                                  shrinkWrap: true,
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

                            return Center(
                              child: SystemInfoPrompt(
                                key: const Key('NoMessages'),
                                isMonolog
                                    ? 'label_chat_monolog_description'.l10n
                                    : 'label_no_messages'.l10n,
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
                        if (c.callPosition == CallButtonsPosition.top ||
                            c.callPosition == CallButtonsPosition.bottom)
                          Positioned(
                            top: c.callPosition == CallButtonsPosition.top
                                ? 8
                                : null,
                            bottom: c.callPosition == CallButtonsPosition.bottom
                                ? 8
                                : null,
                            right: 12,
                            child: Obx(() {
                              final bool inCall = c.chat?.inCall.value ?? false;

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  CircleButton(
                                    inCall
                                        ? SvgIcons.chatAudioCallDisabled
                                        : SvgIcons.chatAudioCall,
                                    onPressed:
                                        inCall ? null : () => c.call(false),
                                  ),
                                  const SizedBox(height: 8),
                                  CircleButton(
                                    inCall
                                        ? SvgIcons.chatVideoCallDisabled
                                        : SvgIcons.chatVideoCall,
                                    onPressed:
                                        inCall ? null : () => c.call(true),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }),
                          ),
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
                    bottomNavigationBar: Padding(
                      padding: Insets.dense.copyWith(top: 0),
                      child: _bottomBar(c, context),
                    ),
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
                                  child: ConditionalBackdropFilter(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color:
                                            style.colors.onBackgroundOpacity27,
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
              highlight: c.highlighted.value == element.id ||
                  c.selected.contains(element),
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
                  avatar: !previousSame,
                  reads: c.chat!.chat.value.membersCount > 10
                      ? []
                      : c.chat!.reads.where((m) =>
                          m.at == e.value.at &&
                          m.memberId != c.me &&
                          m.memberId != e.value.author.id),
                  user: snapshot.data ?? (user is RxUser? ? user : null),
                  getUser: c.getUser,
                  getItem: c.getItem,
                  onHide: () => c.hideChatItem(e.value),
                  onDelete: () => c.deleteMessage(e.value),
                  onReply: () {
                    final field = c.edit.value ?? c.send;

                    if (field.replied.any((i) => i.value.id == e.value.id)) {
                      field.replied
                          .removeWhere((i) => i.value.id == e.value.id);
                    } else {
                      field.replied.add(e);
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
                  onUserPressed: (user) {
                    ChatId chatId = user.dialog;
                    if (chatId.isLocalWith(c.me)) {
                      chatId = c.monolog;
                    }

                    router.chat(chatId, push: true);
                  },
                  onDragging: (e) => c.isDraggingItem.value = e,
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
              highlight: c.highlighted.value == element.id ||
                  c.selected.contains(element),
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
                  reads: c.chat!.chat.value.membersCount > 10
                      ? []
                      : c.chat!.reads.where((m) =>
                          m.at == element.forwards.last.value.at &&
                          m.memberId != c.me &&
                          m.memberId != element.authorId),
                  user: snapshot.data ?? (user is RxUser? ? user : null),
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
                  onReply: () {
                    final MessageFieldController field = c.edit.value ?? c.send;

                    if (element.forwards.any(
                          (e) => field.replied
                              .any((i) => i.value.id == e.value.id),
                        ) ||
                        field.replied.any(
                          (i) => i.value.id == element.note.value?.value.id,
                        )) {
                      for (Rx<ChatItem> e in element.forwards) {
                        field.replied
                            .removeWhere((i) => i.value.id == e.value.id);
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
                          push: true,
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
                    ].whereNotNull()) {
                      await c.chat?.updateAttachments(item);
                    }

                    await Future.delayed(Duration.zero);
                  },
                  onSelect: () {
                    c.selecting.toggle();
                    c.selected.add(element);
                  },
                  onDragging: (e) => c.isDraggingItem.value = e,
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

  /// Opens a confirmation popup leaving this [Chat].
  Future<void> _leaveGroup(ChatController c, BuildContext context) async {
    final bool? result = await MessagePopup.alert(
      'label_leave_group'.l10n,
      description: [TextSpan(text: 'alert_you_will_leave_group'.l10n)],
    );

    if (result == true) {
      await c.leaveGroup();
    }
  }

  /// Opens a confirmation popup hiding this [Chat].
  Future<void> _hideChat(ChatController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_delete_chat'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_deleted1'.l10n),
        TextSpan(
          text: c.chat?.title,
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_chat_will_be_deleted2'.l10n),
      ],
    );

    if (result == true) {
      await c.hideChat();
    }
  }

  /// Opens a confirmation popup clearing this [Chat].
  Future<void> _clearChat(ChatController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_clear_history'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_cleared1'.l10n),
        TextSpan(
          text: c.chat?.title,
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_chat_will_be_cleared2'.l10n),
      ],
    );

    if (result == true) {
      await c.clearChat();
    }
  }

  /// Opens a confirmation popup blocking the [User].
  Future<void> _blockUser(ChatController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_user_will_be_blocked1'.l10n),
        TextSpan(
          text: c.user?.title,
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_user_will_be_blocked2'.l10n),
      ],
      additional: [
        const SizedBox(height: 25),
        ReactiveTextField(state: c.reason, label: 'label_reason'.l10n),
      ],
    );

    if (result == true) {
      await c.block();
    }
  }

  // TODO: Uncomment, when contacts are implemented.
  /// Opens a confirmation popup deleting the [User] from address book.
  // Future<void> _removeFromContacts(
  //   ChatController c,
  //   BuildContext context,
  // ) async {
  //   final style = Theme.of(context).style;

  //   final bool? result = await MessagePopup.alert(
  //     'label_delete_contact'.l10n,
  //     description: [
  //       TextSpan(text: 'alert_contact_will_be_removed1'.l10n),
  //       TextSpan(
  //         text: c.user?.title,
  //         style: style.fonts.normal.regular.onBackground,
  //       ),
  //       TextSpan(text: 'alert_contact_will_be_removed2'.l10n),
  //     ],
  //   );

  //   if (result == true) {
  //     await c.removeFromContacts();
  //   }
  // }

  /// Returns a bottom bar of this [ChatView] to display under the messages list
  /// containing a send/edit field.
  Widget _bottomBar(ChatController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      if (c.selecting.value) {
        final bool canForward = c.selected.isNotEmpty &&
            !c.selected
                .any((e) => e is ChatCallElement || e is ChatInfoElement);
        final bool canDelete = c.selected.isNotEmpty;

        return CustomSafeArea(
          child: Container(
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
                    key: const Key('ForwardButton'),
                    enabled: canForward,
                    onPressed: canForward
                        ? () async {
                            final items = c.selected.asItems
                                .map((e) => ChatItemQuoteInput(item: e))
                                .toList();

                            items
                                .sort((a, b) => b.item.at.compareTo(a.item.at));

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
                              title: c.selected.length > 1
                                  ? 'label_delete_messages'.l10n
                                  : 'label_delete_message'.l10n,
                              description: deletable
                                  ? null
                                  : c.selected.length > 1
                                      ? 'label_messages_will_deleted_for_you'
                                          .l10n
                                      : 'label_message_will_deleted_for_you'
                                          .l10n,
                              initial: 1,
                              variants: [
                                ConfirmDialogVariant(
                                  key: const Key('HideForMe'),
                                  label: 'label_delete_for_me'.l10n,
                                  onProceed: () async {
                                    return await Future.wait(
                                      c.selected.asItems.map(c.hideChatItem),
                                    );
                                  },
                                ),
                                if (deletable)
                                  ConfirmDialogVariant(
                                    key: const Key('DeleteForAll'),
                                    label: 'label_delete_for_everyone'.l10n,
                                    onProceed: () async {
                                      return await Future.wait(
                                        c.selected.asItems.map(c.deleteMessage),
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
                  const SizedBox(width: 12),
                ],
              ),
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
          onChanged:
              c.chat?.chat.value.isMonolog == true ? null : c.updateTyping,
          onItemPressed: (item) =>
              c.animateTo(item.id, item: item, addToHistory: false),
          onAttachmentError: c.chat?.updateAttachments,
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
      );
    });
  }

  /// Builds a selectable clickable overlay over the provided [child].
  Widget _selectable(
    BuildContext context,
    ChatController c, {
    required ListElement item,
    required bool overlay,
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
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child:
                      c.selecting.value ? IgnorePointer(child: child) : child,
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
                        child: SelectedDot(selected: selected, darken: 0.1),
                      )
                    : const SizedBox(),
              ),
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

    final Iterable<Attachment> files =
        welcome.attachments.where((e) => e is FileAttachment && !e.isVideo);

    // Construct a dummy [ChatMessage] to pass to a [SingleItemPaginated].
    final ChatMessage item = ChatMessage(
      const ChatItemId('dummy'),
      const ChatId('dummy'),
      User(const UserId('dummy'), UserNum('1234123412341234')),
      PreciseDateTime.now(),
      attachments: media.toList(),
    );

    // Returns a [SingleItemPaginated] to display in a [GalleryPopup].
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
                      media.first,
                      media,
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
                      children: media.mapIndexed(
                        (i, e) {
                          return WithGlobalKey((_, key) {
                            return ChatItemWidget.mediaAttachment(
                              context,
                              e,
                              media,
                              item: item,
                              onGallery: onGallery,
                              key: key,
                            );
                          });
                        },
                      ).toList(),
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
