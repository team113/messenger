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

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/text_field.dart';

/// Custom-styled [CopyableTextField] to display copyable [num].
class CopyableNumField extends StatefulWidget {
  const CopyableNumField(this.num, {super.key});

  /// Unique number of an [User].
  final UserNum? num;

  @override
  State<CopyableNumField> createState() => _CopyableNumFieldState();
}

/// State of an [CopyableNumField] maintaining the [_state].
class _CopyableNumFieldState extends State<CopyableNumField> {
  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.num?.val.replaceAllMapped(
      RegExp(r'.{4}'),
      (match) => '${match.group(0)} ',
    ),
    editable: false,
  );

  @override
  Widget build(BuildContext context) {
    return Paddings.basic(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CopyableTextField(
            key: const Key('NumCopyable'),
            state: _state,
            label: 'label_num'.l10n,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
