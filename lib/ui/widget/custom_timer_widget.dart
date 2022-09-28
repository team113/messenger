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

/// [Widget] that displays [getWidget] return value with a frequency of [duration].
class CustomTimerWidget extends StatefulWidget {
  const CustomTimerWidget({
    super.key,
    required this.duration,
    required this.getWidget,
  });

  /// [getWidget] call frequency.
  final Duration duration;

  /// Builder building content for display.
  final Widget Function() getWidget;

  @override
  State<CustomTimerWidget> createState() => _CustomTimerWidgetState();
}

/// State of an [CustomTimerWidget] used to store [Timer].
class _CustomTimerWidgetState extends State<CustomTimerWidget> {
  /// Countdown timer.
  late final Timer timer;

  /// [Widget] to display.
  Widget child = const SizedBox.shrink();

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      widget.duration,
      (_) => setState(() {
        child = widget.getWidget();
      }),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => child;
}
