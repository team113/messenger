import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;

import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/util/platform_utils.dart';

/// [Text] wrapped in a [SelectionArea] if [selectable].
class SelectionText extends StatefulWidget {
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
  State<SelectionText> createState() => _SelectionTextState();
}

/// State of a [SelectionText] invoking a [SelectionText.onChanged] in its
/// [initState].
class _SelectionTextState extends State<SelectionText> {
  @override
  void initState() {
    widget.onChanged?.call(null);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (widget.text != null) {
      child = Text(widget.text!, style: widget.style);
    } else {
      child = Text.rich(widget.span!, style: widget.style);
    }

    if (widget.selectable) {
      if (PlatformUtils.isDesktop) {
        child = Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => widget.onSelecting?.call(true),
          onPointerUp: (_) => widget.onSelecting?.call(false),
          onPointerCancel: (_) => widget.onSelecting?.call(false),
          child: child,
        );
      } else {
        child =
            SelectionArea(onSelectionChanged: widget.onChanged, child: child);

        if (PlatformUtils.isWeb) {
          child = ContextMenuInterceptor(child: child);
        }
      }
    }

    return child;
  }
}
