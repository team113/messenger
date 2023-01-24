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

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_list_view/flutter_list_view.dart';

import '/util/platform_utils.dart';

/// Controller for changing the scroll speed.
class CustomFlutterListViewController extends FlutterListViewController {
  CustomFlutterListViewController([this.coefficientScrollSpeed = 3]) {
    if (PlatformUtils.isWindows && !PlatformUtils.isWeb) {
      super.addListener(_changeScrollSpeed);
    }
  }

  /// Coefficient of change in the speed of the scroll.
  final double coefficientScrollSpeed;

  /// Previous scroll offset of the scrollable widget.
  double? oldOffset;

  @override
  void dispose() {
    super.removeListener(_changeScrollSpeed);
    super.dispose();
  }

  /// Changes the speed of the scroll.
  void _changeScrollSpeed() {
    if (super.position.userScrollDirection != ScrollDirection.idle) {
      oldOffset ??= super.offset;
      final double changingOffset = super.offset - oldOffset!;
      double newOffset = super.offset + changingOffset * coefficientScrollSpeed;
      newOffset = min(super.position.maxScrollExtent,
          max(super.position.minScrollExtent, newOffset));
      jumpTo(newOffset);
      oldOffset = newOffset;
    }
  }
}

/// Controller for changing the scroll speed.
class CustomScrollController extends ScrollController {
  CustomScrollController([this.coefficientScrollSpeed = 3]) {
    if (PlatformUtils.isWindows && !PlatformUtils.isWeb) {
      super.addListener(_changeScrollSpeed);
    }
  }

  /// Coefficient of change in the speed of the scroll.
  final double coefficientScrollSpeed;

  /// Previous scroll offset of the scrollable widget.
  double? oldOffset;

  @override
  void dispose() {
    super.removeListener(_changeScrollSpeed);
    super.dispose();
  }

  /// Changes the speed of the scroll.
  void _changeScrollSpeed() {
    if (super.position.userScrollDirection != ScrollDirection.idle) {
      oldOffset ??= super.offset;
      final double changingOffset = super.offset - oldOffset!;
      double newOffset = super.offset + changingOffset * coefficientScrollSpeed;
      newOffset = min(super.position.maxScrollExtent,
          max(super.position.minScrollExtent, newOffset));
      jumpTo(newOffset);
      oldOffset = newOffset;
    }
  }
}
