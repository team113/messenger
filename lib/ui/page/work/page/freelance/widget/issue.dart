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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../controller.dart';
import '/themes.dart';
import '/ui/page/auth/widget/cupertino_button.dart';
import '/ui/page/home/tab/chats/widget/hovered_ink.dart';
import '/ui/page/home/widget/avatar.dart';

/// Visual representation of the provided [issue].
class IssueWidget extends StatelessWidget {
  const IssueWidget(
    this.issue, {
    super.key,
    this.onPressed,
    this.expanded = false,
  });

  /// [Issue] to display.
  final Issue issue;

  /// Callback, called when this [IssueWidget] is pressed.
  final void Function()? onPressed;

  /// Indicator whether to display the [Issue.description], if any.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius.copyWith(
              bottomLeft: expanded ? Radius.zero : style.cardRadius.bottomLeft,
              bottomRight:
                  expanded ? Radius.zero : style.cardRadius.bottomRight,
            ),
            color: style.colors.transparent,
          ),
          child: InkWellWithHover(
            border: style.cardBorder,
            borderRadius: style.cardRadius.copyWith(
              bottomLeft: expanded ? Radius.zero : style.cardRadius.bottomLeft,
              bottomRight:
                  expanded ? Radius.zero : style.cardRadius.bottomRight,
            ),
            onTap: onPressed,
            selectedHoverColor: style.colors.primaryOpacity20.darken(0.03),
            selectedColor: style.colors.primaryOpacity20,
            selected: expanded,
            unselectedColor: style.cardColor.darken(0.05),
            unselectedHoverColor: style.cardColor.darken(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 10,
                    style: style.fonts.headlineLarge,
                  ),
                  StyledCupertinoButton(
                    onPressed: () => launchUrlString(issue.url),
                    label: 'GitHub #${issue.number}',
                    style: style.fonts.bodyLargePrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSizeAndFade.showHide(
          show: issue.description != null && expanded,
          fadeDuration: const Duration(milliseconds: 300),
          sizeDuration: const Duration(milliseconds: 300),
          child: DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: expanded
                ? style.fonts.labelMediumOnPrimary
                : style.fonts.labelMedium,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: style.cardRadius.copyWith(
                  topLeft: Radius.zero,
                  topRight: Radius.zero,
                ),
                border: style.cardBorder,
                color: style.colors.transparent,
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  MarkdownBody(
                    data: issue.description!,
                    onTapLink: (_, href, __) async =>
                        await launchUrlString(href!),
                    styleSheet: MarkdownStyleSheet(
                      h2Padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),

                      // TODO: Exception.
                      h2: style.fonts.displayLarge.copyWith(fontSize: 20),

                      p: style.fonts.titleMedium,
                      code: style.fonts.bodySmall.copyWith(
                        letterSpacing: 1.2,
                        backgroundColor: style.colors.secondaryHighlight,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: style.colors.secondaryHighlight,
                      ),
                      codeblockPadding: const EdgeInsets.all(16),
                      blockquoteDecoration: BoxDecoration(
                        color: style.colors.secondaryHighlight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StyledCupertinoButton(
                    onPressed: onPressed,
                    label: 'Свернуть',
                    style: style.fonts.labelMediumPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
