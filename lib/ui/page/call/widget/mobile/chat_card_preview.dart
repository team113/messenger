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
import '/ui/page/home/page/chat/widget/chat_item.dart';

/// [Widget] which builds a tile representation of the chat.
class ChatCardPreview extends StatelessWidget {
  const ChatCardPreview({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.duration,
    required this.child,
    this.onTap,
  });

  /// Title of this [ChatCardPreview].
  final String title;

  /// Subtitle of this [ChatCardPreview].
  final String subtitle;

  /// Trailing of this [ChatCardPreview].
  final String trailing;

  /// Current duration of the call.
  final Duration duration;

  /// [Widget] wrapped by this [ChatCardPreview].
  final Widget child;

  /// Callback [Function] that opens a screen to add members to the chat.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: style.cardRadius,
          color: style.colors.transparent,
        ),
        child: Material(
          type: MaterialType.card,
          borderRadius: style.cardRadius,
          color: style.colors.onSecondaryOpacity50,
          child: InkWell(
            borderRadius: style.cardRadius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
              child: Row(
                children: [
                  child,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: style.colors.onPrimary),
                              ),
                            ),
                            Text(
                              duration.hhMmSs(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: style.colors.onPrimary),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              Text(
                                subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: style.colors.onPrimary),
                              ),
                              const Spacer(),
                              Text(
                                trailing,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: style.colors.onPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
