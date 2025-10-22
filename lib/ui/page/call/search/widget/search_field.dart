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
import '/ui/page/home/widget/app_bar.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';

/// [ReactiveTextField] inside a [CustomAppBar] stylized as a search field.
class SearchField extends StatelessWidget {
  const SearchField(this.state, {super.key, this.onChanged, this.hint});

  /// State of the search [ReactiveTextField].
  final TextFieldState state;

  /// Hint to display in the [SearchField].
  final String? hint;

  /// Callback, called when [SearchField] changes.
  final void Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ReactiveTextField(
      key: const Key('SearchTextField'),
      state: state,
      hint: hint ?? 'label_search'.l10n,
      maxLines: 1,
      filled: true,
      dense: false,
      padding: const EdgeInsets.symmetric(vertical: 8),
      style: style.fonts.medium.regular.onBackground,
      onChanged: onChanged,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: SvgIcon(SvgIcons.search),
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
