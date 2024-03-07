// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/menu_button.dart';

class BalanceProviderWidget extends StatelessWidget {
  const BalanceProviderWidget({
    super.key,
    required this.title,
    this.selected = false,
    this.onPressed,
    this.bonus,
    this.leading = const [],
  });

  final String title;
  final bool selected;
  final void Function()? onPressed;
  final double? bonus;

  final List<Widget> leading;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    var secondaryStyle = style.fonts.small.regular.secondary;

    Widget? subtitle;
    if (bonus != null) {
      if (bonus! > 0) {
        subtitle = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Пополнить счёт, бонус: ',
                style: selected
                    ? style.fonts.small.regular.onPrimary
                    : style.fonts.small.regular.secondary,
              ),
              TextSpan(
                text: '+$bonus%',
                style: selected
                    ? style.fonts.small.regular.onPrimary
                    : style.fonts.small.regular.secondary
                        .copyWith(color: style.colors.acceptPrimary),
              ),
            ],
          ),
        );

        secondaryStyle = style.fonts.small.regular.secondary.copyWith(
          color: style.colors.acceptPrimary,
        );
      } else {
        subtitle = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Пополнить счёт, комиссия: ',
                style: selected
                    ? style.fonts.small.regular.onPrimary
                    : style.fonts.small.regular.secondary,
              ),
              TextSpan(
                text: '$bonus%',
                style: selected
                    ? style.fonts.small.regular.onPrimary
                    : style.fonts.small.regular.danger,
              ),
            ],
          ),
        );
        secondaryStyle = style.fonts.small.regular.secondary.copyWith(
          color: style.colors.danger,
        );
      }
    }

    return Padding(
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
            color: selected ? style.colors.primary : style.cardColor,
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: onPressed,
              hoverColor:
                  selected ? style.colors.primary : style.cardHoveredColor,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(width: 6.5),
                    if (leading.isNotEmpty) ...leading,
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   'Add funds',
                          //   style: selected
                          //       ? style.fonts.big.regular.onPrimary
                          //       : style.fonts.big.regular.onBackground,
                          // ),
                          DefaultTextStyle(
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: selected
                                ? style.fonts.big.regular.onPrimary
                                : style.fonts.big.regular.onBackground,
                            child: Text(title),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 6),
                            DefaultTextStyle.merge(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: selected
                                  ? style.fonts.small.regular.onPrimary
                                  : secondaryStyle,
                              child: subtitle,
                            ),
                          ],
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

    // return MenuButton(
    //   leading: leading.firstOrNull,
    //   title: title,
    //   subtitle: bonus == null
    //       ? null
    //       : bonus! > 0
    //           ? 'Bonus: +$bonus%'
    //           : 'Commission: $bonus%',
    //   inverted: selected,
    //   // reversed: true,
    //   onPressed: onPressed,
    // );

    // return SizedBox(
    //   height: 73,
    //   child: Padding(
    //     padding: const EdgeInsets.symmetric(vertical: 1.5),
    //     child: InkWellWithHover(
    //       selectedColor: style.colors.primary,
    //       unselectedColor: style.cardColor,
    //       selected: selected,
    //       hoveredBorder:
    //           selected ? style.primaryBorder : style.cardHoveredBorder,
    //       border: selected ? style.primaryBorder : style.cardBorder,
    //       borderRadius: style.cardRadius,
    //       onTap: onTap,
    //       unselectedHoverColor: style.cardHoveredColor,
    //       selectedHoverColor: style.colors.primary,
    //       child: Padding(
    //         padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
    //         child: Row(
    //           children: [
    //             // const SizedBox(width: 12),
    //             ...leading.map(
    //               (e) => IconTheme(
    //                 data: IconThemeData(
    //                   size: 48,
    //                   color: selected
    //                       ? style.colors.onPrimary
    //                       : style.colors.primary,
    //                 ),
    //                 child: e,
    //               ),
    //             ),
    //             const SizedBox(width: 12),
    //             Expanded(
    //               child: Column(
    //                 mainAxisSize: MainAxisSize.min,
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 children: [
    //                   Row(
    //                     children: [
    //                       Expanded(
    //                         child: Text(
    //                           title,
    //                           overflow: TextOverflow.ellipsis,
    //                           maxLines: 1,
    //                           style: selected
    //                               ? style.fonts.medium.regular.onPrimary
    //                               : style.fonts.medium.regular.onBackground,
    //                         ),
    //                       ),
    //                     ],
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }
}
