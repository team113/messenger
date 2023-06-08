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

import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/selected_tile.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

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
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      key: const Key('SearchView'),
      init: SearchController(
        Get.find(),
        Get.find(),
        Get.find(),
        chat: chat,
        categories: categories,
        onSelected: onSelected,
      ),
      builder: (SearchController c) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              ModalPopupHeader(
                onBack: onBack,
                header: Center(
                  child: Text(
                    title,
                    style: style.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: ReactiveTextField(
                    key: const Key('SearchTextField'),
                    state: c.search,
                    label: 'label_search'.l10n,
                    style: style.labelLarge.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                    onChanged: () => c.query.value = c.search.text,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Obx(() {
                  if (c.recent.isEmpty &&
                      c.contacts.isEmpty &&
                      c.users.isEmpty &&
                      c.chats.isEmpty) {
                    if (c.searchStatus.value.isSuccess) {
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
                          'label_use_search'.l10n,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return const Center(child: CustomProgressIndicator());
                  }

                  return Scrollbar(
                    controller: c.controller,
                    child: FlutterListView(
                      key: const Key('SearchScrollable'),
                      controller: c.controller,
                      delegate: FlutterListViewDelegate(
                        (context, i) {
                          final dynamic e = c.getIndex(i);
                          final Widget child;

                          if (e is RxUser) {
                            child = Obx(() {
                              return SelectedTile(
                                key: Key('SearchUser_${e.id}'),
                                user: e,
                                selected: c.selectedUsers.contains(e),
                                darken: 0.05,
                                onAvatarTap: null,
                                onTap: selectable
                                    ? () => c.select(user: e)
                                    : enabled
                                        ? () => onPressed?.call(e)
                                        : null,
                              );
                            });
                          } else if (e is RxChatContact) {
                            child = Obx(() {
                              return SelectedTile(
                                key: Key('SearchContact_${e.id}'),
                                contact: e,
                                darken: 0.05,
                                selected: c.selectedContacts.contains(e),
                                onAvatarTap: null,
                                onTap: selectable
                                    ? () => c.select(contact: e)
                                    : enabled
                                        ? () => onPressed?.call(e)
                                        : null,
                              );
                            });
                          } else if (e is RxChat) {
                            child = Obx(() {
                              return SelectedTile(
                                key: Key('SearchChat_${e.id}'),
                                chat: e,
                                darken: 0.05,
                                selected: c.selectedChats.contains(e),
                                onAvatarTap: null,
                                onTap: selectable
                                    ? () => c.select(chat: e)
                                    : enabled
                                        ? () => onPressed?.call(e)
                                        : null,
                              );
                            });
                          } else {
                            child = const SizedBox();
                          }

                          return child;
                        },
                        childCount: c.chats.length +
                            c.contacts.length +
                            c.users.length +
                            c.recent.length,
                        disableCacheItems: true,
                      ),
                    ),
                  );
                }),
              ),
              if (onSubmit != null) ...[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Obx(() {
                    final bool enabled = this.enabled &&
                        (c.selectedContacts.isNotEmpty ||
                            c.selectedUsers.isNotEmpty);

                    return OutlinedRoundedButton(
                      key: const Key('SearchSubmitButton'),
                      maxWidth: double.infinity,
                      title: Text(
                        submit ?? 'btn_submit'.l10n,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: style.bodyLarge.copyWith(
                          color: enabled
                              ? style.colors.onPrimary
                              : style.colors.onBackground,
                        ),
                      ),
                      onPressed:
                          enabled ? () => onSubmit?.call(c.selected()) : null,
                      color: style.colors.primary,
                    );
                  }),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
