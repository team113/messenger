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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';

/// [ReactiveTextField] inside a [CustomAppBar] stylized as a search field.
class SearchField extends StatelessWidget {
  const SearchField(
    this.state, {
    super.key,
    this.onChanged,
    this.hint,
  });

  /// State of the search [ReactiveTextField].
  final TextFieldState state;

  /// Hint to display in the [SearchField].
  final String? hint;

  /// Callback, called when [SearchField] changes.
  final void Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SizedBox(
      height: CustomAppBar.height,
      child: Obx(() {
        return CustomAppBar(
          margin: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          top: false,
          borderRadius: style.cardRadius,
          border: state.isFocused.value || !state.isEmpty.value
              ? Border.all(color: style.colors.primary, width: 2)
              : null,
          title: Theme(
            data: MessageFieldView.theme(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Transform.translate(
                offset: const Offset(0, 1),
                child: ReactiveTextField(
                  key: const Key('SearchTextField'),
                  state: state,
                  hint: hint ?? 'label_search'.l10n,
                  maxLines: 1,
                  filled: false,
                  dense: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  style: style.fonts.medium.regular.onBackground,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          leading: [
            Container(
              padding: const EdgeInsets.only(left: 20, right: 6),
              width: 46,
              height: double.infinity,
              child: const Center(child: SvgIcon(SvgIcons.search)),
            ),
          ],
          actions: [
            Obx(() {
              final Widget child;

              if (state.isEmpty.value) {
                child = const SizedBox();
              } else {
                child = AnimatedButton(
                  key: const Key('ClearButton'),
                  onPressed: () => state.text = '',
                  decorator: (child) => Container(
                    padding: const EdgeInsets.only(right: 20, left: 6),
                    width: 46,
                    height: double.infinity,
                    child: child,
                  ),
                  child: const Center(child: SvgIcon(SvgIcons.clearSearch)),
                );
              }

              return SafeAnimatedSwitcher(
                duration: 200.milliseconds,
                child: child,
              );
            }),
          ],
        );
      }),
    );
  }
}
