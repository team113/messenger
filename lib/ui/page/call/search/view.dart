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

import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/tab/chats/widget/recent_chat.dart';
import '/ui/page/home/widget/shadowed_rounded_button.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/selected_dot.dart';
import '/ui/widget/selected_tile.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/search_field.dart';

/// View of the [User]s search.
class SearchView extends StatelessWidget {
  const SearchView({
    super.key,
    required this.categories,
    required this.title,
    this.chat,
    this.selectable = true,
    this.enabled = true,
    this.submit,
    this.onPressed,
    this.onSubmit,
    this.onBack,
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

  /// Title of this [SearchView].
  final String title;

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

  /// Callback, called when the back button is pressed.
  ///
  /// If `null`, then no back button will be displayed.
  final VoidCallback? onBack;

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
              ModalPopupHeader(onBack: onBack, text: title),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              return RecentChatTile(
                                key: Key('SearchUser_${element.id}'),
                                element.dialog.value!,
                                me: c.me,
                                getUser: c.getUser,
                                onTap: () => c.select(user: element),
                                selected: c.selectedUsers.contains(element),
                                invertible: !selectable,
                                trailing: [
                                  SelectedDot(
                                    selected: c.selectedUsers.contains(element),
                                    size: 20,
                                  ),
                                ],
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
                              return RecentChatTile(
                                key: Key('SearchContact_${element.id}'),
                                element.user.value!.dialog.value!,
                                me: c.me,
                                getUser: c.getUser,
                                onTap: () => c.select(contact: element),
                                selected: c.selectedContacts.contains(element),
                                invertible: !selectable,
                                trailing: [
                                  SelectedDot(
                                    selected: c.selectedContacts.contains(
                                      element,
                                    ),
                                    size: 20,
                                  ),
                                ],
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
                            return RecentChatTile(
                              key: Key('SearchChat_${element.id}'),
                              element,
                              me: c.me,
                              getUser: c.getUser,
                              onTap: () => c.select(chat: element),
                              selected: c.selectedChats.contains(element),
                              invertible: !selectable,
                              trailing: [
                                SelectedDot(
                                  selected: c.selectedChats.contains(element),
                                  size: 20,
                                ),
                              ],
                            );
                          });
                        } else {
                          child = const SizedBox();
                        }

                        if (i == 0) {
                          child = Padding(
                            padding: const EdgeInsets.only(top: 10),
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
                                const SizedBox(height: 5),
                                const CustomProgressIndicator(),
                              ],
                              const SizedBox(height: 10),
                            ],
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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
