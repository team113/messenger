import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:messenger/themes.dart';
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
            borderRadius: style.cardRadius,
            border: style.cardBorder,
            color: style.colors.transparent,
          ),
          child: Material(
            type: MaterialType.card,
            borderRadius: style.cardRadius.copyWith(
              bottomLeft: expanded ? Radius.zero : style.cardRadius.bottomLeft,
              bottomRight:
                  expanded ? Radius.zero : style.cardRadius.bottomRight,
            ),
            color: expanded ? style.activeColor : style.cardColor,
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: onPressed,
              hoverColor:
                  expanded ? style.activeColor : style.cardColor.darken(0.03),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DefaultTextStyle(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 10,
                  style: style.fonts.headlineLarge.copyWith(
                    color: expanded
                        ? style.colors.onPrimary
                        : style.colors.onBackground,
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: issue.title),
                        const WidgetSpan(child: SizedBox(width: 4)),
                        TextSpan(
                          text: '#444',
                          style: TextStyle(
                            color: expanded
                                ? style.colors.onPrimary
                                : style.colors.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrlString(issue.url),
                        ),
                        const WidgetSpan(child: SizedBox(width: 4)),
                        ...issue.labels.map((e) {
                          final HSLColor hsl = HSLColor.fromColor(e.$2);
                          final Color text =
                              hsl.lightness > 0.7 || hsl.alpha < 0.4
                                  ? const Color(0xFF000000)
                                  : const Color(0xFFFFFFFF);

                          return WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: IgnorePointer(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                                child: Chip(
                                  label: Text(
                                    e.$1,
                                    style: style.fonts.labelMedium
                                        .copyWith(color: text),
                                  ),
                                  backgroundColor: e.$2,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // child: Wrap(
                //   spacing: 4,
                //   runSpacing: 8,
                //   children: [
                //     DefaultTextStyle(
                //       overflow: TextOverflow.ellipsis,
                //       maxLines: 10,
                //       style: style.fonts.headlineLarge.copyWith(
                //         color: expanded
                //             ? style.colors.onPrimary
                //             : style.colors.onBackground,
                //       ),
                //       child: Text(issue.title),
                //     ),
                //     ...issue.labels.map((e) {
                //       final HSLColor hsl = HSLColor.fromColor(e.$2);
                //       final Color text = hsl.lightness > 0.7 || hsl.alpha < 0.4
                //           ? const Color(0xFF000000)
                //           : const Color(0xFFFFFFFF);

                //       return IgnorePointer(
                //         child: Chip(
                //           label: Text(
                //             e.$1,
                //             style:
                //                 style.fonts.labelMedium.copyWith(color: text),
                //           ),
                //           backgroundColor: e.$2,
                //         ),
                //       );
                //     }),
                //   ],
                // ),
              ),
            ),
          ),
        ),
        if (issue.description != null && expanded)
          DefaultTextStyle.merge(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  MarkdownBody(data: issue.description!),
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
      ],
    );
  }
}
