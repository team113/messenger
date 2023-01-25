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

/// [ScrollController] increasing the scrolling sensitivity by the provided
/// [multiplier] when [PlatformUtilsImpl.isWindows] is `true`.
class CustomScrollController extends ScrollController {
  CustomScrollController([this.multiplier = 3]) {
    if (PlatformUtils.isWindows && !PlatformUtils.isWeb) {
      super.addListener(_multiplyOffset);
    }
  }

  /// Multiplier to multiply the scrolling sensitivity by.
  final double multiplier;

  /// [Offset] applied to this [ScrollController] in the previous
  /// [_multiplyOffset] call.
  double? _offset;

  @override
  void dispose() {
    super.removeListener(_multiplyOffset);
    super.dispose();
  }

  /// Calculates a new [Offset] multiplied by the [multiplier] to [jumpTo].
  void _multiplyOffset() {
    if (super.position.userScrollDirection != ScrollDirection.idle) {
      _offset ??= super.offset;

      final double diff = super.offset - _offset!;
      final double newOffset = min(
        super.position.maxScrollExtent,
        max(super.position.minScrollExtent, super.offset + diff * multiplier),
      );

      jumpTo(newOffset);
      _offset = newOffset;
    }
  }
}

/// [FlutterListViewController] increasing the scrolling sensitivity by the
/// provided [multiplier] when [PlatformUtilsImpl.isWindows] is `true`.
class CustomFlutterListViewController extends FlutterListViewController {
  CustomFlutterListViewController([this.multiplier = 3]) {
    if (PlatformUtils.isWindows && !PlatformUtils.isWeb) {
      super.addListener(_multiplyOffset);
    }
  }

  /// Multiplier to multiply the scrolling sensitivity by.
  final double multiplier;

  /// [Offset] applied to this [ScrollController] in the previous
  /// [_multiplyOffset] call.
  double? _offset;

  @override
  void dispose() {
    super.removeListener(_multiplyOffset);
    super.dispose();
  }

  /// Calculates a new [Offset] multiplied by the [multiplier] to [jumpTo].
  void _multiplyOffset() {
    if (super.position.userScrollDirection != ScrollDirection.idle) {
      _offset ??= super.offset;

      final double diff = super.offset - _offset!;
      final double newOffset = min(
        super.position.maxScrollExtent,
        max(super.position.minScrollExtent, super.offset + diff * multiplier),
      );

      jumpTo(newOffset);
      _offset = newOffset;
    }
  }
}
