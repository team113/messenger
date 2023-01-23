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

import 'dart:async';

import 'package:flutter/material.dart';

class SkeletonContainer extends StatefulWidget {
  const SkeletonContainer({
    super.key,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final BoxShape shape;

  @override
  State<SkeletonContainer> createState() => _SkeletonContainerState();
}

class _SkeletonContainerState extends State<SkeletonContainer> {
  static const Duration _duration = Duration(milliseconds: 1000);

  late Timer timer;
  Color _color = const Color(0xFFE0E0E0);

  @override
  void initState() {
    timer = Timer.periodic(
      _duration,
      (timer) {
        if (_color == const Color(0xFFE0E0E0)) {
          _color = const Color(0xFFB0B0B0);
        } else {
          _color = const Color(0xFFE0E0E0);
        }

        setState(() {});
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _duration,
      width: widget.width,
      height: widget.height,
      curve: Curves.ease,
      decoration: BoxDecoration(
        color: _color,
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.rectangle
            ? BorderRadius.circular(8)
            : null,
      ),
    );
  }
}
