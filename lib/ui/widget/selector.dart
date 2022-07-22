// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/util/platform_utils.dart';

/// Dropdown selecting the provided [items].
///
/// Intended to be displayed with the [show] method.
class Selector<T extends Object> extends StatefulWidget {
  const Selector({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.initial,
    this.onSelected,
    this.buttonKey,
    this.alignment = Alignment.topCenter,
    this.debounce,
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

  /// [GlobalKey] of an [Object] displaying this [Selector].
  final GlobalKey? buttonKey;

  /// [Alignment] this [Selector] should take relative to the [buttonKey].
  final Alignment alignment;

  /// [Duration] of a debounce effect.
  ///
  /// No debounce is applied if `null` is provided.
  final Duration? debounce;

  /// Indicator whether a mobile design with [CupertinoPicker] should be used.
  final bool isMobile;

  /// Displays a [Selector] wrapped in a modal popup.
  static Future<T?> show<T extends Object>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(T data) itemBuilder,
    void Function(T)? onSelected,
    GlobalKey? buttonKey,
    Alignment alignment = Alignment.topCenter,
    Duration? debounce,
    T? initial,
  }) {
    bool isMobile = context.isMobile;
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
        builder: (context) {
          return Selector<T>(
            debounce: debounce,
            initial: initial,
            items: items,
            itemBuilder: itemBuilder,
            onSelected: onSelected,
            buttonKey: buttonKey,
            alignment: alignment,
            isMobile: isMobile,
          );
        },
      );
    } else {
      return showDialog(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        builder: (context) {
          return Selector<T>(
            debounce: debounce,
            initial: initial,
            items: items,
            itemBuilder: itemBuilder,
            onSelected: onSelected,
            buttonKey: buttonKey,
            alignment: alignment,
            isMobile: isMobile,
          );
        },
      );
    }
  }

  @override
  State<Selector<T>> createState() => _SelectorState<T>();
}

/// State of a [Selector] maintaining the [_debounce].
class _SelectorState<T extends Object> extends State<Selector<T>> {
  /// Currently selected item.
  late Rx<T> selected;

  /// [Worker] debouncing the [selected] value, if any debounce is specified.
  Worker? _debounce;

  @override
  void initState() {
    selected = Rx(widget.initial ?? widget.items.first);

    if (widget.debounce != null) {
      _debounce = debounce(
        selected,
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
      return _mobile(context);
    } else {
      return _desktop(context);
    }
  }

  /// Returns mobile design of this [Selector].
  Widget _mobile(BuildContext context) {
    return Container(
      height: 12 + 3 + 12 + 14 * 2 + min(widget.items.length * 38, 330) + 12,
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
                        initialItem: widget.initial == null
                            ? 0
                            : widget.items.indexOf(selected.value),
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
                        selected.value = widget.items[i];
                        if (_debounce == null) {
                          widget.onSelected?.call(selected.value);
                        }
                      },
                      children: widget.items
                          .map(
                            (e) => Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(46, 0, 29, 0),
                                child: widget.itemBuilder(e),
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

  /// Returns desktop design of this [Selector].
  Widget _desktop(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double? left, right;
      double? top, bottom;

      Offset offset =
          Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
      final keyContext = widget.buttonKey?.currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox?;
        offset = box?.localToGlobal(Offset.zero) ?? offset;

        if (widget.alignment == Alignment.topCenter) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0) / 2,
            offset.dy,
          );

          left = offset.dx - 260 / 2;
          bottom = MediaQuery.of(context).size.height - offset.dy;
        } else if (widget.alignment == Alignment.bottomCenter) {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0) / 2,
            offset.dy + (box?.size.height ?? 0),
          );

          left = offset.dx - 260 / 2;
          top = offset.dy;
        } else {
          offset = Offset(
            offset.dx + (box?.size.width ?? 0) / 2,
            offset.dy + (box?.size.height ?? 0) / 2,
          );

          left = offset.dx - 260 / 2;
          top = offset.dy;
        }
      }

      // Builds the provided [item].
      Widget _button(T item) {
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
                if (_debounce == null) {
                  widget.onSelected?.call(selected.value);
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
        children: [
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: Listener(
              onPointerUp: (d) => Navigator.of(context).pop(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 260,
                    constraints: const BoxConstraints(maxHeight: 280),
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      10,
                      0,
                      10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          CupertinoColors.systemBackground.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            children: widget.items.map(_button).toList(),
                          ),
                        ),
                        if (widget.items.length >= 8)
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
                        if (widget.items.length >= 8)
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
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
