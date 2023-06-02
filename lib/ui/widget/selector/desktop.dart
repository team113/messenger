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
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';

/// [Widget] which returns desktop design of this [Selector].
class DesktopSelector<T> extends StatelessWidget {
  const DesktopSelector({
    super.key,
    required this.items,
    required this.alignment,
    required this.width,
    required this.itemBuilder,
    required this.selected,
    this.buttonKey,
    this.margin,
    this.buttonBuilder,
    this.debounce,
    this.onSelected,
  });

  /// [GlobalKey] of an [Object] displaying this [Selector].
  final GlobalKey<State<StatefulWidget>>? buttonKey;

  /// [List] of items to select from.
  final List<T> items;

  /// [Alignment] this [Selector] should take relative to the [buttonKey].
  final Alignment alignment;

  /// Width this [Selector] should occupy.
  final double width;

  /// Margin to apply to this [Selector].
  final EdgeInsetsGeometry? margin;

  /// Currently selected item.
  final Rx<T> selected;

  /// [Worker] debouncing the [selected] value, if any debounce is specified.
  final Worker? debounce;

  /// Callback, called when the provided item is selected.
  final void Function(T)? onSelected;

  /// Builder building a button to place the provided item onto.
  final Widget Function(int, T)? buttonBuilder;

  /// Builder building the provided item.
  final Widget Function(T) itemBuilder;

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
      } else if (right! > constraints.maxWidth) {
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
            color: style.colors.onPrimary,
            child: InkWell(
              hoverColor: style.colors.onSecondaryOpacity20,
              highlightColor: style.colors.onPrimaryOpacity7,
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                selected.value = item;
                if (debounce == null) {
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
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  style.colors.onPrimary,
                                  style.colors.transparent,
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
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  style.colors.transparent,
                                  style.colors.onPrimary,
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
