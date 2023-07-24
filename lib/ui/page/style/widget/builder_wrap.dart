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

/// Colored [Wrap] displaying the provided [children] in a [Wrap] using the
/// [builder].
class BuilderWrap<T> extends StatelessWidget {
  const BuilderWrap(
    this.children,
    this.builder, {
    super.key,
    this.inverted = false,
    this.padding = const EdgeInsets.symmetric(vertical: 15),
  });
  final EdgeInsetsGeometry padding;

  /// Items to [Wrap].
  final Iterable<T> children;

  /// Builder, building the single [T] item from the [children].
  final Widget Function(T) builder;

  /// Indicator whether the background should have its colors inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      width: double.infinity,
      decoration: BoxDecoration(
        color: inverted ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: padding,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: children.map((e) => builder(e)).toList(),
        ),
      ),
    );
  }
}
