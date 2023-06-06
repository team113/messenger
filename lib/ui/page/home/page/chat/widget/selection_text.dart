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
    this.textAlign,
  }) : span = null;

  const SelectionText.rich(
    InlineSpan this.span, {
    super.key,
    this.selectable = true,
    this.style,
    this.onSelecting,
    this.onChanged,
    this.textAlign,
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

  final TextAlign? textAlign;

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
      child = Text(
        widget.text!,
        style: widget.style,
        textAlign: widget.textAlign,
      );
    } else {
      child = Text.rich(
        widget.span!,
        style: widget.style,
        textAlign: widget.textAlign,
      );
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
    } else if (PlatformUtils.isDesktop) {
      child = SelectionContainer.disabled(child: child);
    }

    return child;
  }
}
