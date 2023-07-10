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

import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';

import '/themes.dart';
import '/ui/page/home/page/my_profile/call_window_switch/controller.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/paddings.dart';

/// Custom-styled [FieldButton] for opening calls either in a separate window
/// or inside the application.
class ProfileCall extends StatelessWidget {
  const ProfileCall({super.key, this.enablePopups});

  /// Indicator whether calls will be opened in a separate window or
  /// within the app.
  final bool? enablePopups;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Paddings.dense(
          FieldButton(
            text: enablePopups ?? true
                ? 'label_open_calls_in_window'.l10n
                : 'label_open_calls_in_app'.l10n,
            maxLines: null,
            onPressed: () => CallWindowSwitchView.show(context),
            style: fonts.titleMedium!.copyWith(color: style.colors.primary),
          ),
        ),
      ],
    );
  }
}
