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

/// Class which is responsible for showing popup of items select.
class Selector<T extends Object> extends StatefulWidget {
  /// Items that are present in this [Selector];
  final List<T> items;

  /// Initial value of selected item.
  final T? initialValue;

  /// Callback that is called on selection complete.
  final Function(T)? onSelect;

  /// Callback that returns view of single item from [items].
  final Widget Function(T data) itemBuilder;

  /// [GlobalKey] of the parent of this [Selector].
  /// Uses for resolving of popup position.
  final GlobalKey? globalKey;

  /// Delay that will be spent after value was set and before [onSelect] call.
  final Duration switchingDelayDuration;

  const Selector({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.initialValue,
    this.onSelect,
    this.globalKey,
    this.switchingDelayDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  /// Displays a [Selector] wrapped in a popup depend to the current platform.
  static Future<T?> show<T extends Object>(
    BuildContext context, {
    required List<T> items,
    required Widget Function(T data) itemBuilder,
    GlobalKey? globalKey,
    T? initialValue,
    void Function(T)? onSelect,
  }) {
    if (!context.isMobile) {
      return showDialog(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        builder: (context) {
          return Selector<T>(
            globalKey: globalKey,
            initialValue: initialValue,
            items: items,
            itemBuilder: itemBuilder,
            onSelect: onSelect,
          );
        },
      );
    } else {
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
            globalKey: globalKey,
            initialValue: initialValue,
            items: items,
            itemBuilder: itemBuilder,
            onSelect: onSelect,
          );
        },
      );
    }
  }

  @override
  State<Selector<T>> createState() => _SelectorState<T>();
}

class _SelectorState<T extends Object> extends State<Selector<T>> {
  /// Current selected item.
  late Rx<T> selected;

  /// Prevents instant call of [onSelect] after the user has set
  /// [selected] item.
  Worker? _debounce;

  @override
  void initState() {
    selected = Rx(widget.initialValue ?? widget.items.first);

    if (widget.switchingDelayDuration.inMicroseconds > 0) {
      _debounce = debounce(
        selected,
        (value) {
          if (widget.onSelect != null) {
            widget.onSelect?.call(value as T);
          }
        },
        time: widget.switchingDelayDuration,
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
    if (!context.isMobile) {
      return LayoutBuilder(builder: (context, constraints) {
        Offset offset =
            Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final keyContext = widget.globalKey?.currentContext;
        if (keyContext != null) {
          final box = keyContext.findRenderObject() as RenderBox?;
          offset = box?.localToGlobal(Offset.zero) ?? offset;
          offset = Offset(
            offset.dx + (box?.size.width ?? 0) / 2,
            offset.dy,
          );
        }
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
                onTap: () => widget.onSelect?.call(item),
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
              left: offset.dx - 260 / 2,
              bottom: MediaQuery.of(context).size.height - offset.dy,
              child: Listener(
                onPointerUp: (d) {
                  Navigator.of(context).pop();
                },
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
                        color: CupertinoColors.systemBackground
                            .resolveFrom(context),
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
    } else {
      return Container(
        height: min(widget.items.length * (65), 330),
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
                              initialItem: widget.initialValue == null
                                  ? 0
                                  : widget.items.indexOf(selected.value)),
                          magnification: 1,
                          squeeze: 1,
                          looping: true,
                          diameterRatio: 100,
                          useMagnifier: false,
                          itemExtent: 38,
                          selectionOverlay: Container(
                            margin: const EdgeInsetsDirectional.only(
                                start: 8, end: 8),
                            decoration:
                                const BoxDecoration(color: Color(0x3363B4FF)),
                          ),
                          onSelectedItemChanged: (int i) {
                            HapticFeedback.selectionClick();
                            selected.value = widget.items[i];
                          },
                          children: widget.items
                              .map((item) => Center(
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          46, 0, 29, 0),
                                      child: widget.itemBuilder(item),
                                    ),
                                  ))
                              .toList()),
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
}
