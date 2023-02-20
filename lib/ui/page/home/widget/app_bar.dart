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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';

/// Custom stylized and decorated [AppBar].
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.leading = const [],
    this.actions = const [],
    this.padding,
    this.background,
    this.border,
    this.onBottom,
  });

  /// Primary centered [Widget] of this [CustomAppBar].
  final Widget? title;

  /// [Widget]s displayed in a row before the [title].
  final List<Widget> leading;

  /// [Widget]s displayed in a row after the [title].
  final List<Widget> actions;

  /// Padding to apply to the contents.
  final EdgeInsets? padding;

  /// [Border] to apply to this [CustomAppBar].
  final Border? border;

  final Color? background;

  final void Function()? onBottom;

  /// Height of the [CustomAppBar].
  static const double height = 60;

  @override
  Size get preferredSize => const Size(double.infinity, CustomAppBar.height);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (onBottom != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: const Offset(0, 14),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Color(0x22000000),
                        blurStyle: BlurStyle.outer,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.monetization_on_outlined,
                    color: Color(0xFF72B060),
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        _bar(context),
        if (onBottom != null) Positioned.fill(child: _button(onBottom)),
      ],
    );
  }

  Widget _button(void Function()? onPressed) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: UnconstrainedBox(
        child: Transform.translate(
          offset: const Offset(0, 14),
          child: WidgetButton(
            onPressed: onPressed,
            child: Container(
              // padding: const EdgeInsets.all(4),
              // width: 32, height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                // color: Colors.white,
                // boxShadow: [
                //   BoxShadow(
                //     blurRadius: 8,
                //     color: Color(0x22000000),
                //     blurStyle: BlurStyle.outer,
                //   )
                // ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgLoader.asset(
                    'assets/icons/balance.svg',
                    width: 30,
                    height: 30,
                  ),
                  const Positioned.fill(
                    child: Center(
                      child: Text(
                        '\$',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              // child: Center(
              //   child: SvgLoader.asset(
              //     'assets/icons/paid_chat.svg',
              //     width: 24,
              //     height: 24,
              //   ),
              // ),
              // child: const Icon(
              //   Icons.monetization_on_outlined,
              //   color: Color(0xFF72B060),
              //   size: 32,
              // ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, [List<Widget> bottom = const []]) {
    final Style style = Theme.of(context).extension<Style>()!;
    final double top = MediaQuery.of(context).padding.top;

    final Widget row = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          ...leading,
          Expanded(
            child: DefaultTextStyle.merge(
              style: Theme.of(context).appBarTheme.titleTextStyle,
              child: Center(child: title ?? const SizedBox.shrink()),
            ),
          ),
          ...actions,
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (top != 0)
          Container(
            height: top,
            width: double.infinity,
            color: Colors.white,
          ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Container(
              // height: CustomAppBar.height,
              constraints: BoxConstraints(minHeight: height),
              decoration: BoxDecoration(
                borderRadius: style.cardRadius,
                boxShadow: const [
                  CustomBoxShadow(
                    blurRadius: 8,
                    color: Color(0x22000000),
                    blurStyle: BlurStyle.outer,
                  ),
                ],
              ),
              child: ConditionalBackdropFilter(
                condition: style.cardBlur > 0,
                filter: ImageFilter.blur(
                  sigmaX: style.cardBlur,
                  sigmaY: style.cardBlur,
                ),
                borderRadius: style.cardRadius,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    borderRadius: style.cardRadius,
                    border: border ?? style.cardBorder,
                    color: background ?? style.cardColor,
                  ),
                  child: row,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // void _expand(BuildContext context) {
  //   final Style style = Theme.of(context).extension<Style>()!;
  //   final TextStyle textStyle = TextStyle(fontSize: 15);

  //   _entry?.remove();
  //   _entry = OverlayEntry(
  //     builder: (context) {
  //       return Stack(
  //         fit: StackFit.expand,
  //         children: [
  //           GestureDetector(
  //             behavior: HitTestBehavior.deferToChild,
  //             onTap: () {
  //               _entry?.remove();
  //               _entry = null;
  //             },
  //             child: Container(color: Colors.black.withOpacity(0.5)),
  //           ),
  //           Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               SizedBox(
  //                 height: height,
  //                 child: _bar(context),
  //               ),
  //               Container(
  //                 margin: const EdgeInsets.symmetric(horizontal: 21),
  //                 constraints: const BoxConstraints(maxWidth: 300),
  //                 decoration: BoxDecoration(
  //                   color: const Color.fromARGB(255, 237, 237, 237),
  //                   borderRadius: BorderRadius.only(
  //                     bottomLeft: style.cardRadius.bottomLeft,
  //                     bottomRight: style.cardRadius.bottomRight,
  //                   ),
  //                 ),
  //                 child: Center(
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       const SizedBox(height: 21),
  //                       Center(
  //                         child: Text(
  //                           'Платный чат',
  //                           style: textStyle.copyWith(fontSize: 18),
  //                         ),
  //                       ),
  //                       const SizedBox(height: 21),
  //                       Padding(
  //                         padding: const EdgeInsets.fromLTRB(21, 0, 21, 0),
  //                         child: Row(
  //                           children: [
  //                             Text('Отправить сообщение', style: textStyle),
  //                             Spacer(),
  //                             Text('\$0.91', style: textStyle),
  //                           ],
  //                         ),
  //                       ),
  //                       const SizedBox(height: 12),
  //                       Padding(
  //                         padding: const EdgeInsets.fromLTRB(21, 0, 21, 0),
  //                         child: Row(
  //                           children: [
  //                             Text('Совершить звонок', style: textStyle),
  //                             Spacer(),
  //                             Text('\$0.12/мин', style: textStyle),
  //                           ],
  //                         ),
  //                       ),
  //                       const SizedBox(height: 32),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               Transform.translate(
  //                 offset: const Offset(0, -21),
  //                 child: WidgetButton(
  //                   onPressed: () {
  //                     _entry?.remove();
  //                     _entry = null;
  //                   },
  //                   child: Container(
  //                     padding: const EdgeInsets.all(4),
  //                     decoration: const BoxDecoration(
  //                       shape: BoxShape.circle,
  //                       color: Color.fromARGB(255, 237, 237, 237),
  //                       // boxShadow: [
  //                       //   BoxShadow(
  //                       //     blurRadius: 8,
  //                       //     color: Color(0x22000000),
  //                       //     blurStyle: BlurStyle.outer,
  //                       //   )
  //                       // ],
  //                     ),
  //                     child: Center(
  //                       child: SvgLoader.asset(
  //                         'assets/icons/paid_chat.svg',
  //                         width: 24,
  //                         height: 24,
  //                       ),
  //                     ),
  //                     // child: const Icon(
  //                     //   Icons.monetization_on_outlined,
  //                     //   color: Color(0xFF72B060),
  //                     //   size: 32,
  //                     // ),
  //                   ),
  //                 ),
  //               )
  //             ],
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   Overlay.of(context).insert(_entry!);
  // }
}
