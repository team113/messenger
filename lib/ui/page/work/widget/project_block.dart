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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/block.dart';
import 'interactive_logo.dart';

/// [Block] display the [InteractiveLogo].
class ProjectBlock extends StatelessWidget {
  const ProjectBlock({super.key, this.onPressed, this.children = const []});

  /// Callback, called when logo is pressed.
  final void Function()? onPressed;

  /// [Widget]s to display under the [InteractiveLogo], if any.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Block(
      children: [
        Text(
          'label_messenger1'.l10n,
          style: style.fonts.larger.regular.secondary,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 1.6),
        Text(
          'label_messenger2'.l10n,
          style: style.fonts.medium.regular.secondary,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 20),
        InteractiveLogo(onEyePressed: onPressed),
        const SizedBox(height: 7),
        ...children,
      ],
    );
  }
}
