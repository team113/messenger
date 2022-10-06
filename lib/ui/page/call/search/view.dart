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

import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';

/// View of the [User]s search.
class SearchView extends StatelessWidget {
  const SearchView({
    Key? key,
    required this.categories,
    required this.title,
    this.chat,
    this.selectable = true,
    this.enabled = true,
    this.submit,
    this.onPressed,
    this.onSubmit,
    this.onBack,
  }) : super(key: key);

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

  /// Callback, called when the back button is pressed.
  ///
  /// If `null`, then no back button will be displayed.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: SearchController(
        Get.find(),
        Get.find(),
        Get.find(),
        chat: chat,
        categories: categories,
      ),
      builder: (SearchController c) {
        Widget tile({
          RxUser? user,
          RxChatContact? contact,
          void Function()? onTap,
          bool selected = false,
        }) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ContactTile(
              contact: contact,
              user: user,
              onTap: onTap,
              selected: selected,
              trailing: [
                if (selectable)
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: AnimatedSwitcher(
                      duration: 200.milliseconds,
                      child: selected
                          ? CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              radius: 12,
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            )
                          : const CircleAvatar(
                              backgroundColor: Color(0xFFD7D7D7),
                              radius: 12,
                            ),
                    ),
                  ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  title,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: ReactiveTextField(
                    state: c.search,
                    label: 'label_search'.l10n,
                    style: thin,
                    onChanged: () => c.query.value = c.search.text,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 17,
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        children: categories
                            .map((e) => _category(context, c, e))
                            .toList(),
                      ),
                    ),
                    Obx(() {
                      return Text(
                        'label_selected'.l10nfmt({
                          'count':
                              c.selectedContacts.length + c.selectedUsers.length
                        }),
                        style: thin?.copyWith(fontSize: 15),
                      );
                    }),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Obx(() {
                  if (c.recent.isEmpty &&
                      c.contacts.isEmpty &&
                      c.users.isEmpty) {
                    if (c.searchStatus.value.isSuccess) {
                      return Center(child: Text('label_nothing_found'.l10n));
                    } else if (c.searchStatus.value.isEmpty) {
                      return Center(child: Text('label_use_search'.l10n));
                    }

                    return const Center(child: CircularProgressIndicator());
                  }

                  return FlutterListView(
                    controller: c.controller,
                    delegate: FlutterListViewDelegate(
                      (context, i) {
                        dynamic e = c.getIndex(i);
                        Widget child = Container();

                        if (e is RxUser) {
                          child = Obx(() {
                            return tile(
                              user: e,
                              selected: c.selectedUsers.contains(e),
                              onTap: selectable
                                  ? () => c.selectUser(e)
                                  : enabled
                                      ? () => onPressed?.call(e)
                                      : null,
                            );
                          });
                        } else if (e is RxChatContact) {
                          child = Obx(() {
                            return tile(
                              contact: e,
                              selected: c.selectedContacts.contains(e),
                              onTap: selectable
                                  ? () => c.selectContact(e)
                                  : enabled
                                      ? () => onPressed?.call(e)
                                      : null,
                            );
                          });
                        }

                        return Padding(
                          padding: EdgeInsets.only(top: i > 0 ? 7 : 0),
                          child: child,
                        );
                      },
                      childCount:
                          c.contacts.length + c.users.length + c.recent.length,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    if (onBack != null) ...[
                      Expanded(
                        child: OutlinedRoundedButton(
                          key: const Key('BackButton'),
                          maxWidth: null,
                          title: Text(
                            'btn_back'.l10n,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onPressed: onBack,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Obx(() {
                        bool enabled = this.enabled &&
                            (c.selectedContacts.isNotEmpty ||
                                c.selectedUsers.isNotEmpty);

                        return OutlinedRoundedButton(
                          key: const Key('SearchSubmitButton'),
                          maxWidth: null,
                          title: Text(
                            submit ?? 'btn_submit'.l10n,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: enabled ? Colors.white : Colors.black,
                            ),
                          ),
                          onPressed: enabled
                              ? () => onSubmit?.call(c.selected())
                              : null,
                          color: Theme.of(context).colorScheme.secondary,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Builds a [WidgetButton] of the provided [category].
  Widget _category(
    BuildContext context,
    SearchController c,
    SearchCategory category,
  ) {
    return WidgetButton(
      onPressed: () => c.jumpTo(category),
      child: Obx(() {
        final TextStyle? thin = Theme.of(context).textTheme.bodyText1?.copyWith(
              fontSize: 15,
              color: c.category.value == category
                  ? Theme.of(context).colorScheme.secondary
                  : null,
            );

        return Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Text(category.l10n, style: thin),
        );
      }),
    );
  }
}

/// Extension adding [L10n] to a [SearchCategory].
extension _SearchCategoryL10n on SearchCategory {
  /// Returns a localized [String] of this [SearchCategory].
  String get l10n {
    switch (this) {
      case SearchCategory.recent:
        return 'label_recent'.l10n;
      case SearchCategory.contacts:
        return 'label_contacts'.l10n;
      case SearchCategory.users:
        return 'label_users'.l10n;
    }
  }
}
