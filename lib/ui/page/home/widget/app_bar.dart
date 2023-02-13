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
import 'package:messenger/ui/widget/widget_button.dart';

import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';

/// Custom stylized and decorated [AppBar].
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.leading = const [],
    this.actions = const [],
    this.padding,
    this.background,
    this.border,
    this.expandable = false,
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

  final bool expandable;

  /// Height of the [CustomAppBar].
  static const double height = 60;

  @override
  Size get preferredSize => const Size(double.infinity, CustomAppBar.height);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _expanded = false;
  OverlayEntry? _entry;
  GlobalKey _key = GlobalKey();

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final double top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        _bar(context),
        if (widget.expandable)
          Positioned.fill(child: _button(() => _expand(context))),
      ],
    );
  }

  Widget _button(void Function()? onPressed) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: const Offset(0, 12),
        child: WidgetButton(
          onPressed: onPressed,
          child: Container(
            padding: const EdgeInsets.all(4),
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
      padding: widget.padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          ...widget.leading,
          Expanded(
            child: DefaultTextStyle.merge(
              style: Theme.of(context).appBarTheme.titleTextStyle,
              child: Center(child: widget.title ?? const SizedBox.shrink()),
            ),
          ),
          ...widget.actions,
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
              constraints: BoxConstraints(minHeight: CustomAppBar.height),
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
                    border: widget.border ?? style.cardBorder,
                    color: widget.background ?? style.cardColor,
                  ),
                  child: bottom.isEmpty
                      ? row
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 2.4),
                            row,
                            Container(
                              color: Color(0xFFF9F9F9),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: bottom,
                              ),
                            ),
                            // ...bottom,
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _expand(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final TextStyle textStyle = TextStyle(fontSize: 15);

    _entry?.remove();
    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: () {
                _entry?.remove();
                _entry = null;
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bar(
                  context,
                  [
                    const SizedBox(height: 12),
                    Center(
                      child: Text('alex3 has set a fee for:', style: textStyle),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                      child: Row(
                        children: [
                          Text('- incoming messages', style: textStyle),
                          Spacer(),
                          Text('\$0.91', style: textStyle),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                      child: Row(
                        children: [
                          Text('- incoming calls', style: textStyle),
                          Spacer(),
                          Text('\$0.12/min', style: textStyle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 21),
                    Center(
                      child: Text('You get paid for:', style: textStyle),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                      child: Row(
                        children: [
                          Text('- incoming messages', style: textStyle),
                          Spacer(),
                          Text('\$0.91', style: textStyle),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                      child: Row(
                        children: [
                          Text('- incoming calls', style: textStyle),
                          Spacer(),
                          Text('\$0.12/min', style: textStyle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 31),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -21),
                  child: WidgetButton(
                    onPressed: () {
                      _entry?.remove();
                      _entry = null;
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
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
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_entry!);
  }
}
