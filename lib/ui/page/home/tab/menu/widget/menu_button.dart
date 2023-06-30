import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';

/// Rounded button with an [icon], [title] and [subtitle] intended to be used in
/// a menu list.
class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.onPressed,
    this.inverted = false,
  });

  /// Optional title of this [MenuButton].
  final String? title;

  /// Optional subtitle of this [MenuButton].
  final String? subtitle;

  /// Optional icon of this [MenuButton].
  final IconData? icon;

  /// Callback, called when this [MenuButton] is tapped.
  final void Function()? onPressed;

  /// Indicator whether this [MenuButton] should have its contents inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 73,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            border: style.cardBorder,
            color: style.colors.transparent,
          ),
          child: Material(
            type: MaterialType.card,
            borderRadius: style.cardRadius,
            color: inverted ? style.colors.primary : style.cardColor,
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: onPressed,
              hoverColor: inverted
                  ? style.colors.primary
                  : style.cardColor.darken(0.03),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      icon,
                      color: inverted
                          ? style.colors.onPrimary
                          : style.colors.primary,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            DefaultTextStyle(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: fonts.headlineLarge!.copyWith(
                                color: inverted
                                    ? style.colors.onPrimary
                                    : style.colors.onBackground,
                              ),
                              child: Text(title!),
                            ),
                          if (title != null && subtitle != null)
                            const SizedBox(height: 6),
                          if (subtitle != null)
                            DefaultTextStyle.merge(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: fonts.labelMedium!.copyWith(
                                color: inverted
                                    ? style.colors.onPrimary
                                    : style.colors.onBackground,
                              ),
                              child: Text(subtitle!),
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
      ),
    );
  }
}
