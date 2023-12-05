import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/util/platform_utils.dart';

class ContactInfoWidget extends StatelessWidget {
  const ContactInfoWidget({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.trailing,
  });

  final String title;
  final String content;

  final Widget? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        constraints: context.isNarrow
            ? const BoxConstraints.tightForFinite()
            : const BoxConstraints(maxWidth: 400),
        child: SizedBox(
          height: 73,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: style.cardRadius,
              border: style.cardBorder,
              color: style.cardColor,
            ),
            child: ContactInfoContents(
              title: title,
              content: content,
              icon: icon,
              trailing: trailing,
            ),
          ),
        ),
      ),
    );
  }
}

class ContactInfoContents extends StatelessWidget {
  const ContactInfoContents({
    super.key,
    this.title,
    required this.content,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(12),
    this.maxLines = 1,
  });

  final String? title;
  final String content;

  final Widget? icon;
  final Widget? trailing;

  final EdgeInsets padding;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          const SizedBox(width: 6.5),
          // if (icon != null) icon!,
          // const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  DefaultTextStyle(
                    overflow: TextOverflow.ellipsis,
                    maxLines: maxLines,
                    style: style.fonts.small.regular.secondary,
                    child: Text(title!),
                  ),
                // const SizedBox(height: 4),
                DefaultTextStyle.merge(
                  maxLines: maxLines,
                  overflow: maxLines == null ? null : TextOverflow.ellipsis,
                  style: style.fonts.big.regular.onBackground,
                  child: Row(
                    children: [
                      Expanded(child: Text(content)),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
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
