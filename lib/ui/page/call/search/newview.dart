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
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View of the [User]s search.
class NewSearchView extends StatelessWidget {
  const NewSearchView({
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
    this.onChanged,
    this.onResultsUpdated,
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

  /// Callback, called when the selected items was changed.
  final void Function(SearchViewResults results)? onChanged;

  /// Callback, called when the selected items was changed.
  final void Function(SearchViewResults results)? onResultsUpdated;

  /// Callback, called when the back button is pressed.
  ///
  /// If `null`, then no back button will be displayed.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: SearchController(
        Get.find(),
        Get.find(),
        Get.find(),
        chat: chat,
        categories: categories,
        onChanged: onChanged,
        onResultsUpdated: onResultsUpdated,
      ),
      builder: (SearchController c) {
        return ReactiveTextField(
          state: c.search,
          hint: 'label_search'.l10n,
          maxLines: 1,
          filled: false,
          dense: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          style: Theme.of(context)
              .extension<Style>()!
              .boldBody
              .copyWith(fontSize: 17),
          onChanged: () => c.query.value = c.search.text,
        );
      },
    );
  }

  /// Builds [User]s tile.
  Widget tile({
    required BuildContext context,
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
        darken: 0.05,
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

  /// Builds [Chat]s tile.
  Widget chatTile(
    BuildContext context, {
    required RxChat chat,
    void Function()? onTap,
    bool selected = false,
  }) {
    Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          borderRadius: style.cardRadius,
          border: style.cardBorder,
          color: Colors.transparent,
        ),
        child: Material(
          type: MaterialType.card,
          borderRadius: style.cardRadius,
          color: selected
              ? const Color(0xFFD7ECFF).withOpacity(0.8)
              : style.cardColor.darken(0.05),
          child: InkWell(
            key: Key('SearchViewChat_${chat.chat.value.id}'),
            borderRadius: style.cardRadius,
            onTap: onTap,
            hoverColor: selected
                ? const Color(0x00D7ECFF)
                : const Color(0xFFD7ECFF).withOpacity(0.8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
              child: Row(
                children: [
                  AvatarWidget.fromRxChat(chat, radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      chat.title.value,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headline5,
                    ),
                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}
