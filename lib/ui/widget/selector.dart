// ignore_for_file: public_member_api_docs, sort_constructors_first
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

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        builder: (context) => _Builder(
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
        ),
      );
    } else {
      return showDialog(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        builder: (context) => _Builder(
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
        ),
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
      return _Mobile(
        items: widget.items,
        initial: widget.initial,
        selected: _selected,
        debounceWorker: _debounce,
        onSelected: widget.onSelected,
        itemBuilder: widget.itemBuilder,
      );
    } else {
      return _Desktop(
        buttonKey: widget.buttonKey,
        alignment: widget.alignment,
        width: widget.width,
        buttonBuilder: widget.buttonBuilder,
        selected: _selected,
        debounceWorker: _debounce,
        onSelected: widget.onSelected,
        itemBuilder: widget.itemBuilder,
        margin: widget.margin,
        items: widget.items,
      );
    }
  }
}

class _Builder<T> extends StatelessWidget {
  final Duration? debounce;
  final T? initial;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final Widget Function(int i, T data)? buttonBuilder;
  final void Function(T)? onSelected;
  final GlobalKey? buttonKey;
  final Alignment alignment;
  final double width;
  final EdgeInsets margin;
  final bool isMobile;
  const _Builder({
    Key? key,
    required this.debounce,
    required this.initial,
    required this.items,
    required this.itemBuilder,
    required this.buttonBuilder,
    required this.onSelected,
    required this.buttonKey,
    required this.alignment,
    required this.width,
    required this.margin,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}

/// Returns mobile design of this [Selector].
class _Mobile<T> extends StatelessWidget {
  final List<T> items;
  final T? initial;
  final Rx<T> selected;
  final Worker? debounceWorker;
  final void Function(T)? onSelected;
  final Widget Function(T) itemBuilder;
  const _Mobile({
    Key? key,
    required this.items,
    required this.initial,
    required this.selected,
    required this.debounceWorker,
    required this.onSelected,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12 + 3 + 12 + 14 * 2 + min(items.length * 38, 330) + 12,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Stack(
                  children: [
                    CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem:
                            initial == null ? 0 : items.indexOf(selected.value),
                      ),
                      magnification: 1,
                      squeeze: 1,
                      looping: true,
                      diameterRatio: 100,
                      useMagnifier: false,
                      itemExtent: 38,
                      selectionOverlay: Container(
                        margin:
                            const EdgeInsetsDirectional.only(start: 8, end: 8),
                        decoration:
                            const BoxDecoration(color: Color(0x3363B4FF)),
                      ),
                      onSelectedItemChanged: (int i) {
                        HapticFeedback.selectionClick();
                        selected.value = items[i];
                        if (debounceWorker == null) {
                          onSelected?.call(selected.value);
                        }
                      },
                      children: items
                          .map(
                            (e) => Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(46, 0, 29, 0),
                                child: itemBuilder(e),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 15,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 15,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0xFFFFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns desktop design of this [Selector].
class _Desktop<T> extends StatelessWidget {
  final GlobalKey<State<StatefulWidget>>? buttonKey;
  final Alignment alignment;
  final double width;
  final Widget Function(int, T)? buttonBuilder;
  final Rx<T> selected;
  final Worker? debounceWorker;
  final void Function(T)? onSelected;
  final Widget Function(T) itemBuilder;
  final EdgeInsets margin;
  final List<T> items;
  const _Desktop({
    Key? key,
    required this.buttonKey,
    required this.alignment,
    required this.width,
    required this.buttonBuilder,
    required this.selected,
    required this.debounceWorker,
    required this.onSelected,
    required this.itemBuilder,
    required this.margin,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return LayoutBuilder(builder: (context, constraints) {
      double? left, right;
      double? top, bottom;

      Offset offset =
          Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
      final keyContext = buttonKey?.currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox?;
        offset = box?.localToGlobal(Offset.zero) ?? offset;

        if (alignment == Alignment.topCenter) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0) / 2,
            offset.dy,
          );

          left = offset.dx - width / 2;
          bottom = MediaQuery.of(context).size.height - offset.dy;
        } else if (alignment == Alignment.topLeft) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0),
            offset.dy,
          );

          left = offset.dx - width;
          bottom = MediaQuery.of(context).size.height - offset.dy;
        } else if (alignment == Alignment.bottomCenter) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0) / 2,
            offset.dy + (box?.size.height ?? 0),
          );

          left = offset.dx - width / 2;
          top = offset.dy;
        } else if (alignment == Alignment.bottomRight) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0),
            offset.dy + (box?.size.height ?? 0),
          );

          left = offset.dx - width / 2;
          top = offset.dy;
        } else {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0) / 2,
            offset.dy + (box?.size.height ?? 0) / 2,
          );

          left = offset.dx - width / 2;
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
        if (buttonBuilder != null) {
          return buttonBuilder!(i, item);
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
                selected.value = item;
                if (debounceWorker == null) {
                  onSelected?.call(selected.value);
                }
              },
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: itemBuilder(item),
                ),
              ),
            ),
          ),
        );
      }

      return Stack(
        children: [
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: Listener(
              onPointerUp: (d) => Navigator.of(context).pop(),
              child: Container(
                width: width,
                margin: margin,
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: style.contextMenuBackgroundColor,
                  borderRadius: style.contextMenuRadius,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: style.contextMenuRadius,
                      child: ListView(
                        shrinkWrap: true,
                        children: items.mapIndexed(button).toList(),
                      ),
                    ),
                    if (items.length >= 8)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 15,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0x00FFFFFF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (items.length >= 8)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 15,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x00FFFFFF),
                                  Color(0xFFFFFFFF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
