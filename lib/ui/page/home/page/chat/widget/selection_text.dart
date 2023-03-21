import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;

import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/util/platform_utils.dart';

/// [Text] wrapped in a [SelectionArea] if [selectable].
class SelectionText extends StatelessWidget {
  const SelectionText(
    String this.text, {
    super.key,
    this.selectable = true,
    this.style,
    this.onSelecting,
    this.onChanged,
  }) : span = null;

  const SelectionText.rich(
    InlineSpan this.span, {
    super.key,
    this.selectable = true,
    this.style,
    this.onSelecting,
    this.onChanged,
  }) : text = null;

  /// Text to be selected.
  final String? text;

  /// [InlineSpan] to be selected.
  final InlineSpan? span;

  /// Indicator whether this [SelectionText] is allowed to be selected.
  final bool selectable;

  /// Optional [TextStyle] of this [SelectionText].
  final TextStyle? style;

  /// Callback, called when a selection of the [text] starts or ends.
  final void Function(bool)? onSelecting;

  /// Callback, called when the [SelectedContent] changes.
  final void Function(SelectedContent?)? onChanged;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (text != null) {
      child = Text(text!, style: style);
    } else {
      child = Text.rich(span!, style: style);
    }

    if (selectable) {
      if (PlatformUtils.isDesktop) {
        child = Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => onSelecting?.call(true),
          onPointerUp: (_) => onSelecting?.call(false),
          onPointerCancel: (_) => onSelecting?.call(false),
          child: child,
        );
      } else {
        child = SelectionArea(onSelectionChanged: onChanged, child: child);

        if (PlatformUtils.isWeb) {
          child = ContextMenuInterceptor(child: child);
        }
      }
    }

    return child;
  }
}
