import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/hovered_ink.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/vacancy/body/controller.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GitHubIssueWidget extends StatelessWidget {
  const GitHubIssueWidget(
    this.issue, {
    super.key,
    this.onPressed,
    this.expanded = false,
  });

  final GitHubIssue issue;

  final void Function()? onPressed;
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
            border: style.cardBorder,
            color: style.colors.transparent,
          ),
          child: InkWellWithHover(
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
                  DefaultTextStyle(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 10,
                    style: style.fonts.headlineLarge,
                    child: Text(issue.title),
                  ),
                  WidgetButton(
                    onPressed: () => launchUrlString(issue.url),
                    child: Text(
                      'GitHub #${issue.number}',
                      style: style.fonts.bodyLargePrimary,
                    ),
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
            style: style.fonts.labelMedium.copyWith(
              color:
                  expanded ? style.colors.onPrimary : style.colors.onBackground,
            ),
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
                    styleSheet: MarkdownStyleSheet(
                      h2Padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),
                      h2: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      p: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      ),
                      code: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.normal,
                        backgroundColor: Color.fromRGBO(246, 248, 250, 1),
                      ),
                      codeblockDecoration: const BoxDecoration(
                        color: Color.fromRGBO(246, 248, 250, 1),
                      ),
                      codeblockPadding: const EdgeInsets.all(16),
                      blockquoteDecoration: const BoxDecoration(
                        color: Color.fromRGBO(246, 248, 250, 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  WidgetButton(
                    onPressed: onPressed,
                    child: Text(
                      'Свернуть',
                      style: style.fonts.labelMediumPrimary,
                    ),
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
