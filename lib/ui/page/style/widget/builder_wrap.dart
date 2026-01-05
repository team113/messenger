// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
    this.dense = false,
  });

  /// Items to [Wrap].
  final Iterable<T> children;

  /// Builder, building the single [T] item from the [children].
  final Widget Function(T) builder;

  /// Indicator whether the background should have its colors inverted.
  final bool inverted;

  /// Indicator whether this [BuilderWrap] should be dense, meaning no
  /// [Padding]s and roundness.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: inverted ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: dense ? BorderRadius.zero : BorderRadius.circular(16),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: children.map((e) => builder(e)).toList(),
      ),
    );
  }
}
