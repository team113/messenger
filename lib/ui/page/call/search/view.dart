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
import '/ui/page/call/participant/controller.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';

/// View of the [User]s search.
class SearchView extends StatelessWidget {
  const SearchView({
    Key? key,
    required this.searchTypes,
    required this.title,
    this.chat,
    this.selectable = true,
    this.enabled = true,
    this.submitLabel,
    this.onItemTap,
    this.onSubmit,
    this.onBack,
  }) : super(key: key);

  /// [Search] types this [SearchView] doing.
  final List<Search> searchTypes;

  /// [RxChat] this [SearchView] is bound to.
  final Rx<RxChat?>? chat;

  /// Indicator whether searched items is selectable.
  final bool selectable;

  /// Indicator whether the selected items can be submitted.
  final bool enabled;

  /// Title showed on this [SearchView].
  final String title;

  /// Label showed on the submit button.
  ///
  /// If not set then submit button will not be displayed
  final String? submitLabel;

  /// Callback, called when an searched item is tapped.
  final void Function(dynamic)? onItemTap;

  /// Callback, called when the submit button tapped.
  ///
  /// If not set then submit button will not be displayed.
  final SubmitCallback? onSubmit;

  /// Callback, called when the back button tapped.
  ///
  /// If not set then back button will not be displayed.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: SearchController(
        Get.find(),
        Get.find(),
        Get.find(),
        chat: chat,
        searchTypes: searchTypes,
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
                          ? const CircleAvatar(
                              backgroundColor: Color(0xFF63B4FF),
                              radius: 12,
                              child: Icon(
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
                      child: Builder(builder: (context) {
                        List<Widget> widgets = [];

                        if (searchTypes.contains(Search.recent)) {
                          widgets.add(_type(c, Search.recent, thin));
                        }

                        if (searchTypes.contains(Search.contacts)) {
                          if (widgets.isNotEmpty) {
                            widgets.add(const SizedBox(width: 20));
                          }
                          widgets.add(_type(c, Search.contacts, thin));
                        }

                        if (searchTypes.contains(Search.users)) {
                          if (widgets.isNotEmpty) {
                            widgets.add(const SizedBox(width: 20));
                          }
                          widgets.add(_type(c, Search.users, thin));
                        }

                        return ListView(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          children: widgets,
                        );
                      }),
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
                      return Center(
                        child: Text('label_use_search'.l10n),
                      );
                    }

                    return const Center(child: CircularProgressIndicator());
                  }

                  return FlutterListView(
                    controller: c.controller,
                    delegate: FlutterListViewDelegate(
                      (context, i) {
                        dynamic e = c.getIndex(i);

                        if (e is RxUser) {
                          return Column(
                            children: [
                              if (i > 0) const SizedBox(height: 7),
                              Obx(() {
                                return tile(
                                  user: e,
                                  selected: c.selectedUsers.contains(e),
                                  onTap: () => selectable
                                      ? c.selectUser(e)
                                      : onItemTap?.call(e),
                                );
                              }),
                            ],
                          );
                        } else if (e is RxChatContact) {
                          return Column(
                            children: [
                              if (i > 0) const SizedBox(height: 7),
                              Obx(() {
                                return tile(
                                  contact: e,
                                  selected: c.selectedContacts.contains(e),
                                  onTap: () => selectable
                                      ? c.selectContact(e)
                                      : onItemTap?.call(e),
                                );
                              }),
                            ],
                          );
                        }

                        return Container();
                      },
                      childCount:
                          c.contacts.length + c.users.length + c.recent.length,
                    ),
                  );
                }),
              ),
              if (onSubmit != null && submitLabel != null) ...[
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
                            color: const Color(0xFF63B4FF),
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
                              submitLabel!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: enabled ? Colors.white : Colors.black,
                              ),
                            ),
                            onPressed: () =>
                                enabled ? onSubmit!(c.selected()) : null,
                            color: enabled
                                ? const Color(0xFF63B4FF)
                                : const Color(0xFFEEEEEE),
                          );
                        }),
                      ),
                    ],
                  ),
                )
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Returns button to jump to the provided [Search] type search results.
  Widget _type(SearchController s, Search type, TextStyle? textStyle) {
    return WidgetButton(
      onPressed: () => s.jumpTo(type),
      child: Obx(() {
        return Text(
          type.name.capitalizeFirst!,
          style: textStyle?.copyWith(
            fontSize: 15,
            color:
                s.selectedSearch.value == type ? const Color(0xFF63B4FF) : null,
          ),
        );
      }),
    );
  }
}
