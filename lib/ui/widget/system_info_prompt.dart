// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/themes.dart';

/// Rounded [Container] with [Style.systemMessageColor] displaying the [text].
class SystemInfoPrompt extends StatelessWidget {
  const SystemInfoPrompt(this.text, {super.key});

  /// Text to display in the prompt.
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: style.systemMessageBorder,
        color: style.systemMessageColor,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: style.fonts.small.regular.onBackground,
      ),
    );
  }
}
