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

import '/themes.dart';

/// [Widget] which returns mobile design of this [Selector].
class MobileSelector<T> extends StatelessWidget {
  const MobileSelector({
    super.key,
    this.initial,
    required this.initialItem,
    required this.items,
    this.child,
    this.onSelectedItemChanged,
  });

  /// Initially selected item.
  final T? initial;

  /// Item to be [initial].
  final int initialItem;

  /// [List] of items to select from.
  final List<T> items;

  /// TODO: docs
  final Widget? child;

  /// TODO: docs
  final void Function(int)? onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

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
                  color: style.colors.secondaryHighlightDarkest,
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
                        initialItem: initialItem,
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
                        decoration: BoxDecoration(
                          color: style.colors.onSecondaryOpacity20,
                        ),
                      ),
                      onSelectedItemChanged: onSelectedItemChanged,
                      children: items
                          .map(
                            (e) => Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(46, 0, 29, 0),
                                child: child,
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
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 15,
                        width: double.infinity,
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
