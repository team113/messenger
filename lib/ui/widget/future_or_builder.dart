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

import 'dart:async';

import 'package:flutter/material.dart';

/// [FutureOr] builder returning the [T] value fetched.
class FutureOrBuilder<T> extends StatefulWidget {
  const FutureOrBuilder({
    super.key,
    required this.futureOr,
    required this.builder,
  });

  /// Callback returning [FutureOr] itself.
  ///
  /// Used as a function to prevent possible reinvokes.
  final FutureOr<T> Function() futureOr;

  /// Callback, building the [T].
  final Widget Function(BuildContext, T?) builder;

  @override
  State<FutureOrBuilder<T>> createState() => _FutureOrBuilderState<T>();
}

/// State of a [FutureOrBuilder] used for maintaining the data.
class _FutureOrBuilderState<T> extends State<FutureOrBuilder<T>> {
  /// Current snapshot of the [T] fetched, if any.
  T? _data;

  @override
  void initState() {
    final futureOr = widget.futureOr();

    if (futureOr is T?) {
      _data = futureOr as T?;
    } else {
      (futureOr as Future).then((e) {
        if (mounted) {
          setState(() => _data = e);
        }
      });
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant FutureOrBuilder<T> oldWidget) {
    if (oldWidget.key != widget.key) {
      final futureOr = widget.futureOr();

      if (futureOr is T?) {
        if (mounted) {
          setState(() => _data = futureOr as T?);
        }
      } else {
        (futureOr as Future).then((e) {
          if (mounted) {
            setState(() => _data = e);
          }
        });
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _data);
  }
}
