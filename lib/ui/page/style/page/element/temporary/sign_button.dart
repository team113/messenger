import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/page/home/widget/field_button.dart';

class SignButton extends StatelessWidget {
  const SignButton({
    super.key,
    this.text = '',
    this.leading,
    this.asset = '',
    this.assetWidth = 20,
    this.assetHeight = 20,
    this.padding = EdgeInsets.zero,
    this.onPressed,
    this.color,
  });

  final String text;
  final Widget? leading;
  final String asset;
  final double assetWidth;
  final double assetHeight;
  final EdgeInsets padding;
  final void Function()? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Center(
      child: PrefixButton(
        color: color,
        text: text,
        style: style.fonts.titleMediumOnPrimary,
        onPressed: onPressed ?? () {},
        prefix: Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 4).add(padding),
          child: leading ??
              SvgImage.asset(
                'assets/icons/$asset.svg',
                width: assetWidth,
                height: assetHeight,
              ),
        ),
      ),
    );
  }
}

class PrefixButton extends StatelessWidget {
  const PrefixButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.style,
    this.prefix,
    this.color,
  });

  final String text;
  final TextStyle? style;
  final void Function()? onPressed;
  final Widget? prefix;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        NewFieldButton(
          color: color,
          text: text,
          style: style,
          onPressed: onPressed,
          textAlign: TextAlign.center,
        ),
        if (prefix != null) IgnorePointer(child: prefix!),
      ],
    );
  }
}

class NewFieldButton extends StatefulWidget {
  const NewFieldButton({
    super.key,
    this.text,
    this.textAlign = TextAlign.start,
    this.hint,
    this.maxLines = 1,
    this.onPressed,
    this.onTrailingPressed,
    this.trailing,
    this.prefix,
    this.style,
    this.border,
    this.prefixText,
    this.prefixStyle,
    this.label,
    this.color,
    this.floatingLabelBehavior = FloatingLabelBehavior.auto,
  });

  /// Optional label of this [FieldButton].
  final String? text;

  /// [TextAlign] of the [text].
  final TextAlign textAlign;

  /// Optional hint of this [FieldButton].
  final String? hint;

  /// Maximum number of lines to show at one time, wrapping if necessary.
  final int? maxLines;

  /// Callback, called when this [FieldButton] is pressed.
  final VoidCallback? onPressed;

  /// Callback, called when the [trailing] is pressed.
  ///
  /// Only meaningful if the [trailing] is `null`.
  final VoidCallback? onTrailingPressed;

  /// Optional trailing [Widget].
  final Widget? trailing;

  /// Optional prefix [Widget].
  final Widget? prefix;

  /// [TextStyle] of the [text].
  final TextStyle? style;

  final Color? color;

  final Color? border;

  final String? prefixText;
  final TextStyle? prefixStyle;
  final String? label;
  final FloatingLabelBehavior floatingLabelBehavior;

  @override
  State<NewFieldButton> createState() => _NewFieldButtonState();
}

/// State of a [FieldButton] maintaining the [_hovered] indicator.
class _NewFieldButtonState extends State<NewFieldButton> {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return NewOutlinedRoundedButton(
      title: Text(widget.text ?? ''),
      maxWidth: double.infinity,
      color: widget.color ?? style.colors.onPrimary,
      disabled: style.colors.onPrimary,
      onPressed: widget.onPressed,
      style: style.fonts.titleLarge,
      height: 46,
      border: Border.all(
        width: 0.5,
        color: style.colors.secondary,
      ),
    );
  }
}

class NewOutlinedRoundedButton extends StatelessWidget {
  const NewOutlinedRoundedButton({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.leadingWidth = 24,
    this.onPressed,
    this.onLongPress,
    this.gradient,
    this.elevation = 0,
    this.color,
    this.disabled,
    this.maxWidth = 250 * 0.72,
    this.border,
    // this.maxWidth = 210,
    this.height = 42,
    this.shadows,
    this.style,
  });

  /// Primary content of this button.
  ///
  /// Typically a [Text] widget.
  final Widget? title;

  /// Additional content displayed below the [title].
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// Widget to display before the [title].
  ///
  /// Typically an [Icon] or a [CircleAvatar] widget.
  final Widget? leading;

  /// Callback, called when this button is tapped or activated other way.
  final VoidCallback? onPressed;

  /// Callback, called when this button is long-pressed.
  final VoidCallback? onLongPress;

  /// Background color of this button.
  final Color? color;
  final Color? disabled;

  /// Gradient to use when filling this button.
  ///
  /// If this is specified, [color] has no effect.
  final Gradient? gradient;

  /// Z-coordinate at which this button should be placed relatively to its
  /// parent.
  ///
  /// This controls the size of the shadow below this button.
  final double elevation;

  /// Maximum width this button is allowed to occupy.
  final double maxWidth;

  /// Height of this button.
  final double? height;

  /// [BoxShadow]s to apply to this button.
  final List<BoxShadow>? shadows;

  final double? leadingWidth;

  final TextStyle? style;

  final Border? border;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final BorderRadius borderRadius = BorderRadius.circular(
      15 * 0.7 * ((height ?? 42) / 42),
    );

    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        minHeight: height ?? 0,
        maxHeight: height ?? double.infinity,
      ),
      decoration: BoxDecoration(
        boxShadow: shadows,
        color: onPressed == null
            ? disabled ?? style.colors.secondaryHighlight
            : color ?? style.colors.onPrimary,
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
      ),
      child: Material(
        color: style.colors.transparent,
        elevation: elevation,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          onLongPress: onLongPress,
          hoverColor: style.colors.secondary.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8 * 0.7,
              vertical: 6 * 0.7,
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                if (leading != null)
                  SizedBox(width: leadingWidth, child: Center(child: leading!)),
                const SizedBox(width: 8),
                Expanded(
                  child: DefaultTextStyle.merge(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: this.style ?? style.fonts.titleLarge,
                    child: Center(
                      child: Padding(
                        padding: leading == null
                            ? EdgeInsets.zero
                            : const EdgeInsets.only(left: 10 * 0.7),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            title ?? Container(),
                            if (subtitle != null)
                              const SizedBox(height: 1 * 0.7),
                            if (subtitle != null)
                              DefaultTextStyle.merge(
                                style: style.fonts.labelMedium,
                                child: subtitle!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (leading != null)
                  SizedBox(
                    width: leadingWidth,
                    child: Center(child: Opacity(opacity: 0, child: leading!)),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
