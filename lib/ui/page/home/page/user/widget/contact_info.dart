import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/chat_tile.dart';
import 'package:messenger/ui/widget/menu_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
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

    return Center(
      child: Container(
        constraints: context.isNarrow
            ? const BoxConstraints.tightForFinite()
            : const BoxConstraints(maxWidth: 400),
        child: MenuButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          leading: icon ?? const SizedBox(),
          title: title,
          subtitle: content,
          trailing: trailing,
          // trailing: trailing == null ? [] : [trailing!],
        ),
      ),
    );

    return Center(
      child: Container(
        constraints: context.isNarrow
            ? const BoxConstraints.tightForFinite()
            : const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ChatTile(
            avatarBuilder: (_) => icon ?? const SizedBox(),
            titleBuilder: (_) =>
                Text(title, style: style.fonts.small.regular.secondary),
            subtitle: [
              const SizedBox(height: 6),
              Text(
                content,
                style: style.fonts.medium.regular.onBackground,
              ),
            ],
            trailing: trailing == null ? [] : [trailing!],
          ),
        ),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: context.isNarrow
            ? const BoxConstraints.tightForFinite()
            : const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            color: style.cardColor,
          ),
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            children: [
              // Icon(Icons.person, size: 54),
              const SvgImage.asset(
                'assets/icons/gapopa_purple.svg',
                height: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: style.fonts.small.regular.secondary),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            content,
                            style: style.fonts.medium.regular.onBackground,
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactInfoContents extends StatelessWidget {
  const ContactInfoContents({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(12),
  });

  final String title;
  final String content;

  final Widget? icon;
  final Widget? trailing;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          const SizedBox(width: 6.5),
          if (icon != null) icon!,
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: style.fonts.small.regular.secondary,
                  child: Text(title),
                ),
                // const SizedBox(height: 4),
                DefaultTextStyle.merge(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.fonts.big.regular.onBackground,
                  child: Row(
                    children: [
                      Expanded(child: Text(content)),
                      if (trailing != null) ...[
                        trailing!,
                        const SizedBox(width: 8),
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
