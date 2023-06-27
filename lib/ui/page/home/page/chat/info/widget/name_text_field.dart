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

import '/l10n/l10n.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Custom-styled [ReactiveTextField] to manipulate user name.
class NameTextField extends StatelessWidget {
  const NameTextField({
    super.key,
    required this.state,
    this.label,
  });

  /// State of the [ReactiveTextField].
  final TextFieldState state;

  /// Label of the [ReactiveTextField].
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Paddings.basic(
      ReactiveTextField(
        state: state,
        label: label,
        hint: 'label_chat_name_hint'.l10n,
        onSuffixPressed: state.text.isEmpty
            ? null
            : () {
                PlatformUtils.copy(text: state.text);
                MessagePopup.success('label_copied'.l10n);
              },
        trailing: state.text.isEmpty
            ? null
            : Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/copy.svg', height: 15),
                ),
              ),
      ),
    );
  }
}
