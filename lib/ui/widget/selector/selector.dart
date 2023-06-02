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

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/util/platform_utils.dart';
import 'desktop.dart';
import 'mobile.dart';

/// Dropdown selecting the provided [items].
///
/// Intended to be displayed with the [show] method.
class Selector<T> extends StatefulWidget {
  const Selector({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.buttonBuilder,
    this.initial,
    this.onSelected,
    this.buttonKey,
    this.alignment = Alignment.topCenter,
    this.debounce,
    this.width = 260,
    this.margin = EdgeInsets.zero,
    required this.isMobile,
  });

  /// [List] of items to select from.
  final List<T> items;

  /// Initially selected item.
  final T? initial;

  /// Callback, called when the provided item is selected.
  final void Function(T)? onSelected;

  /// Builder building the provided item.
  final Widget Function(T data) itemBuilder;

  /// Builder building a button to place the provided item onto.
  final Widget Function(int i, T data)? buttonBuilder;

  /// [GlobalKey] of an [Object] displaying this [Selector].
  final GlobalKey? buttonKey;

  /// [Alignment] this [Selector] should take relative to the [buttonKey].
  final Alignment alignment;

  /// [Duration] of a debounce effect.
  ///
  /// No debounce is applied if `null` is provided.
  final Duration? debounce;

  /// Width this [Selector] should occupy.
  final double width;

  /// Margin to apply to this [Selector].
  final EdgeInsets margin;

  /// Indicator whether a mobile design with [CupertinoPicker] should be used.
  final bool isMobile;

  /// Displays a [Selector] wrapped in a modal popup.
  static Future<T?> show<T extends Object>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(T data) itemBuilder,
    Widget Function(int i, T data)? buttonBuilder,
    void Function(T)? onSelected,
    GlobalKey? buttonKey,
    Alignment alignment = Alignment.topCenter,
    Duration? debounce,
    double width = 260,
    EdgeInsets margin = EdgeInsets.zero,
    T? initial,
  }) {
    final bool isMobile = context.isMobile;

    Widget builder(BuildContext context) {
      return Selector<T>(
        debounce: debounce,
        initial: initial,
        items: items,
        itemBuilder: itemBuilder,
        buttonBuilder: buttonBuilder,
        onSelected: onSelected,
        buttonKey: buttonKey,
        alignment: alignment,
        width: width,
        margin: margin,
        isMobile: isMobile,
      );
    }

    final Style style = Theme.of(context).extension<Style>()!;

    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        backgroundColor: style.colors.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        builder: builder,
      );
    } else {
      return showDialog(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        builder: builder,
      );
    }
  }

  @override
  State<Selector<T>> createState() => _SelectorState<T>();
}

/// State of a [Selector] maintaining the [_debounce].
class _SelectorState<T> extends State<Selector<T>> {
  /// Currently selected item.
  late Rx<T> _selected;

  /// [Worker] debouncing the [_selected] value, if any debounce is specified.
  Worker? _debounce;

  @override
  void initState() {
    _selected = Rx(widget.initial ?? widget.items.first);

    if (widget.debounce != null) {
      _debounce = debounce(
        _selected,
        (T value) => widget.onSelected?.call(value),
        time: widget.debounce,
      );
    }

    super.initState();
  }

  @override
  void dispose() {
    _debounce?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return MobileSelector<T>(
        items: widget.items,
        initial: widget.initial,
        initialItem:
            widget.initial == null ? 0 : widget.items.indexOf(_selected.value),
        child: widget.itemBuilder(e as T),
        onSelectedItemChanged: (int i) {
          HapticFeedback.selectionClick();
          _selected.value = widget.items[i];
          if (_debounce == null) {
            widget.onSelected?.call(_selected.value);
          }
        },
      );
    } else {
      return DesktopSelector(
        selected: _selected,
        debounce: _debounce,
        onSelected: widget.onSelected,
        buttonKey: widget.buttonKey,
        items: widget.items,
        alignment: widget.alignment,
        width: widget.width,
        margin: widget.margin,
        buttonBuilder: widget.buttonBuilder,
        itemBuilder: widget.itemBuilder,
      );
    }
  }
}
