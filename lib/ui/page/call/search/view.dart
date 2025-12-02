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

import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/chat_tile.dart';
import '/ui/page/home/widget/shadowed_rounded_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/selected_dot.dart';
import '/ui/widget/selected_tile.dart';
import '/ui/widget/svg/svgs.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the [User]s search.
class SearchView extends StatelessWidget {
  const SearchView({
    super.key,
    required this.categories,
    this.chat,
    this.selectable = true,
    this.enabled = true,
    this.submit,
    this.onPressed,
    this.onSubmit,
    this.onSelected,
  });

  /// [SearchCategory]ies to search through.
  final List<SearchCategory> categories;

  /// [RxChat] this [SearchView] is bound to, if any.
  final RxChat? chat;

  /// Indicator whether the searched items are selectable.
  final bool selectable;

  /// Indicator whether the selected items can be submitted, if [selectable], or
  /// otherwise [onPressed] may be called.
  final bool enabled;

  /// Label of the submit button.
  ///
  /// Only meaningful if [onSubmit] is non-`null`.
  final String? submit;

  /// Callback, called when a searched item is pressed.
  final void Function(dynamic)? onPressed;

  /// Callback, called when the submit button is pressed.
  final void Function(List<UserId> ids)? onSubmit;

  /// Callback, called on the selected items changes.
  final void Function(SearchViewResults? results)? onSelected;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('SearchView'),
      init: SearchController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        chat: chat,
        categories: categories,
        onSelected: onSelected,
      ),
      builder: (SearchController c) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SearchField(
                  c.search,
                  onChanged: () => c.query.value = c.search.text,
                ),
              ),
              Expanded(
                child: Obx(() {
                  final RxStatus status = c.searchStatus.value;

                  if (c.recent.isEmpty &&
                      c.contacts.isEmpty &&
                      c.users.isEmpty &&
                      c.chats.isEmpty) {
                    if (status.isSuccess && !status.isLoadingMore) {
                      return AnimatedDelayedSwitcher(
                        delay: const Duration(milliseconds: 300),
                        child: Center(
                          child: Text(
                            'label_nothing_found'.l10n,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    } else if (c.searchStatus.value.isEmpty) {
                      return Center(
                        child: Text(
                          'label_no_users'.l10n,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return const Center(child: CustomProgressIndicator());
                  }

                  final int childCount =
                      c.chats.length +
                      c.contacts.length +
                      c.users.length +
                      c.recent.length;

                  final Widget list = FlutterListView(
                    key: const Key('SearchScrollable'),
                    controller: c.scrollController,
                    delegate: FlutterListViewDelegate(
                      (context, i) {
                        final dynamic element = c.elementAt(i);
                        Widget child;

                        if (element is RxUser) {
                          child = Obx(() {
                            if (element.dialog.value != null) {
                              return _ChatTile(
                                key: Key('SearchUser_${element.id}'),
                                element.dialog.value!,
                                onTap: () => c.select(user: element),
                                selected: c.selectedUsers.contains(element),
                              );
                            }

                            return SelectedTile(
                              key: Key('SearchUser_${element.id}'),
                              user: element,
                              selected: c.selectedUsers.contains(element),
                              onAvatarTap: null,
                              onTap: selectable
                                  ? () => c.select(user: element)
                                  : enabled
                                  ? () => onPressed?.call(element)
                                  : null,
                            );
                          });
                        } else if (element is RxChatContact) {
                          child = Obx(() {
                            if (element.user.value?.dialog.value != null) {
                              return _ChatTile(
                                key: Key('SearchContact_${element.id}'),
                                element.user.value!.dialog.value!,
                                onTap: () => c.select(contact: element),
                                selected: c.selectedContacts.contains(element),
                              );
                            }

                            return SelectedTile(
                              key: Key('SearchContact_${element.id}'),
                              contact: element,
                              selected: c.selectedContacts.contains(element),
                              onAvatarTap: null,
                              onTap: selectable
                                  ? () => c.select(contact: element)
                                  : enabled
                                  ? () => onPressed?.call(element)
                                  : null,
                            );
                          });
                        } else if (element is RxChat) {
                          child = Obx(() {
                            return _ChatTile(
                              key: Key('SearchChat_${element.id}'),
                              element,
                              onTap: () => c.select(chat: element),
                              selected: c.selectedChats.contains(element),
                            );
                          });
                        } else {
                          child = const SizedBox();
                        }

                        if (i == 0) {
                          child = Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: child,
                          );
                        }

                        if (i == childCount - 1) {
                          Widget widget = child;
                          child = Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              widget,
                              if (status.isLoadingMore || status.isLoading) ...[
                                const SizedBox(height: 2),
                                const CustomProgressIndicator(),
                              ],
                              const SizedBox(height: 6),
                            ],
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: child,
                        );
                      },
                      childCount: childCount,
                      disableCacheItems: true,
                    ),
                  );

                  // Force [Scrollbar]s to appear on mobile.
                  if (PlatformUtils.isMobile) {
                    return Scrollbar(
                      controller: c.scrollController,
                      child: list,
                    );
                  } else {
                    return list;
                  }
                }),
              ),
              if (onSubmit != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Obx(() {
                    final bool enabled =
                        (c.selectedContacts.isNotEmpty ||
                            c.selectedUsers.isNotEmpty) &&
                        this.enabled;

                    return ShadowedRoundedButton(
                      key: const Key('SearchSubmitButton'),
                      maxWidth: double.infinity,
                      color: style.colors.primary,
                      onPressed: enabled
                          ? () => onSubmit?.call(c.selected())
                          : null,
                      child: Text(
                        submit ?? 'btn_submit'.l10n,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: enabled
                            ? style.fonts.medium.regular.onPrimary
                            : style.fonts.medium.regular.onBackground,
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// [ReactiveTextField] styled as a search field.
class SearchField extends StatelessWidget {
  const SearchField(this.state, {super.key, this.onChanged});

  /// State of the search [ReactiveTextField].
  final TextFieldState state;

  /// Callback, called when [SearchField] changes.
  final void Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ReactiveTextField(
      key: const Key('SearchTextField'),
      state: state,
      hint: 'label_search'.l10n,
      hintColor: style.colors.secondary,
      maxLines: 1,
      filled: true,
      dense: false,
      padding: const EdgeInsets.symmetric(vertical: 18),
      style: style.fonts.normal.regular.onBackground,
      onChanged: onChanged,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Transform.translate(
          offset: Offset(0, 2),
          child: SvgIcon(SvgIcons.search, width: 18, height: 18),
        ),
      ),
      trailing: Obx(() {
        final Widget child;

        if (state.isEmpty.value) {
          child = const SizedBox();
        } else {
          child = AnimatedButton(
            key: const Key('ClearButton'),
            onPressed: () => state.text = '',
            child: SvgIcon(SvgIcons.clearSearch),
          );
        }

        return SafeAnimatedSwitcher(duration: 200.milliseconds, child: child);
      }),
    );
  }
}

/// [ChatTile] representing the provided [RxChat] as a recent [Chat] for [SearchView].
class _ChatTile extends StatelessWidget {
  const _ChatTile(this.rxChat, {super.key, this.onTap, this.selected = false});

  /// [RxChat] this [_ChatTile] is about.
  final RxChat rxChat;

  /// Indicator whether this [_ChatTile] is selected.
  final bool selected;

  /// Callback, called when this [_ChatTile] is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ChatTile(
      key: Key(rxChat.id.val),
      chat: rxChat,
      dimmed: false,
      status: [
        const SizedBox(width: 8),
        SelectedDot(selected: selected),
      ],
      selected: selected,
      enableContextMenu: false,
      onTap: onTap,
      onForbidden: rxChat.updateAvatar,
      height: 55.5,
    );
  }
}
