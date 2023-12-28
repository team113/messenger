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

import '/themes.dart';

/// An info tile with [title] and [content].
class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    this.title,
    required this.content,
    this.trailing,
    this.padding = const EdgeInsets.all(12),
    this.maxLines = 1,
  });

  /// Optional title of this [InfoTile].
  final String? title;

  /// Content of this [InfoTile].
  final String content;

  /// Optional trailing [Widget] of this [InfoTile].
  final Widget? trailing;

  /// Padding to apply to this [InfoTile].
  final EdgeInsets padding;

  /// Maximum number of lines of the [content].
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 6.5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  DefaultTextStyle(
                    overflow: TextOverflow.ellipsis,
                    style: style.fonts.small.regular.secondary,
                    child: Text(title!),
                  ),
                DefaultTextStyle.merge(
                  maxLines: maxLines,
                  overflow: maxLines == null ? null : TextOverflow.ellipsis,
                  style: style.fonts.big.regular.onBackground,
                  textAlign: TextAlign.justify,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Text(content)),
                      if (trailing != null) ...[
                        const SizedBox(width: 24),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: trailing!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
