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
import 'package:rive/rive.dart';

class RiveAsset extends StatefulWidget {
  const RiveAsset(
    this.asset, {
    super.key,
    this.width,
    this.height,
  });

  final String asset;
  final double? width;
  final double? height;

  @override
  State<RiveAsset> createState() => _RiveAssetState();
}

class _RiveAssetState extends State<RiveAsset> {
  StateMachineController? _controller;
  SMIBool? _hover;
  SMITrigger? _click;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover?.change(true)),
      onExit: (_) => setState(() => _hover?.change(false)),
      child: Listener(
        onPointerDown: (_) => setState(() => _click?.fire()),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: RiveAnimation.asset(
            widget.asset,
            fit: BoxFit.contain,
            onInit: (a) {
              _controller = StateMachineController.fromArtboard(
                a,
                a.stateMachines.first.name,
              );
              a.addController(_controller!);

              _hover = _controller?.findInput<bool>('Hover') as SMIBool?;
              _click = _controller?.findInput<bool>('Click') as SMITrigger?;

              setState(() {});
            },
          ),
        ),
      ),
    );
  }
}
