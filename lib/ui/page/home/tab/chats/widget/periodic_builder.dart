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

import '/util/fixed_timer.dart';

/// [Widget] invoking the [builder] over the provided [period].
class PeriodicBuilder extends StatefulWidget {
  const PeriodicBuilder({
    super.key,
    required this.period,
    required this.builder,
    this.delay = Duration.zero,
  });

  /// Period, over which to invoke the [builder].
  final Duration period;

  /// Delay before the first invocation of the [builder].
  final Duration delay;

  /// Builder building the [Widget] to periodically rebuild.
  final Widget Function(BuildContext context) builder;

  @override
  State<PeriodicBuilder> createState() => _PeriodicBuilderState();
}

/// State of a [PeriodicBuilder] maintaining the [_timer] and [_delay].
class _PeriodicBuilderState extends State<PeriodicBuilder> {
  /// [FixedTimer] rebuilding this [Widget].
  FixedTimer? _timer;

  /// [Timer] delaying the first invocation of the [builder].
  Timer? _delay;

  @override
  void initState() {
    super.initState();

    if (widget.delay == Duration.zero) {
      _start();
    } else {
      _delay = Timer(widget.delay, () {
        if (mounted) {
          setState(() {});
        }

        _start();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);

  /// Starts the [_timer].
  void _start() {
    _timer = FixedTimer.periodic(widget.period, () {
      if (mounted) {
        setState(() {});
      }
    });
  }
}
