import 'package:flutter/material.dart';
import 'package:messenger/ui/widget/animated_switcher.dart';
import 'package:messenger/ui/widget/selected_dot.dart';

import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';

/// Rectangular filled selectable button.
class RectangleButton extends StatelessWidget {
  const RectangleButton({
    super.key,
    this.selected = false,
    this.onPressed,
    required this.label,
    this.subtitle,
    this.trailingColor,
    this.radio = false,
    this.toggleable = false,
  });

  /// Label of this [RectangleButton].
  final String label;

  final String? subtitle;

  /// Indicator whether this [RectangleButton] is selected, meaning an
  /// [Icons.check] should be displayed in a trailing.
  final bool selected;

  /// Indicator whether this [RectangleButton] is radio button.
  final bool radio;

  /// Callback, called when this [RectangleButton] is pressed.
  final void Function()? onPressed;

  /// [Color] of the trailing background, when [selected] is `true`.
  final Color? trailingColor;

  /// Indicator whether [onPressed] can be invoked when [selected].
  final bool toggleable;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Material(
      borderRadius: BorderRadius.circular(10),
      color:
          selected ? style.colors.primary : style.colors.onPrimary.darken(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: selected && !toggleable ? null : onPressed,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            subtitle == null ? 16 : 8,
            16,
            subtitle == null ? 16 : 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: selected
                                ? style.fonts.normal.regular.onPrimary
                                : style.fonts.normal.regular.onBackground,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: selected
                            ? style.fonts.small.regular.onPrimary
                            : style.fonts.small.regular.secondary,
                      ),
                    ],
                  ],
                ),
              ),
              if (toggleable) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SafeAnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: selected
                        ? CircleAvatar(
                            backgroundColor: style.colors.onPrimary,
                            radius: 12,
                            child: Icon(
                              Icons.check,
                              color: style.colors.primary,
                              size: 12,
                            ),
                          )
                        : radio
                            ? const SelectedDot()
                            : const SizedBox(),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
