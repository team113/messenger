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

import '../dense.dart';
import '../field_button.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';

/// [Widget] which returns the contents of a [ProfileTab.danger] section.
class ProfileDanger extends StatelessWidget {
  const ProfileDanger(this.onPressed, {super.key});

  /// Callback, called when this [ProfileDanger] is pressed.
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Column(
      children: [
        Dense(
          FieldButton(
            key: const Key('DeleteAccount'),
            text: 'btn_delete_account'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
              ),
            ),
            onPressed: onPressed,
            style: TextStyle(color: style.colors.primary),
          ),
        ),
      ],
    );
  }
}
