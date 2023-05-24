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


import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/util/platform_utils.dart';

/// Dropdown selecting the provided [items].
///
/// Intended to be displayed with the [show] method.
class Selector<T> extends StatefulWidget {
  const Selector({
    Key? key,
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
  }) : super(key: key);

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

    // if (isMobile) {
    //   return showModalBottomSheet(
    //     context: context,
    //     barrierColor: kCupertinoModalBarrierColor,
    //     backgroundColor: Colors.white,
    //     shape: const RoundedRectangleBorder(
    //       borderRadius: BorderRadius.only(
    //         topLeft: Radius.circular(8),
    //         topRight: Radius.circular(8),
    //       ),
    //     ),
    //     builder: builder,
    //   );
    // } else {
    return showDialog(
      context: context,
      // barrierColor: kCupertinoModalBarrierColor,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: builder,
    );
    // }
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

  final GlobalKey _itemsKey = GlobalKey();

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

    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    _debounce?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // if (widget.isMobile) {
    //   return _mobile(context);
    // } else {
    return _desktop(context);
    // }
  }

  /// Returns desktop design of this [Selector].
  Widget _desktop(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return LayoutBuilder(builder: (context, constraints) {
      double? left, right;
      double? top, bottom;

      Offset offset =
          Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
      final keyContext = widget.buttonKey?.currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox?;
        offset = box?.localToGlobal(Offset.zero) ?? offset;

        Offset? size;

        final itemsContext = _itemsKey.currentContext;
        if (itemsContext != null) {
          final box = itemsContext.findRenderObject() as RenderBox?;
          size = box?.localToGlobal(Offset.zero) ?? offset;
        }

        if (widget.alignment == Alignment.topCenter) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0) / 2,
            offset.dy,
          );

          left =
              offset.dx - (size?.dx ?? widget.width) / 2 - widget.margin.right;
          bottom = MediaQuery.of(context).size.height - offset.dy;
        } else if (widget.alignment == Alignment.topLeft) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0),
            offset.dy - widget.margin.bottom,
          );

          // left = offset.dx - widget.width;
          right = constraints.maxWidth - offset.dx;
          bottom = MediaQuery.of(context).size.height - offset.dy;
        } else if (widget.alignment == Alignment.topRight) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0),
            offset.dy - widget.margin.bottom,
          );

          left = offset.dx - widget.margin.right;
          // right = constraints.maxWidth - offset.dx;
          bottom = MediaQuery.of(context).size.height - offset.dy;
        } else if (widget.alignment == Alignment.bottomCenter) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0) / 2,
            offset.dy + (box?.size.height ?? 0),
          );

          left = offset.dx - widget.width / 2;
          top = offset.dy;
        } else if (widget.alignment == Alignment.bottomRight) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0),
            offset.dy + (box?.size.height ?? 0),
          );

          left = offset.dx - widget.margin.right;
          top = offset.dy - widget.margin.bottom;
        } else if (widget.alignment == Alignment.bottomLeft) {
          offset = Offset(
            offset.dx - (box?.size.width ?? 0),
            offset.dy + (box?.size.height ?? 0),
          );

          right = constraints.maxWidth - 100 - offset.dx;
          top = offset.dy - widget.margin.bottom;
        } else {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0) / 2,
            offset.dy + (box?.size.height ?? 0) / 2,
          );

          left = offset.dx - widget.width / 2;
          top = offset.dy;
        }
      }

      if (left != null && left < 0) {
        left = 0;
      } else if (right != null && right > constraints.maxWidth) {
        right = constraints.maxWidth;
      }

      if (top != null && top < 0) {
        top = 0;
      } else if (bottom != null && bottom > constraints.maxHeight) {
        bottom = constraints.maxHeight;
      }

      // Builds the provided [item].
      Widget button(int i, T item) {
        if (widget.buttonBuilder != null) {
          return widget.buttonBuilder!(i, item);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Material(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: InkWell(
              hoverColor: const Color(0x3363B4FF),
              highlightColor: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                _selected.value = item;
                if (_debounce == null) {
                  widget.onSelected?.call(_selected.value);
                }
              },
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: widget.itemBuilder(item),
                ),
              ),
            ),
          ),
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: Listener(
              onPointerUp: (d) => Navigator.of(context).pop(),
              child: Container(
                // width: widget.width,
                margin: widget.margin,
                // constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: style.contextMenuBackgroundColor,
                  borderRadius: style.contextMenuRadius,
                  border:
                      Border.all(color: const Color(0xFFAAAAAA), width: 0.5),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 12,
                      color: Color(0x33000000),
                      blurStyle: BlurStyle.outer,
                    )
                  ],
                ),
                child: IntrinsicWidth(
                  key: _itemsKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.items.mapIndexed(button).toList(),
                  ),
                ),
                // child: Stack(
                //   children: [
                //     // ClipRRect(
                //     //   borderRadius: style.contextMenuRadius,
                //     //   child: ListView(
                //     //     shrinkWrap: true,
                //     //     children: widget.items.mapIndexed(button).toList(),
                //     //   ),
                //     // ),
                //     // if (widget.items.length >= 8)
                //     //   Positioned.fill(
                //     //     child: Align(
                //     //       alignment: Alignment.topCenter,
                //     //       child: Container(
                //     //         height: 15,
                //     //         margin: const EdgeInsets.only(right: 10),
                //     //         decoration: const BoxDecoration(
                //     //           gradient: LinearGradient(
                //     //             begin: Alignment.topCenter,
                //     //             end: Alignment.bottomCenter,
                //     //             colors: [
                //     //               Color(0xFFFFFFFF),
                //     //               Color(0x00FFFFFF),
                //     //             ],
                //     //           ),
                //     //         ),
                //     //       ),
                //     //     ),
                //     //   ),
                //     // if (widget.items.length >= 8)
                //     //   Positioned.fill(
                //     //     child: Align(
                //     //       alignment: Alignment.bottomCenter,
                //     //       child: Container(
                //     //         height: 15,
                //     //         margin: const EdgeInsets.only(right: 10),
                //     //         decoration: const BoxDecoration(
                //     //           gradient: LinearGradient(
                //     //             begin: Alignment.topCenter,
                //     //             end: Alignment.bottomCenter,
                //     //             colors: [
                //     //               Color(0x00FFFFFF),
                //     //               Color(0xFFFFFFFF),
                //     //             ],
                //     //           ),
                //     //         ),
                //     //       ),
                //     //     ),
                //     //   ),
                //   ],
                // ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
