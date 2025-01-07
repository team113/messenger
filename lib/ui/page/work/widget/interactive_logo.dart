// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';

/// Interactive animated logo.
class InteractiveLogo extends StatefulWidget {
  const InteractiveLogo({super.key});

  @override
  State<InteractiveLogo> createState() => _InteractiveLogoState();
}

/// State of an [InteractiveLogo] animating the [_frame] with [_timer].
class _InteractiveLogoState extends State<InteractiveLogo> {
  /// Index of a frame of logo to display.
  int _frame = 0;

  /// [Timer] increasing the [_frame]s.
  Timer? _timer;

  @override
  void initState() {
    _animate();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _animate(),
      child: SvgImage.asset(
        'assets/images/logo/head_$_frame.svg',
        height: 134,
        fit: BoxFit.contain,
        placeholderBuilder: (context) {
          return const Center(child: CustomProgressIndicator());
        },
      ),
    );
  }

  /// Starts the [_timer] increasing the [_frame]s.
  void _animate() {
    _frame = 1;
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: 45),
      (t) {
        ++_frame;
        if (_frame >= 9) t.cancel();

        if (mounted) {
          setState(() {});
        }
      },
    );

    if (mounted) {
      setState(() {});
    }
  }
}
