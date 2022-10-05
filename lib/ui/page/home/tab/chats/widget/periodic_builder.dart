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

import 'dart:async';

import 'package:flutter/material.dart';

/// [Widget] invoking the [builder] over the provided [period].
class PeriodicBuilder extends StatefulWidget {
  const PeriodicBuilder({
    super.key,
    required this.period,
    required this.builder,
  });

  /// Period, over which to invoke the [builder].
  final Duration period;

  /// Builder building the [Widget] to periodically rebuild.
  final Widget Function(BuildContext context) builder;

  @override
  State<PeriodicBuilder> createState() => _PeriodicBuilderState();
}

/// State of a [PeriodicBuilder] maintaining the [timer].
class _PeriodicBuilderState extends State<PeriodicBuilder> {
  /// [Timer] rebuilding this [Widget].
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(widget.period, (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
