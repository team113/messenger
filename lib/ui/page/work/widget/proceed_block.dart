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

import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/primary_button.dart';

/// [Block] displaying a single [OutlinedRoundedButton] with the provided
/// [text].
class ProceedBlock extends StatelessWidget {
  const ProceedBlock(this.text, {super.key, this.onPressed});

  /// Text of a button inside this block.
  final String text;

  /// Callback, called when a button inside this block is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Block(
      children: [
        Paddings.basic(PrimaryButton(onPressed: onPressed, title: text)),
      ],
    );
  }
}
